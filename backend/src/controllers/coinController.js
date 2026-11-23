const CoinTransaction = require('../models/CoinTransaction');
const User = require('../models/User');
const { rupeesForCoins, COIN_VALUE_RUPEES, RUPEES_PER_COIN } = require('../config/coins');

/// The signed-in customer's coin balance and recent history.
const getMyCoins = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select(
      'valleyCoins coinsEarned coinsSpent'
    );
    if (!user) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const ledger = await CoinTransaction.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({
      success: true,
      balance: user.valleyCoins,
      balanceValue: rupeesForCoins(user.valleyCoins),
      totalEarned: user.coinsEarned,
      totalSpent: user.coinsSpent,
      coinValue: COIN_VALUE_RUPEES,
      rupeesPerCoin: RUPEES_PER_COIN,
      transactions: ledger,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/// Admin view of one customer's coins: the same totals plus the full ledger,
/// so earned against spent can be reconciled per order.
const getUserCoins = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(
      'name phone email role valleyCoins coinsEarned coinsSpent'
    );
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const ledger = await CoinTransaction.find({ user: req.params.id })
      .sort({ createdAt: -1 })
      .limit(200);

    res.json({
      success: true,
      user,
      balance: user.valleyCoins,
      balanceValue: rupeesForCoins(user.valleyCoins),
      totalEarned: user.coinsEarned,
      totalSpent: user.coinsSpent,
      coinValue: COIN_VALUE_RUPEES,
      transactions: ledger,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/// Admin list of customers with coin balances, highest first.
const getCoinHolders = async (req, res) => {
  try {
    const users = await User.find({ role: 'customer' })
      .select('name phone email valleyCoins coinsEarned coinsSpent avatarUrl')
      .sort({ valleyCoins: -1 })
      .limit(200);

    res.json({
      success: true,
      count: users.length,
      coinValue: COIN_VALUE_RUPEES,
      users: users.map((u) => ({
        _id: u._id,
        name: u.name,
        phone: u.phone,
        email: u.email,
        avatarUrl: u.avatarUrl,
        balance: u.valleyCoins,
        balanceValue: rupeesForCoins(u.valleyCoins),
        totalEarned: u.coinsEarned,
        totalSpent: u.coinsSpent,
      })),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getMyCoins, getUserCoins, getCoinHolders };
