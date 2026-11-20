const express = require('express');
const router = express.Router();
const {
  getMessagesByOrder,
  sendMessage,
  getAdminChatThreads,
} = require('../controllers/chatController');
const { protect, requireRole } = require('../middleware/auth');

router.get('/threads', protect, requireRole('admin'), getAdminChatThreads);
router.get('/:orderId', protect, getMessagesByOrder);
router.post('/:orderId', protect, sendMessage);

module.exports = router;
