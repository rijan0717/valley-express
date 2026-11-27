const express = require('express');
const router = express.Router();
const {
  createNotifyLead,
  createContactLead,
  getLeads,
  updateLead,
  deleteLead,
} = require('../controllers/leadController');
const { protect, requireRole } = require('../middleware/auth');

// Public: the website's only write paths. The throttle that protects them is
// mounted in app.js.
router.post('/notify', createNotifyLead);
router.post('/contact', createContactLead);

// Admin: the enquiry inbox behind the dashboard.
router.get('/', protect, requireRole('admin'), getLeads);
router.patch('/:id', protect, requireRole('admin'), updateLead);
router.delete('/:id', protect, requireRole('admin'), deleteLead);

module.exports = router;
