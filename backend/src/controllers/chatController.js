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

// The customer and rider may message each other as soon as a rider is assigned.
const DELIVERY_OPEN_FROM = ['rider_assigned', 'picked_up', 'on_the_way', 'delivered'];

const normaliseChannel = (value) => {
  const channel = String(value || 'support');
  return CHANNELS[channel] ? channel : 'support';
};

// A thread id is an order id, a customer id (direct inquiry), or the literal
// 'general'. Resolves to the message filter for that thread and channel.
const buildThreadQuery = (threadId, user, channel) => {
  const scope = { channel };
  if (channel === 'fleet') {
    if (mongoose.Types.ObjectId.isValid(threadId)) {
      return {
        ...scope,
        $or: [
          { order: threadId },
          { rider: threadId },
        ],
      };
    }
    if (user.role === 'rider') {
      return { ...scope, rider: user._id };
    }
    return scope;
  }
  if (mongoose.Types.ObjectId.isValid(threadId)) {
    // Could be orderId or customerId
    return {
      ...scope,
      $or: [
        { order: threadId },
        { customer: threadId, order: null },
        { rider: threadId, order: null },
      ],
    };
  }
  if (threadId === 'general') {
    if (user.role === 'rider') {
      return { ...scope, rider: user._id, order: null };
    }
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
    // Not an order id: customer or rider direct line
    if (user.role === 'customer' && String(user._id) !== String(threadId)) {
      return { ok: false, status: 403, message: 'This conversation is not available to you' };
    }
    if (user.role === 'rider' && String(user._id) !== String(threadId)) {
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
      .populate('sender', 'name role avatarUrl')
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
    let customerId = null;
    let riderId = null;
    if (order) {
      customerId = order.customer?._id || order.customer;
      riderId = order.rider?._id || order.rider;
    } else if (channel === 'fleet') {
      if (req.user.role === 'rider') {
        riderId = req.user._id;
      } else if (mongoose.Types.ObjectId.isValid(orderId)) {
        riderId = orderId;
      }
    } else if (req.user.role === 'customer') {
      customerId = req.user._id;
    } else if (mongoose.Types.ObjectId.isValid(orderId)) {
      // Admin replying to direct customer inquiry
      customerId = orderId;
    }

    const message = await Message.create({
      order: order ? order._id : null,
      customer: (channel === 'fleet' || (req.user.role === 'rider' && !order)) ? null : customerId,
      // Pinned so a rider's threads are findable without re-reading the order.
      rider: channel === 'support' ? null : (order?.rider || riderId || (req.user.role === 'rider' ? req.user._id : null)),
      sender: req.user?._id,
      // Taken from the authenticated session, never the request body: the
      // previous version let a caller label themselves 'admin'.
      senderRole: req.user.role,
      channel,
      text: text.trim(),
    });
    const populated = await Message.findById(message._id).populate('sender', 'name role avatarUrl');

    // Broadcast in real-time to order and personal recipient rooms.
    try {
      const io = getIO();
      if (order) {
        io.to(`order:${order._id}`).emit('chat:message', populated);
        io.to(`order:${order._id}:${channel}`).emit('chat:message', populated);
      }
      if (channel !== 'fleet' && customerId) {
        io.to(`user:${customerId}`).emit('chat:message', populated);
      }
      if (channel !== 'support' && (populated.rider || riderId)) {
        const targetRider = populated.rider || riderId;
        io.to(`user:${targetRider}`).emit('chat:message', populated);
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
      .populate('customer', 'name phone avatarUrl')
      .populate('rider', 'name phone vehicleNumber avatarUrl')
      .sort({ updatedAt: -1 })
      .limit(30);

    const orderThreads = orders.map((o) => ({
      _id: o._id,
      orderNo: o.orderNo,
      customer: o.customer,
      rider: o.rider,
      status: o.status,
      deliveryAddress: o.deliveryAddress,
      threadType: 'customer',
      channel: 'support',
      updatedAt: o.updatedAt,
    }));

    // 2. Direct customer inquiries
    const generalMessages = await Message.find({ order: null, channel: 'support' })
      .populate('customer', 'name phone avatarUrl')
      .sort({ createdAt: -1 })
      .limit(15);

    const seenCustomers = new Set();
    const customerGeneralThreads = [];

    for (const msg of generalMessages) {
      if (msg.customer && !seenCustomers.has(msg.customer._id.toString())) {
        seenCustomers.add(msg.customer._id.toString());
        customerGeneralThreads.push({
          _id: msg.customer._id,
          orderNo: 'SUPPORT-GENERAL',
          customer: msg.customer,
          status: 'Direct Inquiry',
          deliveryAddress: { addressText: 'Kathmandu Customer Support' },
          threadType: 'customer',
          channel: 'support',
          isGeneralInquiry: true,
          lastMessage: msg.text,
          updatedAt: msg.createdAt,
        });
      }
    }

    // 3. Rider fleet messages
    const fleetMessages = await Message.find({ channel: 'fleet' })
      .populate('rider', 'name phone vehicleNumber isOnline avatarUrl')
      .sort({ createdAt: -1 })
      .limit(30);

    const seenRiders = new Set();
    const riderThreads = [];

    for (const msg of fleetMessages) {
      if (msg.rider && !seenRiders.has(msg.rider._id.toString())) {
        seenRiders.add(msg.rider._id.toString());
        riderThreads.push({
          _id: msg.rider._id,
          orderNo: `FLEET-${msg.rider.name.toUpperCase().replace(/\s+/g, '-')}`,
          rider: msg.rider,
          customer: { name: `${msg.rider.name} (Rider)`, phone: msg.rider.phone },
          status: msg.rider.isOnline ? 'Online on Duty' : 'Duty Paused',
          deliveryAddress: { addressText: `Vehicle: ${msg.rider.vehicleNumber || 'Valley Fleet Rider'}` },
          threadType: 'rider',
          channel: 'fleet',
          isFleetRider: true,
          lastMessage: msg.text,
          updatedAt: msg.createdAt,
        });
      }
    }

    // Also include active riders so admin can initiate contact with any rider
    const activeRiders = await User.find({ role: 'rider', status: 'active' })
      .select('name phone vehicleNumber isOnline updatedAt avatarUrl')
      .limit(10);
    for (const r of activeRiders) {
      if (!seenRiders.has(r._id.toString())) {
        seenRiders.add(r._id.toString());
        riderThreads.push({
          _id: r._id,
          orderNo: `FLEET-${r.name.toUpperCase().replace(/\s+/g, '-')}`,
          rider: r,
          customer: { name: `${r.name} (Rider)`, phone: r.phone },
          status: r.isOnline ? 'Online on Duty' : 'Standby',
          deliveryAddress: { addressText: `Vehicle: ${r.vehicleNumber || 'Valley Fleet Rider'}` },
          threadType: 'rider',
          channel: 'fleet',
          isFleetRider: true,
          updatedAt: r.updatedAt || new Date(),
        });
      }
    }

    const combinedThreads = [...customerGeneralThreads, ...riderThreads, ...orderThreads];

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
      .select('name phone vehicleNumber isOnline avatarUrl');
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

// GET /api/chat/conversations
// Returns a messenger-style list of distinct conversation threads for the logged-in customer or rider.
const getUserConversations = async (req, res) => {
  try {
    const user = req.user;
    const conversations = [];

    if (user.role === 'customer') {
      // 1. General Valley Dispatch & Support line
      const generalLastMsg = await Message.findOne({
        customer: user._id,
        order: null,
        channel: 'support',
      }).sort({ createdAt: -1 });

      const generalUnread = await Message.countDocuments({
        customer: user._id,
        order: null,
        channel: 'support',
        senderRole: { $ne: 'customer' },
        isRead: false,
      });

      conversations.push({
        threadId: 'general',
        orderId: null,
        orderNo: null,
        channel: 'support',
        type: 'support',
        title: 'Valley Dispatch & Operations',
        subtitle: 'Official Support Helpdesk • 24/7',
        avatarType: 'support',
        status: 'online',
        lastMessage: generalLastMsg ? generalLastMsg.text : 'Need help with your orders or deliveries? Message our dispatch team anytime.',
        lastMessageTime: generalLastMsg ? generalLastMsg.createdAt : user.createdAt,
        unreadCount: generalUnread,
      });

      // 2. All orders belonging to this customer
      const orders = await Order.find({ customer: user._id })
        .populate('rider', 'name phone vehicleNumber vehicleType isOnline avatarUrl')
        .sort({ createdAt: -1 })
        .limit(50);

      for (const order of orders) {
        // If rider is assigned, create a delivery chat thread with the rider
        if (order.rider) {
          const riderLastMsg = await Message.findOne({
            order: order._id,
            channel: 'delivery',
          }).sort({ createdAt: -1 });

          const riderUnread = await Message.countDocuments({
            order: order._id,
            channel: 'delivery',
            senderRole: { $ne: 'customer' },
            isRead: false,
          });

          conversations.push({
            threadId: String(order._id),
            orderId: String(order._id),
            orderNo: order.orderNo,
            orderStatus: order.status,
            channel: 'delivery',
            type: 'rider',
            title: order.rider.name || 'Assigned Rider',
            subtitle: `Rider for Order #${order.orderNo}`,
            riderName: order.rider.name,
            riderPhone: order.rider.phone,
            riderVehicle: order.rider.vehicleNumber,
            avatarType: 'rider',
            status: order.rider.isOnline ? 'Online on Duty' : 'On Route',
            lastMessage: riderLastMsg ? riderLastMsg.text : `Rider assigned to order #${order.orderNo}. Tap to chat.`,
            lastMessageTime: riderLastMsg ? riderLastMsg.createdAt : order.updatedAt,
            unreadCount: riderUnread,
          });
        }

        // Check if there are support messages for this specific order
        const supportLastMsg = await Message.findOne({
          order: order._id,
          channel: 'support',
        }).sort({ createdAt: -1 });

        if (supportLastMsg) {
          const supportUnread = await Message.countDocuments({
            order: order._id,
            channel: 'support',
            senderRole: { $ne: 'customer' },
            isRead: false,
          });

          conversations.push({
            threadId: String(order._id),
            orderId: String(order._id),
            orderNo: order.orderNo,
            orderStatus: order.status,
            channel: 'support',
            type: 'support',
            title: `Order #${order.orderNo} Support`,
            subtitle: `Operations query for #${order.orderNo}`,
            avatarType: 'support',
            status: order.status,
            lastMessage: supportLastMsg.text,
            lastMessageTime: supportLastMsg.createdAt,
            unreadCount: supportUnread,
          });
        }
      }
    } else if (user.role === 'rider') {
      // 1. Dispatch Fleet line
      const fleetLastMsg = await Message.findOne({
        rider: user._id,
        channel: 'fleet',
      }).sort({ createdAt: -1 });

      const fleetUnread = await Message.countDocuments({
        rider: user._id,
        channel: 'fleet',
        senderRole: { $ne: 'rider' },
        isRead: false,
      });

      conversations.push({
        threadId: 'general',
        orderId: null,
        orderNo: null,
        channel: 'fleet',
        type: 'support',
        title: 'Operations Fleet Dispatch',
        subtitle: 'Kathmandu Central Fleet Control',
        avatarType: 'support',
        status: 'online',
        lastMessage: fleetLastMsg ? fleetLastMsg.text : 'Direct line to Operations Dispatch. Report delays or vehicle issues.',
        lastMessageTime: fleetLastMsg ? fleetLastMsg.createdAt : user.createdAt,
        unreadCount: fleetUnread,
      });

      // 2. Orders assigned to this rider
      const assignedOrders = await Order.find({ rider: user._id })
        .populate('customer', 'name phone avatarUrl')
        .sort({ updatedAt: -1 })
        .limit(50);

      for (const order of assignedOrders) {
        const deliveryLastMsg = await Message.findOne({
          order: order._id,
          channel: 'delivery',
        }).sort({ createdAt: -1 });

        const deliveryUnread = await Message.countDocuments({
          order: order._id,
          channel: 'delivery',
          senderRole: { $ne: 'rider' },
          isRead: false,
        });

        conversations.push({
          threadId: String(order._id),
          orderId: String(order._id),
          orderNo: order.orderNo,
          orderStatus: order.status,
          channel: 'delivery',
          type: 'customer',
          title: order.customer?.name || 'Customer',
          subtitle: `Customer for Order #${order.orderNo}`,
          customerName: order.customer?.name,
          customerPhone: order.customer?.phone || order.deliveryAddress?.contactPhone,
          deliveryAddress: order.deliveryAddress?.addressText || order.address?.addressText,
          avatarType: 'customer',
          status: order.status,
          lastMessage: deliveryLastMsg ? deliveryLastMsg.text : `Delivery line open for Order #${order.orderNo}`,
          lastMessageTime: deliveryLastMsg ? deliveryLastMsg.createdAt : order.updatedAt,
          unreadCount: deliveryUnread,
        });
      }
    } else {
      // Admin: redirect to getAdminChatThreads logic
      return getAdminChatThreads(req, res);
    }

    // Sort all conversations by lastMessageTime descending (most recent first, like Messenger)
    conversations.sort((a, b) => new Date(b.lastMessageTime).getTime() - new Date(a.lastMessageTime).getTime());

    res.json({ success: true, count: conversations.length, conversations });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getMessagesByOrder,
  sendMessage,
  getAdminChatThreads,
  getFleetChatThreads,
  getUserConversations,
  getUnreadCount,
  markThreadRead,
};
