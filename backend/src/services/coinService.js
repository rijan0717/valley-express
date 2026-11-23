const CoinTransaction = require('../models/CoinTransaction');
const User = require('../models/User');
const { coinsForAmount } = require('../config/coins');

/// Moves a customer's Valley Coins and records why.
///
/// Every change goes through here so the balance and the ledger cannot drift
/// apart. Balances move with a conditional update rather than a read followed
/// by a write, so two requests racing on the same account cannot overdraw it
/// or lose a credit.

/// Credits coins. Returns the transaction, or null when there is nothing to do.
const credit = async ({ userId, coins, type, order, note }) => {
  const amount = Math.floor(Number(coins) || 0);
  if (amount <= 0) return null;

  const user = await User.findByIdAndUpdate(
    userId,
    { $inc: { valleyCoins: amount, coinsEarned: amount } },
    { new: true, select: 'valleyCoins' }
  );
  if (!user) return null;

  return CoinTransaction.create({
    user: userId,
    order: order ? order._id : null,
    orderNo: order ? order.orderNo : '',
    type: type || 'earned',
    coins: amount,
    balanceAfter: user.valleyCoins,
    note: note || '',
  });
};

/// Debits coins, refusing rather than going negative.
///
/// The balance check lives in the query, so the update only applies if the
/// coins are still there when it runs. Returns null when the balance is short.
const debit = async ({ userId, coins, type, order, note }) => {
  const amount = Math.floor(Number(coins) || 0);
  if (amount <= 0) return null;

  const user = await User.findOneAndUpdate(
    { _id: userId, valleyCoins: { $gte: amount } },
    { $inc: { valleyCoins: -amount, coinsSpent: amount } },
    { new: true, select: 'valleyCoins' }
  );
  if (!user) return null;

  return CoinTransaction.create({
    user: userId,
    order: order ? order._id : null,
    orderNo: order ? order.orderNo : '',
    type: type || 'spent',
    coins: -amount,
    balanceAfter: user.valleyCoins,
    note: note || '',
  });
};

/// Credits the coins a delivered order earned, once.
///
/// `coinsEarned` on the order is both the record and the guard: the update
/// only matches while it is still zero, so a repeated delivered transition
/// cannot pay out twice.
const awardForDeliveredOrder = async (Order, orderId) => {
  const order = await Order.findById(orderId).select(
    'customer orderNo total coinsEarned status'
  );
  if (!order || order.status !== 'delivered' || order.coinsEarned > 0) return null;

  const coins = coinsForAmount(order.total);
  if (coins <= 0) return null;

  const claimed = await Order.findOneAndUpdate(
    { _id: orderId, coinsEarned: 0 },
    { $set: { coinsEarned: coins } },
    { new: true }
  );
  if (!claimed) return null; // another request got there first

  return credit({
    userId: order.customer,
    coins,
    type: 'earned',
    order: claimed,
    note: `Earned on delivered order ${claimed.orderNo}`,
  });
};

/// Takes back the coins an order earned, once, when it is cancelled or
/// refunded after delivery. The balance is allowed to fall to zero but not
/// below, so a customer who already spent them is not pushed negative.
const reverseForOrder = async (Order, orderId) => {
  const claimed = await Order.findOneAndUpdate(
    { _id: orderId, coinsEarned: { $gt: 0 }, coinsReversed: false },
    { $set: { coinsReversed: true } },
    { new: true }
  );
  if (!claimed) return null;

  const holder = await User.findById(claimed.customer).select('valleyCoins');
  if (!holder) return null;

  const take = Math.min(claimed.coinsEarned, holder.valleyCoins);
  if (take <= 0) return null;

  const user = await User.findOneAndUpdate(
    { _id: claimed.customer, valleyCoins: { $gte: take } },
    { $inc: { valleyCoins: -take } },
    { new: true, select: 'valleyCoins' }
  );
  if (!user) return null;

  return CoinTransaction.create({
    user: claimed.customer,
    order: claimed._id,
    orderNo: claimed.orderNo,
    type: 'reversed',
    coins: -take,
    balanceAfter: user.valleyCoins,
    note: `Reversed for cancelled order ${claimed.orderNo}`,
  });
};

module.exports = { credit, debit, awardForDeliveredOrder, reverseForOrder };
