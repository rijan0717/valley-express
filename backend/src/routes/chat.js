const express = require('express');
const router = express.Router();
const {
  getMessagesByOrder,
  sendMessage,
  getAdminChatThreads,
  getFleetChatThreads,
  getUserConversations,
  getUnreadCount,
  markThreadRead,
} = require('../controllers/chatController');
const { protect, requireRole } = require('../middleware/auth');

router.get('/conversations', protect, getUserConversations);
router.get('/threads', protect, requireRole('admin'), getAdminChatThreads);
router.get('/fleet', protect, requireRole('admin'), getFleetChatThreads);
router.get('/unread', protect, getUnreadCount);
router.get('/:orderId', protect, getMessagesByOrder);
router.post('/:orderId/read', protect, markThreadRead);
router.post('/:orderId', protect, sendMessage);

module.exports = router;
