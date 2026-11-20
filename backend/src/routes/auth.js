const express = require('express');
const router = express.Router();
const {
  adminLogin,
  riderLogin,
  sendOtp,
  verifyOtp,
  getMe,
  updateProfile,
  toggleRiderStatus,
} = require('../controllers/authController');
const { protect, requireRole } = require('../middleware/auth');

router.post('/admin-login', adminLogin);
router.post('/login', adminLogin);
router.post('/rider-login', riderLogin);
router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.patch('/rider/status', protect, requireRole('rider', 'admin'), toggleRiderStatus);

module.exports = router;
