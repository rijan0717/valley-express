/// Valley Coins: the loyalty balance a customer earns by ordering.
///
/// One rupee paid earns one coin, and each coin is worth 0.1 rupee when it is
/// redeemed, so 100 coins take 10 rupees off a bill. Coins are credited only
/// once an order reaches `delivered`, and taken back if that order is later
/// cancelled or refunded.
const COIN_VALUE_RUPEES = 0.1;
const COINS_PER_RUPEE = 1;

/// Coins a paid amount earns. Rounded down so a bill never earns more than it
/// was worth.
const coinsForAmount = (amount) => {
  const value = Number(amount);
  if (!Number.isFinite(value) || value <= 0) return 0;
  return Math.floor(value * COINS_PER_RUPEE);
};

/// Rupees a number of coins is worth, to two decimals.
const rupeesForCoins = (coins) => {
  const value = Number(coins);
  if (!Number.isFinite(value) || value <= 0) return 0;
  return Math.round(value * COIN_VALUE_RUPEES * 100) / 100;
};

/// Most coins that may be applied to a bill, so a redemption can never take
/// the payable amount below zero.
const maxRedeemableCoins = (payableAmount, balance) => {
  const affordable = Math.floor(Number(payableAmount) / COIN_VALUE_RUPEES);
  return Math.max(0, Math.min(Number(balance) || 0, affordable));
};

module.exports = {
  COIN_VALUE_RUPEES,
  COINS_PER_RUPEE,
  coinsForAmount,
  rupeesForCoins,
  maxRedeemableCoins,
};
