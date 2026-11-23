const mongoose = require('mongoose');

/// Every movement of a customer's Valley Coins, so a balance can always be
/// explained and admin can reconcile earned against spent per order.
const coinTransactionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      default: null,
    },
    orderNo: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      enum: ['earned', 'spent', 'reversed', 'adjusted'],
      required: true,
    },
    // Signed: positive credits the customer, negative debits them.
    coins: {
      type: Number,
      required: true,
    },
    // Balance after this entry was applied, so history reads without replay.
    balanceAfter: {
      type: Number,
      required: true,
    },
    note: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

coinTransactionSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('CoinTransaction', coinTransactionSchema);
