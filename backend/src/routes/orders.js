const express = require('express');
const router = express.Router();
const {
  createOrder,
  getMyOrders,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  assignRider,
  cancelOrder,
  deleteOrder,
  getAvailableOrders,
  claimOrder,
} = require('../controllers/orderController');
const { protect, requireRole } = require('../middleware/auth');

router.post('/', protect, createOrder);
router.get('/my', protect, getMyOrders);
router.get('/available', protect, requireRole('rider', 'admin'), getAvailableOrders);
router.get('/', protect, requireRole('admin'), getAllOrders);
router.get('/:id', protect, getOrderById);
router.patch('/:id/claim', protect, requireRole('rider'), claimOrder);
router.patch('/:id/status', protect, requireRole('admin', 'rider'), updateOrderStatus);
router.patch('/:id/assign', protect, requireRole('admin'), assignRider);
router.patch('/:id/cancel', protect, cancelOrder);
router.delete('/:id', protect, requireRole('admin'), deleteOrder);

module.exports = router;
