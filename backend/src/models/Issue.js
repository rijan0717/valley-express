const mongoose = require('mongoose');

const issueSchema = new mongoose.Schema(
  {
    ticketNo: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    reporterRole: {
      type: String,
      enum: ['customer', 'rider', 'admin'],
      required: true,
      default: 'customer',
      index: true,
    },
    reporterName: {
      type: String,
      required: true,
    },
    reporterPhone: {
      type: String,
      default: '',
    },
    reporterEmail: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      minlength: [3, 'Title must be at least 3 characters'],
      maxlength: [120, 'Title cannot exceed 120 characters'],
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      minlength: [10, 'Description must be at least 10 characters'],
    },
    category: {
      type: String,
      enum: [
        'delivery',
        'order',
        'payment',
        'app_bug',
        'rider_behavior',
        'customer_behavior',
        'vehicle_breakdown',
        'store_stock',
        'delayed_pickup',
        'other',
      ],
      default: 'other',
    },
    screenshot: {
      type: String, // Base64 data URL or external URL
      default: null,
    },
    status: {
      type: String,
      enum: ['pending', 'investigating', 'resolved', 'rejected'],
      default: 'pending',
      index: true,
    },
    adminNote: {
      type: String,
      default: '',
      trim: true,
    },
    resolvedAt: {
      type: Date,
      default: null,
    },
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Issue', issueSchema);
