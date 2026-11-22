const Order = require('../models/Order');
const Product = require('../models/Product');
const Setting = require('../models/Setting');
const Offer = require('../models/Offer');
const User = require('../models/User');
const { getIO } = require('../sockets');
const { createNotification } = require('./notificationController');

// Helper to generate readable order numbers: VX-98231
const generateOrderNo = () => {
  const rand = Math.floor(10000 + Math.random() * 90000);
  return `VX-${rand}`;
};

// POST /api/orders
const createOrder = async (req, res) => {
  try {
    const { items, paymentMethod = 'cash_on_delivery', offerCode, notes } = req.body;
    const rawAddress = req.body.address || req.body.deliveryAddress;

    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Order must contain at least one item' });
    }

    const addressObj = typeof rawAddress === 'string' ? { addressText: rawAddress } : (rawAddress || {});
    const addressText = addressObj.addressText || addressObj.formattedAddress || '';
    if (!addressText.trim()) {
      return res.status(400).json({ success: false, message: 'Delivery address is required' });
    }

    const settings = await Setting.findOne();
    const alcoholGlobalEnabled = settings ? settings.alcoholEnabled : false;
    const defaultDeliveryFee = settings ? settings.defaultDeliveryFee : 100;
    const freeDeliveryThreshold = settings ? settings.freeDeliveryThreshold : 1500;

    let subtotal = 0;
    let containsAlcohol = false;
    const processedItems = [];

    // Verify products, stock, and calculate subtotal securely on server
    for (const item of items) {
      const productId = item.product?._id || item.product?.id || item.product;
      const product = await Product.findById(productId);
      if (!product) {
        return res.status(404).json({ success: false, message: `Product not found: ${productId || item.product}` });
      }

      if (product.isAlcohol) {
        containsAlcohol = true;
        if (!alcoholGlobalEnabled) {
          return res.status(400).json({
            success: false,
            message: 'Alcohol sales are currently restricted pending regulatory licensing approval.',
          });
        }
        const userConfirmed = req.user?.ageConfirmed;
        const payloadConfirmed = req.body.ageConfirmed === true || req.body.isAgeConfirmed === true;
        if (!userConfirmed && !payloadConfirmed) {
          return res.status(400).json({
            success: false,
            message: 'You must confirm you are 18+ years of age to order alcoholic beverages.',
          });
        }
        if (!userConfirmed && payloadConfirmed) {
          req.user.ageConfirmed = true;
          await User.findByIdAndUpdate(req.user._id, { ageConfirmed: true });
        }
      }

      const itemPrice = product.discountPrice || product.price;
      const quantity = item.quantity || 1;
      subtotal += itemPrice * quantity;

      processedItems.push({
        product: product._id,
        name: product.name,
        price: itemPrice,
        quantity,
        isAlcohol: product.isAlcohol,
      });
    }

    // Delivery fee logic
    const deliveryFee = subtotal >= freeDeliveryThreshold ? 0 : defaultDeliveryFee;
    let discount = 0;
    let appliedOfferCode = '';

    // Real DB Offer / Coupon calculation
    if (offerCode) {
      const now = new Date();
      const validOffer = await Offer.findOne({
        code: offerCode.toUpperCase().trim(),
        isActive: true,
        startDate: { $lte: now },
        endDate: { $gte: now },
      });

      if (validOffer && subtotal >= (validOffer.minOrderAmount || 0)) {
        appliedOfferCode = validOffer.code;
        if (validOffer.discountType === 'percentage') {
          discount = Math.round((subtotal * validOffer.discountValue) / 100);
          if (validOffer.maxDiscountAmount) {
            discount = Math.min(discount, validOffer.maxDiscountAmount);
          }
        } else {
          discount = validOffer.discountValue;
        }
        await Offer.findByIdAndUpdate(validOffer._id, { $inc: { usedCount: 1 } });
      }
    }

    const total = Math.max(0, subtotal + deliveryFee - discount);

    const orderNo = generateOrderNo();

    let coordinates = [85.33, 27.728]; // default Kathmandu [longitude, latitude]
    if (addressObj.location && Array.isArray(addressObj.location.coordinates) && addressObj.location.coordinates.length === 2) {
      coordinates = [Number(addressObj.location.coordinates[0]), Number(addressObj.location.coordinates[1])];
    } else if (addressObj.coordinates && Array.isArray(addressObj.coordinates) && addressObj.coordinates.length === 2) {
      coordinates = [Number(addressObj.coordinates[0]), Number(addressObj.coordinates[1])];
    } else if (addressObj.latitude !== undefined && addressObj.longitude !== undefined) {
      coordinates = [Number(addressObj.longitude), Number(addressObj.latitude)];
    } else if (addressObj.lat !== undefined && addressObj.lng !== undefined) {
      coordinates = [Number(addressObj.lng), Number(addressObj.lat)];
    }

    let contactPhone = addressObj.contactPhone || req.user?.phone || '9841234567';
    if (!contactPhone || !contactPhone.trim()) {
      contactPhone = '9841234567';
    }

    const deliveryAddress = {
      addressText: addressText.trim(),
      landmark: addressObj.landmark || '',
      formattedAddress: addressObj.formattedAddress || addressText.trim(),
      location: {
        type: 'Point',
        coordinates,
      },
      contactPhone: contactPhone.trim(),
    };

    let normalizedPaymentMethod = (paymentMethod || 'cash_on_delivery').toLowerCase().trim();
    if (normalizedPaymentMethod === 'cod') normalizedPaymentMethod = 'cash_on_delivery';
    if (!['cash_on_delivery', 'esewa', 'khalti', 'fonepay'].includes(normalizedPaymentMethod)) {
      normalizedPaymentMethod = 'cash_on_delivery';
    }

    const order = await Order.create({
      orderNo,
      customer: req.user._id,
      items: processedItems,
      subtotal,
      deliveryFee,
      discount,
      total,
      offerCode: appliedOfferCode || offerCode || '',
      paymentMethod: normalizedPaymentMethod,
      paymentStatus: normalizedPaymentMethod === 'cash_on_delivery' ? 'pending' : 'paid',
      deliveryAddress,
      containsAlcohol,
      customerNotes: notes || '',
      status: 'placed',
      statusHistory: [
        {
          status: 'placed',
          timestamp: new Date(),
          note: 'Order placed by customer',
        },
      ],
      ageCheckedAtDoor: false,
    });

    // Populate customer details for socket broadcast
    const populatedOrder = await Order.findById(order._id)
      .populate('customer', 'name phone')
      .populate('items.product', 'name price images');

    // Notify Admin and Rider Pool in real-time
    try {
      getIO().to('admin-room').emit('order:new', populatedOrder);
      getIO().to('riders-pool').emit('order:available', populatedOrder);

      // Dispatch "New Order Arrived" notifications to all fleet riders
      User.find({ role: 'rider' }).select('_id').then((riders) => {
        riders.forEach((r) => {
          createNotification(r._id, {
            title: 'New Order Arrived!',
            body: `Order #${populatedOrder.orderNo} is waiting to be claimed. Drop-off: ${deliveryAddress.addressText || 'Kathmandu Valley'}.`,
            type: 'new_order',
            data: { orderId: populatedOrder._id, orderNo: populatedOrder.orderNo },
          });
        });
      }).catch(() => {});
    } catch (e) {
      console.error('[Socket Error]', e.message);
    }

    res.status(201).json({
      success: true,
      message: 'Order placed successfully',
      order: populatedOrder,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/orders/my
const getMyOrders = async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'customer') {
      query.customer = req.user._id;
    } else if (req.user.role === 'rider') {
      query.rider = req.user._id;
    }

    const orders = await Order.find(query)
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber')
      .populate('items.product', 'name price images isAlcohol')
      .sort({ createdAt: -1 });

    res.json({ success: true, count: orders.length, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/orders (Admin)
const getAllOrders = async (req, res) => {
  try {
    const { status, date } = req.query;
    let query = {};

    if (status && status !== 'all') {
      query.status = status;
    }

    const orders = await Order.find(query)
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber')
      .populate('items.product', 'name price images')
      .sort({ createdAt: -1 });

    res.json({ success: true, count: orders.length, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/orders/:id
const getOrderById = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('customer', 'name phone addresses')
      .populate('rider', 'name phone vehicleNumber')
      .populate('items.product', 'name price images isAlcohol');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/orders/:id/status
const updateOrderStatus = async (req, res) => {
  try {
    const { status, note, ageCheckedAtDoor } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    order.status = status;
    if (ageCheckedAtDoor !== undefined) {
      order.ageCheckedAtDoor = ageCheckedAtDoor;
    }

    order.statusHistory.push({
      status,
      timestamp: new Date(),
      note: note || `Order status updated to ${status}`,
    });

    if (status === 'delivered') {
      order.deliveredAt = new Date();
      if (order.paymentMethod === 'cash_on_delivery') {
        order.paymentStatus = 'paid';
      }
    }

    await order.save();

    const updated = await Order.findById(order._id)
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber');

    // Real-time broadcast to rooms
    try {
      getIO().to(`order:${order._id}`).emit('order:status', updated);
      getIO().to('admin-room').emit('order:status', updated);
      if (order.rider) {
        getIO().to(`rider:${order.rider}`).emit('order:status', updated);
      }

      // Customer notifications based on order status transition
      if (order.customer) {
        const customerId = order.customer._id || order.customer;
        const picker = req.user.role === 'admin' ? 'Store Operations' : (updated.rider?.name || 'Assigned Courier');

        if (status === 'picked_up') {
          createNotification(customerId, {
            title: `Order #${order.orderNo} Picked Up! 🛵`,
            body: `Your order has been collected from the store by ${picker} and is now en route to your location!`,
            type: 'order_update',
            data: { orderId: order._id, orderNo: order.orderNo, status: 'picked_up' },
          }).catch(() => {});
        } else if (status === 'on_the_way') {
          createNotification(customerId, {
            title: `Order #${order.orderNo} is On The Way! 🚀`,
            body: `Your courier is approaching your neighborhood. Please keep your phone handy!`,
            type: 'order_update',
            data: { orderId: order._id, orderNo: order.orderNo, status: 'on_the_way' },
          }).catch(() => {});
        } else if (status === 'delivered') {
          createNotification(customerId, {
            title: `Order #${order.orderNo} Delivered! 🎉`,
            body: `Your order was delivered successfully. Enjoy your chilled drinks & snacks!`,
            type: 'order_update',
            data: { orderId: order._id, orderNo: order.orderNo, status: 'delivered' },
          }).catch(() => {});
        } else if (status === 'cancelled') {
          createNotification(customerId, {
            title: `Order #${order.orderNo} Cancelled`,
            body: `Your order has been cancelled: ${note || 'Cancelled by operations'}.`,
            type: 'order_update',
            data: { orderId: order._id, orderNo: order.orderNo, status: 'cancelled' },
          }).catch(() => {});
        }
      }
    } catch (e) {
      console.error('[Socket Error]', e.message);
    }

    res.json({ success: true, message: `Status updated to ${status}`, order: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/orders/:id/assign
const assignRider = async (req, res) => {
  try {
    const { riderId } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    order.rider = riderId;
    order.status = 'rider_assigned';
    order.statusHistory.push({
      status: 'rider_assigned',
      timestamp: new Date(),
      note: 'Rider assigned to order',
    });

    await order.save();

    const updated = await Order.findById(order._id)
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber');

    try {
      getIO().to(`order:${order._id}`).emit('order:status', updated);
      getIO().to('admin-room').emit('order:status', updated);
      getIO().to(`rider:${riderId}`).emit('order:assigned', updated);

      // Notification to Rider that order is assigned to them
      createNotification(riderId, {
        title: 'Order is Assigned to You!',
        body: `You have been assigned order #${order.orderNo}. Please proceed to pick up the delivery.`,
        type: 'order_assigned',
        data: { orderId: order._id, orderNo: order.orderNo },
      }).catch(() => {});
    } catch (e) {
      console.error('[Socket Error]', e.message);
    }

    res.json({ success: true, message: 'Rider assigned successfully', order: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/orders/:id/cancel
const cancelOrder = async (req, res) => {
  try {
    const { reason = 'Cancelled by operations' } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (['delivered', 'cancelled'].includes(order.status)) {
      return res.status(400).json({
        success: false,
        message: `Order cannot be cancelled because it is already ${order.status}`,
      });
    }

    order.status = 'cancelled';
    order.statusHistory.push({
      status: 'cancelled',
      timestamp: new Date(),
      note: reason,
    });

    await order.save();

    const updated = await Order.findById(order._id)
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber');

    try {
      getIO().to(`order:${order._id}`).emit('order:status', updated);
      getIO().to('admin-room').emit('order:status', updated);
      if (order.rider) {
        getIO().to(`rider:${order.rider}`).emit('order:status', updated);

        // Notify rider that order got cancelled
        createNotification(order.rider, {
          title: 'Order Got Cancelled',
          body: `Order #${order.orderNo} was cancelled: ${reason}.`,
          type: 'order_cancelled',
          data: { orderId: order._id, orderNo: order.orderNo },
        }).catch(() => {});
      }
    } catch (e) {
      console.error('[Socket Error]', e.message);
    }

    res.json({ success: true, message: 'Order cancelled successfully', order: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/orders/:id (Admin)
const deleteOrder = async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, message: 'Order purged from database' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/orders/available (Rider & Admin)
// Returns available unassigned orders waiting for delivery
const getAvailableOrders = async (req, res) => {
  try {
    const orders = await Order.find({
      $or: [
        { rider: null },
        { rider: { $exists: false } },
      ],
      status: { $in: ['placed', 'accepted', 'preparing'] },
    })
      .populate('customer', 'name phone')
      .populate('items.product', 'name price images isAlcohol')
      .sort({ createdAt: -1 });

    res.json({ success: true, count: orders.length, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/orders/:id/claim (Rider only)
// Atomic concurrency lock: Prevents multiple riders from accepting the same order
const claimOrder = async (req, res) => {
  try {
    const riderId = req.user._id;

    // Atomic update with concurrency lock: rider must be null, status must be open
    const order = await Order.findOneAndUpdate(
      {
        _id: req.params.id,
        $or: [
          { rider: null },
          { rider: { $exists: false } },
        ],
        status: { $in: ['placed', 'accepted', 'preparing'] },
      },
      {
        $set: {
          rider: riderId,
          status: 'rider_assigned',
        },
        $push: {
          statusHistory: {
            status: 'rider_assigned',
            timestamp: new Date(),
            note: `Order accepted and claimed by rider ${req.user.name || req.user.phone}`,
            changedBy: riderId,
          },
        },
      },
      { new: true }
    )
      .populate('customer', 'name phone')
      .populate('rider', 'name phone vehicleNumber')
      .populate('items.product', 'name price images');

    if (!order) {
      // Check why atomic update failed
      const existing = await Order.findById(req.params.id).populate('rider', 'name phone');
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Order not found' });
      }

      if (existing.rider) {
        // Broadcast so other riders refresh their available lists
        try {
          getIO().emit('order:claimed', {
            orderId: existing._id,
            riderId: existing.rider._id,
            riderName: existing.rider.name,
            status: existing.status,
          });
        } catch (_) {}

        return res.status(409).json({
          success: false,
          isAlreadyClaimed: true,
          message: 'This order has already been picked up by another rider.',
          orderId: existing._id,
        });
      }

      return res.status(400).json({
        success: false,
        message: `Order cannot be claimed in its current status (${existing.status}).`,
      });
    }

    // Broadcast success to all riders so their available tab removes it immediately
    try {
      getIO().emit('order:claimed', {
        orderId: order._id,
        riderId: req.user._id,
        riderName: req.user.name,
        status: 'rider_assigned',
      });
      getIO().to(`order:${order._id}`).emit('order:status', order);
      getIO().to('admin-room').emit('order:status', order);
      getIO().to(`rider:${riderId}`).emit('order:assigned', order);

      // Notification for the rider that order is assigned to them
      createNotification(riderId, {
        title: 'Order is Assigned to You!',
        body: `You have successfully claimed order #${order.orderNo}. Please proceed to pick up the delivery.`,
        type: 'order_assigned',
        data: { orderId: order._id, orderNo: order.orderNo },
      }).catch(() => {});
    } catch (e) {
      console.error('[Socket Claim Error]', e.message);
    }

    res.json({
      success: true,
      message: 'Order accepted successfully! You are assigned to this delivery.',
      order,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createOrder,
  getMyOrders,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  assignRider,
  cancelOrder,
  deleteOrder,
  getAvailableOrders,
  claimOrder,
};
