const Notification = require('../models/Notification');
const Order = require('../models/Order');
const { getIO } = require('../sockets');

// Helper to send a notification to a specific user and emit via socket
const createNotification = async (userId, { title, body, type = 'system', data = {} }) => {
  try {
    const notif = await Notification.create({
      user: userId,
      title,
      body,
      type,
      data,
      isRead: false,
    });

    try {
      const io = getIO();
      if (io) {
        // Emit to general notifications and user-specific room
        io.emit('rider_notification', {
          userId: userId.toString(),
          notification: notif,
        });
        io.to(userId.toString()).emit('new_notification', notif);
      }
    } catch (sockErr) {
      console.warn('Socket notification emit failed:', sockErr.message);
    }

    return notif;
  } catch (err) {
    console.error('Failed to create notification:', err);
    return null;
  }
};

// GET /api/notifications
// Fetch all notifications for the current authenticated user (Rider or Customer)
const getMyNotifications = async (req, res) => {
  try {
    const userId = req.user._id;

    // If Rider, check for unpicked orders and create automated reminder alerts if needed
    if (req.user.role === 'rider') {
      const unpickedOrders = await Order.find({
        rider: userId,
        status: 'rider_assigned',
      });

      for (const order of unpickedOrders) {
        // Check if an unpicked reminder already exists in the last 2 hours
        const existingAlert = await Notification.findOne({
          user: userId,
          type: 'order_not_picked',
          'data.orderId': order._id,
          createdAt: { $gte: new Date(Date.now() - 2 * 60 * 60 * 1000) },
        });

        if (!existingAlert) {
          await createNotification(userId, {
            title: `Pickup Reminder: Order #${order.orderNo}`,
            body: `Order #${order.orderNo} from ${order.pickupAddress?.addressText || 'Central Hub'} is awaiting pickup. Please proceed to the store.`,
            type: 'order_not_picked',
            data: {
              orderId: order._id,
              orderNo: order.orderNo,
            },
          });
        }
      }
    }

    const notifications = await Notification.find({ user: userId })
      .sort({ createdAt: -1 })
      .limit(50);

    const unreadCount = await Notification.countDocuments({
      user: userId,
      isRead: false,
    });

    res.json({
      success: true,
      count: notifications.length,
      unreadCount,
      notifications,
    });
  } catch (error) {
    console.error('Get my notifications error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error fetching notifications' });
  }
};

// GET /api/notifications/unread-count
const getUnreadCount = async (req, res) => {
  try {
    const unreadCount = await Notification.countDocuments({
      user: req.user._id,
      isRead: false,
    });
    res.json({ success: true, count: unreadCount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/notifications/:id/read
const markAsRead = async (req, res) => {
  try {
    const notif = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );
    if (!notif) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, notification: notif });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/notifications/read-all
const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/notifications/test-alert
// Allows sending or testing rider alerts directly
const sendTestAlert = async (req, res) => {
  try {
    const { title, body, type = 'system', data = {} } = req.body;
    const notif = await createNotification(req.user._id, {
      title: title || 'Fleet Alert',
      body: body || 'Test notification alert',
      type,
      data,
    });
    res.status(201).json({ success: true, notification: notif });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  createNotification,
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  sendTestAlert,
};
