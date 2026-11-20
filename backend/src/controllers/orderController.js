const Order = require('../models/Order');
const Product = require('../models/Product');
const Setting = require('../models/Setting');
const Offer = require('../models/Offer');
const { getIO } = require('../sockets');

// Helper to generate readable order numbers: VX-98231
const generateOrderNo = () => {
  const rand = Math.floor(10000 + Math.random() * 90000);
  return `VX-${rand}`;
};

// POST /api/orders
const createOrder = async (req, res) => {
  try {
    const { items, address, paymentMethod = 'cash_on_delivery', offerCode, notes } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Order must contain at least one item' });
    }

    if (!address || !address.addressText) {
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
      const product = await Product.findById(item.product);
      if (!product) {
        return res.status(404).json({ success: false, message: `Product not found: ${item.product}` });
      }

      if (product.isAlcohol) {
        containsAlcohol = true;
        if (!alcoholGlobalEnabled) {
          return res.status(400).json({
            success: false,
            message: 'Alcohol sales are currently restricted pending regulatory licensing approval.',
          });
        }
        if (!req.user.ageConfirmed) {
          return res.status(400).json({
            success: false,
            message: 'You must confirm you are 18+ years of age to order alcoholic beverages.',
          });
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
    if (address.location && Array.isArray(address.location.coordinates) && address.location.coordinates.length === 2) {
      coordinates = [Number(address.location.coordinates[0]), Number(address.location.coordinates[1])];
    } else if (address.coordinates && Array.isArray(address.coordinates) && address.coordinates.length === 2) {
      coordinates = [Number(address.coordinates[0]), Number(address.coordinates[1])];
    } else if (address.latitude !== undefined && address.longitude !== undefined) {
      coordinates = [Number(address.longitude), Number(address.latitude)];
    } else if (address.lat !== undefined && address.lng !== undefined) {
      coordinates = [Number(address.lng), Number(address.lat)];
    }

    const deliveryAddress = {
      addressText: address.addressText || address.formattedAddress || 'Kathmandu Valley',
      landmark: address.landmark || '',
      formattedAddress: address.formattedAddress || address.addressText || '',
      location: {
        type: 'Point',
        coordinates,
      },
      contactPhone: address.contactPhone || req.user?.phone || '9800000000',
    };

    const order = await Order.create({
      orderNo,
      customer: req.user._id,
      items: processedItems,
      subtotal,
      deliveryFee,
      discount,
      total,
      offerCode: appliedOfferCode || offerCode || '',
      paymentMethod,
      paymentStatus: paymentMethod === 'cash_on_delivery' ? 'pending' : 'paid',
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

    // Notify Admin in real-time
    try {
      getIO().to('admin-room').emit('order:new', populatedOrder);
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

module.exports = {
  createOrder,
  getMyOrders,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  assignRider,
  cancelOrder,
  deleteOrder,
};
