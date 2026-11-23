const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true, min: 1 },
  isAlcohol: { type: Boolean, default: false },
});

const statusHistorySchema = new mongoose.Schema({
  status: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  note: { type: String, default: '' },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
});

const orderSchema = new mongoose.Schema(
  {
    orderNo: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    customer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    rider: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    items: [orderItemSchema],
    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },
    deliveryFee: {
      type: Number,
      required: true,
      default: 0,
    },
    discount: {
      type: Number,
      default: 0,
    },
    total: {
      type: Number,
      required: true,
      min: 0,
    },
    offerCode: {
      type: String,
      default: '',
    },
    // Valley Coins applied to this bill, and the rupees they took off. Both
    // are computed on the server from the coin rate; the client never sends
    // a discount amount.
    coinsRedeemed: {
      type: Number,
      default: 0,
      min: 0,
    },
    coinDiscount: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Coins credited when this order was delivered. Doubles as the guard that
    // makes crediting idempotent: it is set in one atomic update.
    coinsEarned: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Set once those earned coins have been taken back, so a cancellation
    // cannot debit twice.
    coinsReversed: {
      type: Boolean,
      default: false,
    },
    // The same guard for coins spent on this order: a cancellation gives them
    // back once and only once.
    coinsRefunded: {
      type: Boolean,
      default: false,
    },
    deliveryAddress: {
      addressText: { type: String, required: true },
      landmark: { type: String, default: '' },
      formattedAddress: { type: String, default: '' },
      location: {
        type: { type: String, enum: ['Point'], default: 'Point' },
        coordinates: { type: [Number], required: true }, // [longitude, latitude]
      },
      contactPhone: { type: String, required: true },
    },
    status: {
      type: String,
      enum: [
        'placed',
        'accepted',
        'preparing',
        'rider_assigned',
        'picked_up',
        'on_the_way',
        'delivered',
        'cancelled',
        'rejected',
      ],
      default: 'placed',
      index: true,
    },
    statusHistory: [statusHistorySchema],
    paymentMethod: {
      type: String,
      enum: ['cash_on_delivery', 'esewa', 'khalti', 'fonepay'],
      default: 'cash_on_delivery',
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending',
    },
    containsAlcohol: {
      type: Boolean,
      default: false,
    },
    ageCheckedAtDoor: {
      type: Boolean,
      default: false,
    },
    customerNotes: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

orderSchema.virtual('address').get(function () {
  return this.deliveryAddress;
});

module.exports = mongoose.model('Order', orderSchema);
