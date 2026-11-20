const express = require('express');
const router = express.Router();
const {
  searchPlaces,
  reverseGeocode,
  getPopularLocations,
} = require('../controllers/mapController');

// Public endpoints for customer and rider map interactions
router.get('/popular', getPopularLocations);
router.get('/search', searchPlaces);
router.get('/reverse', reverseGeocode);

module.exports = router;
