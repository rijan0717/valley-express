const mongoose = require('mongoose');
const Message = require('../models/Message');
const Order = require('../models/Order');
const User = require('../models/User');
const { getIO } = require('../sockets');

// GET /api/chat/:threadId
const getMessagesByOrder = async (req, res) => {
  try {
    const { orderId } = req.params;

    let query = {};
    if (mongoose.Types.ObjectId.isValid(orderId)) {
      // Could be orderId or customerId
      query = {
        $or: [
          { order: orderId },
          { customer: orderId, order: null },
        ],
      };
    } else if (orderId === 'general') {
      query = { customer: req.user._id, order: null };
    } else {
      query = { order: orderId };
    }

    const messages = await Message.find(query)
      .populate('sender', 'name role')
      .sort({ createdAt: 1 });

    res.json({ success: true, count: messages.length, messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/chat/:threadId
const sendMessage = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Message text cannot be empty' });
    }

    let order = null;
    let customerId = req.user?._id;

    if (mongoose.Types.ObjectId.isValid(orderId)) {
      order = await Order.findById(orderId);
      if (order) {
        customerId = order.customer?._id || order.customer || req.user?._id;
      }
    }

    const resolvedRole = req.body.senderRole || req.user?.role || 'customer';

    const messageData = {
      order: order ? order._id : null,
      customer: customerId,
      sender: req.user?._id,
      senderRole: resolvedRole,
      text: text.trim(),
    };

    const message = await Message.create(messageData);
    const populated = await Message.findById(message._id).populate('sender', 'name role');

    // Broadcast in real-time to specific channels
    try {
      if (order) {
        getIO().to(`order:${order._id}`).emit('chat:message', populated);
      }
      if (customerId) {
        getIO().to(`user:${customerId}`).emit('chat:message', populated);
      }
      // Notify Admin Operations room
      getIO().to('admin-room').emit('chat:message', populated);
    } catch (e) {
      console.error('[Socket Chat Error]', e.message);
    }

    res.status(201).json({ success: true, message: populated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/chat/threads (Admin)
const getAdminChatThreads = async (req, res) => {
  try {
    // 1. Orders with active messages or in-flight status
    const orders = await Order.find({ status: { $nin: ['cancelled', 'rejected'] } })
      .populate('customer', 'name phone')
      .sort({ updatedAt: -1 })
      .limit(20);

    // 2. Also fetch any customers who sent direct inquiries without an order
    const generalMessages = await Message.find({ order: null })
      .populate('customer', 'name phone')
      .sort({ createdAt: -1 })
      .limit(10);

    const seenCustomers = new Set();
    const generalThreads = [];

    for (const msg of generalMessages) {
      if (msg.customer && !seenCustomers.has(msg.customer._id.toString())) {
        seenCustomers.add(msg.customer._id.toString());
        generalThreads.push({
          _id: msg.customer._id,
          orderNo: 'SUPPORT-GENERAL',
          customer: msg.customer,
          status: 'Direct Inquiry',
          deliveryAddress: { addressText: 'Kathmandu Customer Support' },
          isGeneralInquiry: true,
          lastMessage: msg.text,
          updatedAt: msg.createdAt,
        });
      }
    }

    const combinedThreads = [...generalThreads, ...orders];

    res.json({ success: true, count: combinedThreads.length, threads: combinedThreads });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getMessagesByOrder,
  sendMessage,
  getAdminChatThreads,
};
