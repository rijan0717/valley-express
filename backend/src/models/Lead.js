const mongoose = require('mongoose');

/**
 * Public-website leads: app launch notifications and contact-form messages.
 * Written by anonymous visitors, so every field is length-capped and the
 * source is pinned to a known set rather than taken from the request.
 */
const leadSchema = new mongoose.Schema(
  {
    source: {
      type: String,
      enum: ['app-notify', 'contact'],
      required: true,
    },
    name: { type: String, trim: true, maxlength: 120, default: '' },
    email: { type: String, trim: true, lowercase: true, maxlength: 200, default: '' },
    phone: { type: String, trim: true, maxlength: 30, default: '' },
    subject: { type: String, trim: true, maxlength: 160, default: '' },
    message: { type: String, trim: true, maxlength: 4000, default: '' },
    platform: {
      type: String,
      enum: ['android', 'ios', 'either'],
      default: 'either',
    },
    handled: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// The notify list is deduplicated per contact, so a visitor tapping twice does
// not land in the list twice.
leadSchema.index(
  { source: 1, email: 1, phone: 1 },
  { unique: true, partialFilterExpression: { source: 'app-notify' } }
);

module.exports = mongoose.model('Lead', leadSchema);
