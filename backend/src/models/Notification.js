const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
    },
    body: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: [
        'order_update',
        'promo',
        'system',
        'chat',
        'order_not_picked',
        'order_assigned',
        'order_cancelled',
        'new_order',
        'issue_update',
      ],
      default: 'order_update',
      index: true,
    },
    data: {
      orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
      orderNo: { type: String },
      issueId: { type: mongoose.Schema.Types.ObjectId, ref: 'Issue' },
      ticketNo: { type: String },
      url: { type: String },
      meta: { type: mongoose.Schema.Types.Mixed },
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
