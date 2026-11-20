const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    nameNe: {
      type: String,
      default: '',
    },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
      index: true,
    },
    description: {
      type: String,
      default: '',
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    originalPrice: {
      type: Number,
      default: null,
    },
    discountPrice: {
      type: Number,
      default: null,
    },
    stock: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },
    unit: {
      type: String,
      default: 'item',
    },
    images: [{ type: String }],
    isAlcohol: {
      type: Boolean,
      default: false,
      index: true,
    },
    alcoholPercentage: {
      type: Number,
      default: 0,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    abv: {
      type: String, // e.g. "5.0%" or "40%"
      default: '',
    },
    volumeOrWeight: {
      type: String, // e.g. "650ml", "150g", "6 pcs"
      default: '',
    },
    temperatureServing: {
      type: String,
      enum: ['Chilled', 'Room Temperature', 'Hot & Fresh', 'Normal'],
      default: 'Normal',
    },
    tags: [{ type: String }],
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', productSchema);
