const mongoose = require('mongoose');

const settingSchema = new mongoose.Schema(
  {
    alcoholEnabled: {
      type: Boolean,
      default: false, // Alcohol toggle disabled by default until license is active
    },
    storeOpen: {
      type: Boolean,
      default: true,
    },
    serviceHours: {
      open: { type: String, default: '10:00' },
      close: { type: String, default: '23:30' },
    },
    defaultDeliveryFee: {
      type: Number,
      default: 100,
    },
    surgeFeePerKm: {
      type: Number,
      default: 25,
    },
    freeDeliveryThreshold: {
      type: Number,
      default: 1500,
    },
    deliveryZones: [
      {
        name: { type: String, required: true },
        polygon: {
          type: { type: String, enum: ['Polygon'], default: 'Polygon' },
          coordinates: [[[Number]]],
        },
        isActive: { type: Boolean, default: true },
      },
    ],
    contactPhone: {
      type: String,
      default: '+977-9800000000',
    },
    contactEmail: {
      type: String,
      default: 'support@valleyexpress.com.np',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Setting', settingSchema);
