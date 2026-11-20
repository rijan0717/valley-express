const mongoose = require('mongoose');

const riderLocationSchema = new mongoose.Schema(
  {
    rider: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      index: true,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    heading: {
      type: Number,
      default: 0,
    },
    speed: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

riderLocationSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('RiderLocation', riderLocationSchema);
