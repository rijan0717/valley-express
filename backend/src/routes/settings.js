const express = require('express');
const router = express.Router();
const {
  getSettings,
  updateSettings,
  getAllRiders,
  createRider,
  updateRider,
  deleteRider,
  toggleRiderDuty,
} = require('../controllers/settingController');
const { protect, requireRole } = require('../middleware/auth');

router.get('/', getSettings);
router.put('/', protect, requireRole('admin'), updateSettings);

// Rider fleet CRUD
router.get('/riders', protect, requireRole('admin'), getAllRiders);
router.post('/riders', protect, requireRole('admin'), createRider);
router.put('/riders/:id', protect, requireRole('admin'), updateRider);
router.delete('/riders/:id', protect, requireRole('admin'), deleteRider);
router.patch('/riders/:id/toggle', protect, requireRole('admin'), toggleRiderDuty);

module.exports = router;
