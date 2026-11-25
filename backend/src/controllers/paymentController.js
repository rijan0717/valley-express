const crypto = require('crypto');
const Order = require('../models/Order');
const { getIO } = require('../sockets');
const { verifyGatewayPayment } = require('../services/paymentVerify');
const { isAdmin, isOrderOwner } = require('../utils/orderAccess');

// Configurable gateway settings (falls back to Nepal Sandbox credentials)
const ESEWA_CONFIG = {
  merchantCode: process.env.ESEWA_MERCHANT_CODE || 'EPAYTEST',
  secretKey: process.env.ESEWA_SECRET_KEY || '8gBm/:&EnhH.1/q',
  endpoint: process.env.ESEWA_ENDPOINT || 'https://rc-epay.esewa.com.np/api/epay/main/v2/form',
};

const KHALTI_CONFIG = {
  publicKey: process.env.KHALTI_PUBLIC_KEY || 'test_public_key_dc74e0fd9274483c80e77028824f93ab',
  secretKey: process.env.KHALTI_SECRET_KEY || 'test_secret_key_f59e8b7d18b4499f8286f809f30997cb',
  endpoint: process.env.KHALTI_ENDPOINT || 'https://a.khalti.com/api/v2/epayment/initiate/',
};

// Helper to generate HMAC-SHA256 signature for eSewa EPAY v2
const generateEsewaSignature = (totalAmount, transactionUuid, productCode) => {
  const message = `total_amount=${totalAmount},transaction_uuid=${transactionUuid},product_code=${productCode}`;
  return crypto.createHmac('sha256', ESEWA_CONFIG.secretKey).update(message).digest('base64');
};

// GET /api/payments/methods
const getPaymentMethods = async (req, res) => {
  try {
    const methods = [
      {
        id: 'cash_on_delivery',
        name: 'Cash on Delivery',
        subtitle: 'Pay cash or Scan on delivery',
        icon: 'payments',
        badge: 'Popular',
        isOnline: false,
        enabled: true,
      },
      {
        id: 'esewa',
        name: 'eSewa Mobile Wallet',
        subtitle: 'Nepal\'s leading digital payment',
        icon: 'account_balance_wallet',
        badge: 'Instant',
        isOnline: true,
        enabled: true,
        color: '#60BB46',
      },
      {
        id: 'khalti',
        name: 'Khalti Digital Wallet',
        subtitle: 'Pay via Khalti balance or e-Banking',
        icon: 'account_balance_wallet',
        badge: 'Instant',
        isOnline: true,
        enabled: true,
        color: '#5C2D91',
      },
      {
        id: 'fonepay',
        name: 'Fonepay Direct QR',
        subtitle: 'Scan & Pay from any banking app',
        icon: 'qr_code_scanner',
        badge: 'Direct Bank',
        isOnline: true,
        enabled: true,
        color: '#E31E24',
      },
    ];

    res.json({ success: true, count: methods.length, methods });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/payments/initialize
const initializePayment = async (req, res) => {
  try {
    const { orderId, method = 'esewa' } = req.body;

    if (!orderId) {
      return res.status(400).json({ success: false, message: 'Order ID is required' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Only the order's own customer (or an admin) may start its payment.
    if (!isAdmin(req.user) && !isOrderOwner(order, req.user)) {
      return res.status(403).json({ success: false, message: 'You cannot pay for this order' });
    }

    const totalAmount = order.total;
    const transactionUuid = `${order.orderNo}-${Date.now()}`;

    if (method === 'esewa') {
      const signature = generateEsewaSignature(totalAmount, transactionUuid, ESEWA_CONFIG.merchantCode);
      const paymentData = {
        amount: totalAmount,
        tax_amount: '0',
        total_amount: totalAmount,
        transaction_uuid: transactionUuid,
        product_code: ESEWA_CONFIG.merchantCode,
        product_service_charge: '0',
        product_delivery_charge: '0',
        success_url: `http://localhost:5173/mobile-preview?payment=success&orderId=${order._id}`,
        failure_url: `http://localhost:5173/mobile-preview?payment=failure&orderId=${order._id}`,
        signed_field_names: 'total_amount,transaction_uuid,product_code',
        signature,
      };

      return res.json({
        success: true,
        method: 'esewa',
        actionUrl: ESEWA_CONFIG.endpoint,
        paymentData,
        isSandbox: true,
      });
    }

    if (method === 'khalti') {
      const paymentData = {
        return_url: `http://localhost:5173/mobile-preview?payment=success&orderId=${order._id}`,
        website_url: 'http://localhost:5173',
        amount: Math.round(totalAmount * 100), // paisa
        purchase_order_id: order.orderNo,
        purchase_order_name: `Valley Express Order ${order.orderNo}`,
        customer_info: {
          name: req.user?.name || 'Valley Customer',
          phone: req.user?.phone || '9841234567',
        },
      };

      return res.json({
        success: true,
        method: 'khalti',
        actionUrl: KHALTI_CONFIG.endpoint,
        paymentData,
        isSandbox: true,
      });
    }

    if (method === 'fonepay') {
      return res.json({
        success: true,
        method: 'fonepay',
        qrData: `fonepay://pay?merchant=VALLEYEXPRESS&amount=${totalAmount}&orderNo=${order.orderNo}`,
        isSandbox: true,
      });
    }

    res.status(400).json({ success: false, message: `Unsupported payment method: ${method}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/payments/verify
const verifyPayment = async (req, res) => {
  try {
    const {
      orderId,
      method = 'esewa',
      transactionId,
      referenceId,
      // Gateway-issued identifiers used for real server-side confirmation.
      transactionUuid,
      pidx,
    } = req.body;

    if (!orderId) {
      return res.status(400).json({ success: false, message: 'Order ID is required' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Only the customer who owns the order (or an admin) may settle its
    // payment. Previously any signed-in account could mark any order paid.
    if (!isAdmin(req.user) && !isOrderOwner(order, req.user)) {
      return res.status(403).json({ success: false, message: 'You cannot modify this order' });
    }

    // Confirm the payment with the gateway itself — never on the client's word.
    const gateway = await verifyGatewayPayment(method, {
      transactionUuid: transactionUuid || referenceId,
      pidx,
      totalAmount: order.total,
    });

    let paid = gateway.verified;
    let note;

    if (paid) {
      note = `Online payment confirmed with ${method.toUpperCase()} (ref: ${gateway.reference}).`;
    } else if (process.env.NODE_ENV !== 'production') {
      // Local development / demo only: the sandbox has no real transaction to
      // confirm, so accept a simulated payment but label it clearly. This
      // branch can never run on a production server.
      paid = true;
      note = `SANDBOX simulated payment via ${method.toUpperCase()} (dev only).`;
    } else {
      // Production and the gateway did not confirm: refuse to mark it paid.
      return res.status(402).json({
        success: false,
        message: 'Payment could not be confirmed with the provider. It has not been marked as paid.',
        reason: gateway.reason,
      });
    }

    const resolvedTxnId = gateway.reference || transactionId || referenceId || transactionUuid || pidx;

    order.paymentMethod = method;
    order.paymentStatus = 'paid';
    order.statusHistory.push({
      status: order.status,
      timestamp: new Date(),
      note: `${note} (Txn Ref: ${resolvedTxnId})`,
      changedBy: req.user?._id,
    });

    await order.save();

    const populatedOrder = await Order.findById(order._id)
      .populate('customer', 'name phone avatarUrl')
      .populate('items.product', 'name price images');

    // Broadcast live payment update to order room & admin board
    try {
      getIO().to(`order:${order._id}`).emit('order:status', {
        orderId: order._id,
        status: order.status,
        paymentStatus: 'paid',
        paymentMethod: method,
        timestamp: new Date(),
      });
      getIO().to('admin-room').emit('order:updated', populatedOrder);
    } catch (e) {
      console.error('[Socket Error]', e.message);
    }

    res.json({
      success: true,
      message: `Payment verified successfully via ${method.toUpperCase()}`,
      order: populatedOrder,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getPaymentMethods,
  initializePayment,
  verifyPayment,
};
