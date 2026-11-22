const express = require('express');
const router = express.Router();
const {
  searchPlaces,
  reverseGeocode,
  getPopularLocations,
  resolveLocationUrl,
} = require('../controllers/mapController');

// Public endpoints for customer and rider map interactions
router.get('/popular', getPopularLocations);
router.get('/search', searchPlaces);
router.get('/reverse', reverseGeocode);
router.post('/resolve-url', resolveLocationUrl);
router.get('/resolve-url', resolveLocationUrl);

module.exports = router;
