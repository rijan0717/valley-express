const mongoose = require('mongoose');
const Message = require('../models/Message');
const Order = require('../models/Order');
const User = require('../models/User');
const { getIO } = require('../sockets');

// A thread id is an order id, a customer id (direct inquiry), or the literal
// 'general'. Resolves to the message filter for that thread.
const buildThreadQuery = (threadId, user) => {
  if (mongoose.Types.ObjectId.isValid(threadId)) {
    // Could be orderId or customerId
    return {
      $or: [
        { order: threadId },
        { customer: threadId, order: null },
      ],
    };
  }
  if (threadId === 'general') {
    return { customer: user._id, order: null };
  }
  return { order: threadId };
};

// Messages are unread for whoever did not send them. Admin reads what the
// customer and rider sent; the customer reads what the admin sent.
const buildUnreadQuery = (user) => {
  if (user.role === 'admin') {
    return { isRead: false, senderRole: { $ne: 'admin' } };
  }
  return { isRead: false, senderRole: 'admin', customer: user._id };
};

// GET /api/chat/:threadId
const getMessagesByOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const query = buildThreadQuery(orderId, req.user);

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

// GET /api/chat/unread
// Total unread for the caller, plus a per-thread breakdown so the admin
// conversation list can badge each thread individually.
const getUnreadCount = async (req, res) => {
  try {
    const match = buildUnreadQuery(req.user);
    if (match.customer) {
      match.customer = new mongoose.Types.ObjectId(String(match.customer));
    }

    const rows = await Message.aggregate([
      { $match: match },
      { $group: { _id: { $ifNull: ['$order', '$customer'] }, count: { $sum: 1 } } },
    ]);

    const threads = {};
    let total = 0;
    for (const row of rows) {
      if (row._id) threads[row._id.toString()] = row.count;
      total += row.count;
    }

    res.json({ success: true, total, threads });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/chat/:orderId/read
// Marks everything the other party sent in this thread as read.
const markThreadRead = async (req, res) => {
  try {
    const { orderId } = req.params;
    const senderFilter =
      req.user.role === 'admin'
        ? { senderRole: { $ne: 'admin' } }
        : { senderRole: 'admin' };

    const result = await Message.updateMany(
      { $and: [buildThreadQuery(orderId, req.user), senderFilter, { isRead: false }] },
      { $set: { isRead: true, readAt: new Date() } }
    );

    // Let other open tabs and the sender's client refresh their badges
    try {
      getIO().to('admin-room').emit('chat:read', { threadId: orderId });
      if (req.user?._id) {
        getIO().to(`user:${req.user._id}`).emit('chat:read', { threadId: orderId });
      }
    } catch (e) {
      console.error('[Socket Chat Read Error]', e.message);
    }

    res.json({ success: true, markedRead: result.modifiedCount || 0 });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getMessagesByOrder,
  sendMessage,
  getAdminChatThreads,
  getUnreadCount,
  markThreadRead,
};
