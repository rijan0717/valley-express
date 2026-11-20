const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
  label: { type: String, default: 'Home' }, // Home, Work, Other
  addressText: { type: String, required: true },
  landmark: { type: String, default: '' },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true }, // [longitude, latitude]
  },
  isDefault: { type: Boolean, default: false },
});

const userSchema = new mongoose.Schema(
  {
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    name: {
      type: String,
      default: '',
      trim: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    password: {
      type: String,
    },
    role: {
      type: String,
      enum: ['customer', 'rider', 'admin'],
      default: 'customer',
      index: true,
    },
    ageConfirmed: {
      type: Boolean,
      default: false,
    },
    addresses: [addressSchema],
    fcmTokens: [{ type: String }],
    // Rider specific fields
    isOnline: {
      type: Boolean,
      default: false,
    },
    vehicleNumber: {
      type: String,
      default: '',
    },
    vehicleType: {
      type: String,
      default: 'Motorcycle',
    },
    currentCoordinates: {
      type: [Number],
      default: [85.3240, 27.7172],
    },
    currentLocation: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [85.3240, 27.7172] }, // Default Kathmandu
      updatedAt: { type: Date, default: Date.now },
    },
    status: {
      type: String,
      enum: ['active', 'suspended', 'pending_approval'],
      default: 'active',
    },
  },
  { timestamps: true }
);

userSchema.index({ currentLocation: '2dsphere' });

module.exports = mongoose.model('User', userSchema);
