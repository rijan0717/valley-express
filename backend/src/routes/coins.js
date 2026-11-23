const express = require('express');
const router = express.Router();
const {
  getMyCoins,
  getUserCoins,
  getCoinHolders,
} = require('../controllers/coinController');
const { protect, requireRole } = require('../middleware/auth');

// A customer only ever reads their own balance; the id never comes from the
// request, so one account cannot read another's ledger.
router.get('/me', protect, getMyCoins);

router.get('/admin/holders', protect, requireRole('admin'), getCoinHolders);
router.get('/admin/:id', protect, requireRole('admin'), getUserCoins);

module.exports = router;
