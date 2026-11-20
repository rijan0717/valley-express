const express = require('express');
const router = express.Router();
const { updateRiderLocation } = require('../controllers/settingController');
const { protect, requireRole } = require('../middleware/auth');

router.post('/location', protect, requireRole('rider'), updateRiderLocation);

module.exports = router;
