const express = require('express');
const router = express.Router();
const { updateRiderLocation, getRiderStats } = require('../controllers/settingController');
const { protect, requireRole } = require('../middleware/auth');

router.post('/location', protect, requireRole('rider'), updateRiderLocation);
router.get('/stats', protect, requireRole('rider'), getRiderStats);

module.exports = router;
