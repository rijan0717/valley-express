const express = require('express');
const router = express.Router();
const {
  createIssue,
  getMyIssues,
  getAllIssues,
  updateIssueStatus,
  deleteIssue,
} = require('../controllers/issueController');
const { protect, requireRole } = require('../middleware/auth');

// Customer & Rider routes
router.post('/', protect, createIssue);
router.get('/my', protect, getMyIssues);

// Admin routes
router.get('/', protect, requireRole('admin'), getAllIssues);
router.patch('/:id/status', protect, requireRole('admin'), updateIssueStatus);
router.delete('/:id', protect, requireRole('admin'), deleteIssue);

module.exports = router;
