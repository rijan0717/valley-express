const express = require('express');
const router = express.Router();
const {
  searchPlaces,
  reverseGeocode,
  getPopularLocations,
  resolveLocationUrl,
} = require('../controllers/mapController');
const { protect } = require('../middleware/auth');

// Public endpoints for customer and rider map interactions
router.get('/popular', getPopularLocations);
router.get('/search', searchPlaces);
router.get('/reverse', reverseGeocode);
// resolve-url makes a server-side fetch, so it is limited to signed-in users
// (and guarded against internal targets inside the controller).
router.post('/resolve-url', protect, resolveLocationUrl);
router.get('/resolve-url', protect, resolveLocationUrl);

module.exports = router;
