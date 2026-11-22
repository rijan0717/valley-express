const mongoose = require('mongoose');
const Message = require('../models/Message');
const Order = require('../models/Order');
const User = require('../models/User');
const { getIO } = require('../sockets');

// The conversations that can hang off an order, and who is allowed in each.
// A customer must never see the rider's line to dispatch, and the rider must
// never see the customer's support thread, so every read and write is checked
// against this table rather than trusting the caller.
const CHANNELS = {
  support: ['customer', 'admin'],
  delivery: ['customer', 'rider'],
  fleet: ['rider', 'admin'],
};

// The customer may only message the rider once that rider is actually
// carrying the order; before pickup there is nobody on the other end.
const DELIVERY_OPEN_FROM = ['picked_up', 'on_the_way', 'delivered'];

const normaliseChannel = (value) => {
  const channel = String(value || 'support');
  return CHANNELS[channel] ? channel : 'support';
};

// A thread id is an order id, a customer id (direct inquiry), or the literal
// 'general'. Resolves to the message filter for that thread and channel.
const buildThreadQuery = (threadId, user, channel) => {
  const scope = { channel };
  if (mongoose.Types.ObjectId.isValid(threadId)) {
    // Could be orderId or customerId
    return {
      ...scope,
      $or: [
        { order: threadId },
        { customer: threadId, order: null },
      ],
    };
  }
  if (threadId === 'general') {
    return { ...scope, customer: user._id, order: null };
  }
  return { ...scope, order: threadId };
};

// Everything in the caller's reachable threads that someone else sent.
const buildUnreadQuery = (user) => {
  if (user.role === 'admin') {
    return { isRead: false, senderRole: { $ne: 'admin' }, channel: { $in: ['support', 'fleet'] } };
  }
  if (user.role === 'rider') {
    return { isRead: false, senderRole: { $ne: 'rider' }, rider: user._id, channel: { $in: ['delivery', 'fleet'] } };
  }
  return { isRead: false, senderRole: { $ne: 'customer' }, customer: user._id, channel: { $in: ['support', 'delivery'] } };
};

/// Decides whether [user] may read or write [channel] on [threadId].
///
/// Returns `{ ok: true, order }` or `{ ok: false, status, message }`. Admins
/// reach every thread their channels allow; a customer is held to their own
/// orders and a rider to the ones assigned to them.
const authorizeThread = async (threadId, user, channel) => {
  if (!CHANNELS[channel].includes(user.role)) {
    return { ok: false, status: 403, message: 'This conversation is not available to you' };
  }

  if (!mongoose.Types.ObjectId.isValid(threadId)) {
    // 'general' and other non-order threads are support-only and belong to
    // the caller, so there is nothing further to check.
    return { ok: true, order: null };
  }

  const order = await Order.findById(threadId);
  if (!order) {
    // Not an order id: a customer-scoped direct inquiry. Only that customer
    // and operations may open it.
    if (user.role === 'customer' && String(user._id) !== String(threadId)) {
      return { ok: false, status: 403, message: 'This conversation is not available to you' };
    }
    return { ok: true, order: null };
  }

  if (user.role === 'customer' && String(order.customer) !== String(user._id)) {
    return { ok: false, status: 403, message: 'This conversation is not available to you' };
  }
  if (user.role === 'rider' && String(order.rider || '') !== String(user._id)) {
    return { ok: false, status: 403, message: 'This order is not assigned to you' };
  }
  if (channel === 'delivery') {
    if (!order.rider) {
      return { ok: false, status: 409, message: 'No rider has been assigned to this order yet' };
    }
    if (!DELIVERY_OPEN_FROM.includes(order.status)) {
      return { ok: false, status: 409, message: 'Chat with your rider opens once the order is picked up' };
    }
  }

  return { ok: true, order };
};

// GET /api/chat/:threadId?channel=support
const getMessagesByOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const channel = normaliseChannel(req.query.channel);

    const allowed = await authorizeThread(orderId, req.user, channel);
    if (!allowed.ok) {
      return res.status(allowed.status).json({ success: false, message: allowed.message });
    }

    const messages = await Message.find(buildThreadQuery(orderId, req.user, channel))
      .populate('sender', 'name role')
      .sort({ createdAt: 1 });

    res.json({ success: true, count: messages.length, channel, messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/chat/:threadId
const sendMessage = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { text } = req.body;
    const channel = normaliseChannel(req.body.channel);

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Message text cannot be empty' });
    }

    const allowed = await authorizeThread(orderId, req.user, channel);
    if (!allowed.ok) {
      return res.status(allowed.status).json({ success: false, message: allowed.message });
    }

    const order = allowed.order;
    let customerId = req.user?._id;
    if (order) {
      customerId = order.customer?._id || order.customer || req.user?._id;
    }

    const message = await Message.create({
      order: order ? order._id : null,
      customer: req.user.role === 'rider' && !order ? null : customerId,
      // Pinned so a rider's threads are findable without re-reading the order.
      rider: channel === 'support' ? null : (order?.rider || (req.user.role === 'rider' ? req.user._id : null)),
      sender: req.user?._id,
      // Taken from the authenticated session, never the request body: the
      // previous version let a caller label themselves 'admin'.
      senderRole: req.user.role,
      channel,
      text: text.trim(),
    });
    const populated = await Message.findById(message._id).populate('sender', 'name role');

    // Broadcast in real-time, but only to the parties in this channel.
    try {
      const io = getIO();
      if (order) {
        io.to(`order:${order._id}:${channel}`).emit('chat:message', populated);
      }
      if (channel !== 'fleet' && customerId) {
        io.to(`user:${customerId}`).emit('chat:message', populated);
      }
      if (channel !== 'support' && populated.rider) {
        io.to(`user:${populated.rider}`).emit('chat:message', populated);
      }
      if (channel !== 'delivery') {
        io.to('admin-room').emit('chat:message', populated);
      }
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
    const generalMessages = await Message.find({ order: null, channel: 'support' })
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

// GET /api/chat/fleet (Admin) — the riders with an open line to dispatch.
const getFleetChatThreads = async (req, res) => {
  try {
    const rows = await Message.aggregate([
      { $match: { channel: 'fleet' } },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$rider',
          lastMessage: { $first: '$text' },
          updatedAt: { $first: '$createdAt' },
          unread: {
            $sum: {
              $cond: [{ $and: [{ $eq: ['$isRead', false] }, { $ne: ['$senderRole', 'admin'] }] }, 1, 0],
            },
          },
        },
      },
      { $sort: { updatedAt: -1 } },
    ]);

    const riders = await User.find({ _id: { $in: rows.map((r) => r._id).filter(Boolean) } })
      .select('name phone vehicleNumber isOnline');
    const byId = new Map(riders.map((r) => [String(r._id), r]));

    res.json({
      success: true,
      threads: rows
        .filter((r) => r._id && byId.has(String(r._id)))
        .map((r) => ({ rider: byId.get(String(r._id)), ...r })),
    });
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
    for (const key of ['customer', 'rider']) {
      if (match[key]) match[key] = new mongoose.Types.ObjectId(String(match[key]));
    }

    const rows = await Message.aggregate([
      { $match: match },
      {
        $group: {
          _id: { thread: { $ifNull: ['$order', '$customer'] }, channel: '$channel' },
          count: { $sum: 1 },
        },
      },
    ]);

    // Badges are per thread *and* per channel, so an order can show a support
    // count and a rider count independently.
    const threads = {};
    const channels = { support: 0, delivery: 0, fleet: 0 };
    let total = 0;
    for (const row of rows) {
      if (row._id.thread) {
        const key = `${row._id.thread.toString()}:${row._id.channel}`;
        threads[key] = row.count;
      }
      channels[row._id.channel] = (channels[row._id.channel] || 0) + row.count;
      total += row.count;
    }

    res.json({ success: true, total, channels, threads });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/chat/:orderId/read
// Marks everything the other party sent in this thread as read.
const markThreadRead = async (req, res) => {
  try {
    const { orderId } = req.params;
    const channel = normaliseChannel(req.body.channel || req.query.channel);

    const allowed = await authorizeThread(orderId, req.user, channel);
    if (!allowed.ok) {
      return res.status(allowed.status).json({ success: false, message: allowed.message });
    }

    const result = await Message.updateMany(
      {
        $and: [
          buildThreadQuery(orderId, req.user, channel),
          { senderRole: { $ne: req.user.role } },
          { isRead: false },
        ],
      },
      { $set: { isRead: true, readAt: new Date() } }
    );

    // Let other open tabs and the sender's client refresh their badges
    try {
      getIO().to('admin-room').emit('chat:read', { threadId: orderId, channel });
      if (req.user?._id) {
        getIO().to(`user:${req.user._id}`).emit('chat:read', { threadId: orderId, channel });
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
  getFleetChatThreads,
  getUnreadCount,
  markThreadRead,
};
