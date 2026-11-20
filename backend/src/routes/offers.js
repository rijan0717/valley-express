const express = require('express');
const router = express.Router();
const {
  getOffers,
  getAllOffers,
  createOffer,
  toggleOffer,
  updateOffer,
  deleteOffer,
  validateOffer,
} = require('../controllers/offerController');
const { protect, requireRole } = require('../middleware/auth');

router.get('/', getOffers);
router.get('/all', protect, requireRole('admin'), getAllOffers);
router.post('/validate', validateOffer);
router.post('/', protect, requireRole('admin'), createOffer);
router.put('/:id', protect, requireRole('admin'), updateOffer);
router.delete('/:id', protect, requireRole('admin'), deleteOffer);
router.patch('/:id/toggle', protect, requireRole('admin'), toggleOffer);

module.exports = router;
