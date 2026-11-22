const express = require('express');
const router = express.Router();
const { updateRiderLocation, getRiderStats, getFleetSummary } = require('../controllers/settingController');
const { protect, requireRole } = require('../middleware/auth');

router.post('/location', protect, requireRole('rider'), updateRiderLocation);
router.get('/stats', protect, requireRole('rider'), getRiderStats);
router.get('/fleet-summary', protect, requireRole('rider', 'admin'), getFleetSummary);

module.exports = router;
