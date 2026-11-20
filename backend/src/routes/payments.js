const express = require('express');
const router = express.Router();
const {
  getPaymentMethods,
  initializePayment,
  verifyPayment,
} = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

// Public route to fetch supported payment channels
router.get('/methods', getPaymentMethods);

// Protected routes to initiate and verify payment transactions
router.post('/initialize', protect, initializePayment);
router.post('/verify', protect, verifyPayment);

module.exports = router;
