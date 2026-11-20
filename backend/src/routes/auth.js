const express = require('express');
const router = express.Router();
const {
  adminLogin,
  riderLogin,
  register,
  customerLogin,
  forgotPassword,
  resetPassword,
  changePassword,
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
router.post('/register', register);
router.post('/customer-login', customerLogin);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/send-otp', sendOtp);
router.post('/verify-otp', verifyOtp);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/change-password', protect, changePassword);
router.patch('/rider/status', protect, requireRole('rider', 'admin'), toggleRiderStatus);

module.exports = router;
