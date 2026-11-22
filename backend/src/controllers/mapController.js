// Open API Map Controller: OpenStreetMap (OSM) & Nominatim Engine
// Provides live place search, reverse-geocoding, and Kathmandu Valley landmark database.

const KATHMANDU_VALLEY_LANDMARKS = [
  {
    id: 'kv-1',
    name: 'Baluwatar Chowk',
    area: 'Baluwatar',
    city: 'Kathmandu',
    displayAddress: 'Baluwatar Chowk, Prime Minister Residence Road, Kathmandu',
    latitude: 27.7280,
    longitude: 85.3300,
  },
  {
    id: 'kv-2',
    name: 'Thamel Tourist Hub',
    area: 'Thamel',
    city: 'Kathmandu',
    displayAddress: 'Thamel Marg, Chaksibari, Kathmandu',
    latitude: 27.7154,
    longitude: 85.3123,
  },
  {
    id: 'kv-3',
    name: 'Jhamsikhel Restaurant Street',
    area: 'Jhamsikhel',
    city: 'Lalitpur',
    displayAddress: 'Jhamsikhel Road, Ward 3, Lalitpur',
    latitude: 27.6833,
    longitude: 85.3125,
  },
  {
    id: 'kv-4',
    name: 'Patan Durbar Square',
    area: 'Mangalbazar',
    city: 'Lalitpur',
    displayAddress: 'Patan Durbar Square, Lalitpur 44700',
    latitude: 27.6727,
    longitude: 85.3253,
  },
  {
    id: 'kv-5',
    name: 'New Baneshwor Chowk',
    area: 'New Baneshwor',
    city: 'Kathmandu',
    displayAddress: 'New Baneshwor Chowk, Parliament Road, Kathmandu',
    latitude: 27.6915,
    longitude: 85.3420,
  },
  {
    id: 'kv-6',
    name: 'Old Baneshwor',
    area: 'Old Baneshwor',
    city: 'Kathmandu',
    displayAddress: 'Old Baneshwor Chowk, Battisputali Road, Kathmandu',
    latitude: 27.6980,
    longitude: 85.3435,
  },
  {
    id: 'kv-7',
    name: 'Durbar Marg Boulevard',
    area: 'Durbar Marg',
    city: 'Kathmandu',
    displayAddress: 'Durbar Marg, Narayanhiti Palace Gate, Kathmandu',
    latitude: 27.7107,
    longitude: 85.3172,
  },
  {
    id: 'kv-8',
    name: 'Boudhanath Stupa Gate',
    area: 'Boudha',
    city: 'Kathmandu',
    displayAddress: 'Boudha Road, Boudhanath UNESCO Heritage Site, Kathmandu',
    latitude: 27.7215,
    longitude: 85.3620,
  },
  {
    id: 'kv-9',
    name: 'Jawalakhel Roundabout',
    area: 'Jawalakhel',
    city: 'Lalitpur',
    displayAddress: 'Jawalakhel Chowk, Central Zoo Gate, Lalitpur',
    latitude: 27.6744,
    longitude: 85.3156,
  },
  {
    id: 'kv-10',
    name: 'Kupondole Heights',
    area: 'Kupondole',
    city: 'Lalitpur',
    displayAddress: 'Kupondole Road, Bagmati Bridge, Lalitpur',
    latitude: 27.6897,
    longitude: 85.3175,
  },
  {
    id: 'kv-11',
    name: 'Maharajgunj / Teaching Hospital',
    area: 'Maharajgunj',
    city: 'Kathmandu',
    displayAddress: 'Maharajgunj Chakrapath, T.U. Teaching Hospital, Kathmandu',
    latitude: 27.7371,
    longitude: 85.3323,
  },
  {
    id: 'kv-12',
    name: 'Lazimpat Embassy Quarter',
    area: 'Lazimpat',
    city: 'Kathmandu',
    displayAddress: 'Lazimpat Road, Near Hotel Shanker, Kathmandu',
    latitude: 27.7210,
    longitude: 85.3218,
  },
  {
    id: 'kv-13',
    name: 'Koteshwor Junction',
    area: 'Koteshwor',
    city: 'Kathmandu',
    displayAddress: 'Koteshwor Chowk, Ring Road & Arniko Highway, Kathmandu',
    latitude: 27.6780,
    longitude: 85.3490,
  },
  {
    id: 'kv-14',
    name: 'Kalanki Gateway Chowk',
    area: 'Kalanki',
    city: 'Kathmandu',
    displayAddress: 'Kalanki Underpass, Prithvi Highway Entrance, Kathmandu',
    latitude: 27.6934,
    longitude: 85.2818,
  },
  {
    id: 'kv-15',
    name: 'Bhaktapur Durbar Square',
    area: 'Durbar Square',
    city: 'Bhaktapur',
    displayAddress: 'Bhaktapur Durbar Square, UNESCO World Heritage, Bhaktapur',
    latitude: 27.6722,
    longitude: 85.4280,
  },
  {
    id: 'kv-16',
    name: 'Chabahil Stupa Chowk',
    area: 'Chabahil',
    city: 'Kathmandu',
    displayAddress: 'Chabahil Chowk, Charumati Buddhist Stupa, Kathmandu',
    latitude: 27.7170,
    longitude: 85.3520,
  },
  {
    id: 'kv-17',
    name: 'Tripureshwor / Dashrath Rangasala',
    area: 'Tripureshwor',
    city: 'Kathmandu',
    displayAddress: 'Tripureshwor Marg, Dashrath Stadium, Kathmandu',
    latitude: 27.6960,
    longitude: 85.3140,
  },
  {
    id: 'kv-18',
    name: 'Sinamangal / TIA Airport Road',
    area: 'Sinamangal',
    city: 'Kathmandu',
    displayAddress: 'Sinamangal Chowk, Airport Cargo Gate, Kathmandu',
    latitude: 27.6985,
    longitude: 85.3550,
  },
  {
    id: 'kv-19',
    name: 'Sanepa Heritage Colony',
    area: 'Sanepa',
    city: 'Lalitpur',
    displayAddress: 'Sanepa Road, Star Hospital Area, Lalitpur',
    latitude: 27.6850,
    longitude: 85.3050,
  },
  {
    id: 'kv-20',
    name: 'Dillibazar & Maitidevi Chowk',
    area: 'Dillibazar',
    city: 'Kathmandu',
    displayAddress: 'Dillibazar Road, Maitidevi Temple Chowk, Kathmandu',
    latitude: 27.7050,
    longitude: 85.3320,
  },
];

// Helper: Calculate distance in meters between 2 coordinates (Haversine)
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Find closest landmark in Kathmandu Valley
function findClosestLandmark(lat, lon) {
  let closest = KATHMANDU_VALLEY_LANDMARKS[0];
  let minDistance = Infinity;

  for (const landmark of KATHMANDU_VALLEY_LANDMARKS) {
    const d = getDistanceMeters(lat, lon, landmark.latitude, landmark.longitude);
    if (d < minDistance) {
      minDistance = d;
      closest = landmark;
    }
  }

  return { landmark: closest, distanceMeters: Math.round(minDistance) };
}

// GET /api/maps/popular
const getPopularLocations = async (req, res) => {
  try {
    const popular = KATHMANDU_VALLEY_LANDMARKS.slice(0, 8);
    res.json({ success: true, count: popular.length, locations: popular });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/maps/search?q=query
const searchPlaces = async (req, res) => {
  try {
    const query = (req.query.q || '').trim();
    if (!query) {
      return res.json({ success: true, count: 0, results: [] });
    }

    const lowerQuery = query.toLowerCase();

    // 1. Local fast search first for high responsiveness
    const localMatches = KATHMANDU_VALLEY_LANDMARKS.filter(
      (loc) =>
        loc.name.toLowerCase().includes(lowerQuery) ||
        loc.area.toLowerCase().includes(lowerQuery) ||
        loc.city.toLowerCase().includes(lowerQuery) ||
        loc.displayAddress.toLowerCase().includes(lowerQuery)
    );

    // 2. Query OpenStreetMap Nominatim Open API with timeout
    let osmResults = [];
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);

      const osmUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
        query
      )}&addressdetails=1&limit=20&countrycodes=np&viewbox=85.20,27.80,85.50,27.60`;

      const response = await fetch(osmUrl, {
        headers: {
          'User-Agent': 'ValleyExpressDeliveryApp/1.0 (info@valleyexpress.com.np)',
          'Accept-Language': 'en,ne',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        const data = await response.json();
        osmResults = (data || []).map((item) => {
          const addr = item.address || {};
          const primaryName =
            item.name ||
            addr.road ||
            addr.suburb ||
            addr.neighbourhood ||
            addr.village ||
            addr.city ||
            item.display_name.split(',')[0];

          return {
            id: `osm-${item.osm_id || item.place_id}`,
            name: primaryName,
            area: addr.suburb || addr.neighbourhood || addr.city_district || addr.quarter || 'Kathmandu',
            city: addr.city || addr.town || addr.county || 'Kathmandu Valley',
            displayAddress: item.display_name,
            latitude: parseFloat(item.lat),
            longitude: parseFloat(item.lon),
            source: 'openstreetmap',
          };
        });
      }
    } catch {
      // If Nominatim times out or network is restricted, fallback to Photon
    }

    // 3. Fallback to Photon geocoder (OpenStreetMap powered, instant autocomplete)
    if (osmResults.length === 0) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 3500);

        const photonUrl = `https://photon.komoot.io/api/?q=${encodeURIComponent(
          query
        )}&limit=10&lat=27.7172&lon=85.3240`;

        const response = await fetch(photonUrl, {
          headers: {
            'User-Agent': 'ValleyExpressDeliveryApp/1.0',
            'Accept-Language': 'en,ne',
          },
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (response.ok) {
          const data = await response.json();
          osmResults = (data.features || []).map((f) => {
            const props = f.properties || {};
            const coords = f.geometry?.coordinates || [85.33, 27.72];
            const name = props.name || props.street || query;
            const area = props.district || props.locality || props.city || '';
            const city = props.city || props.state || 'Nepal';
            const displayParts = [props.name, props.street, props.district, props.city, props.state, props.country].filter(Boolean);

            return {
              id: `photon-${props.osm_id || Math.random().toString(36).substring(7)}`,
              name,
              area: area || city,
              city: city,
              displayAddress: displayParts.length > 0 ? displayParts.join(', ') : `${name}, ${city}`,
              latitude: parseFloat(coords[1]),
              longitude: parseFloat(coords[0]),
              source: 'photon',
            };
          });
        }
      } catch {
        // Fallback gracefully
      }
    }

    // Combine results, prioritising exact local landmark matches followed by
    // OSM results.
    //
    // Coordinates are compared at 5 decimal places (~1m). The previous 3
    // places were ~110m, so two genuinely different addresses on the same
    // street collapsed into one and the list came back far shorter than the
    // places actually found.
    const coordKey = (item) =>
      `${item.latitude.toFixed(5)},${item.longitude.toFixed(5)}`;

    const combined = [...localMatches];
    const seen = new Set(localMatches.map(coordKey));

    for (const osmItem of osmResults) {
      const key = coordKey(osmItem);
      if (!seen.has(key)) {
        seen.add(key);
        combined.push(osmItem);
      }
    }

    res.json({
      success: true,
      count: combined.length,
      results: combined.slice(0, 20),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/maps/reverse?lat=27.728&lon=85.330
const reverseGeocode = async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lon = parseFloat(req.query.lon);

    if (isNaN(lat) || isNaN(lon)) {
      return res.status(400).json({ success: false, message: 'Valid lat and lon query parameters required' });
    }

    // Try OpenStreetMap Nominatim reverse geocoding
    let resolvedData = null;
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);

      const osmReverseUrl = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&addressdetails=1`;
      const response = await fetch(osmReverseUrl, {
        headers: {
          'User-Agent': 'ValleyExpressDeliveryApp/1.0 (info@valleyexpress.com.np)',
          'Accept-Language': 'en,ne',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        const data = await response.json();
        const addr = data.address || {};
        const road = addr.road || addr.pedestrian || addr.footway || '';
        const area = addr.suburb || addr.neighbourhood || addr.quarter || addr.city_district || '';
        const city = addr.city || addr.town || addr.municipality || 'Kathmandu';

        let shortTitle = '';
        if (road && area) {
          shortTitle = `${road}, ${area}`;
        } else if (area) {
          shortTitle = `${area}, ${city}`;
        } else if (road) {
          shortTitle = `${road}, ${city}`;
        } else {
          shortTitle = data.display_name.split(',').slice(0, 2).join(', ').trim();
        }

        resolvedData = {
          name: shortTitle || 'Selected Map Location',
          area: area || 'Kathmandu',
          city: city,
          displayAddress: data.display_name,
          latitude: lat,
          longitude: lon,
          source: 'openstreetmap',
        };
      }
    } catch {
      // Fallback
    }

    // Fallback: Use closest landmark
    if (!resolvedData) {
      const { landmark, distanceMeters } = findClosestLandmark(lat, lon);
      let shortTitle = landmark.name;
      let display = landmark.displayAddress;

      if (distanceMeters > 80) {
        shortTitle = `Near ${landmark.name}`;
        display = `${shortTitle} (~${distanceMeters}m), ${landmark.city}`;
      }

      resolvedData = {
        name: shortTitle,
        area: landmark.area,
        city: landmark.city,
        displayAddress: display,
        latitude: lat,
        longitude: lon,
        distanceToLandmarkMeters: distanceMeters,
        source: 'valley_express_network',
      };
    }

    res.json({
      success: true,
      location: resolvedData,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Resolves a pasted Google Maps URL, short link, or coordinate string.
 * Supports maps.app.goo.gl, goo.gl/maps, full Google Maps URLs, and raw coordinates.
 */
const resolveLocationUrl = async (req, res) => {
  try {
    const rawInput = (req.body?.url || req.query?.url || '').trim();
    if (!rawInput) {
      return res.status(400).json({ success: false, message: 'URL or coordinate text is required' });
    }

    // 1. Exact Google Maps Protobuf Place Pin (!3d{lat}!4d{lon}) — highest precision
    const directProtobufMatch = rawInput.match(/!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)/);
    if (directProtobufMatch) {
      return res.json({
        success: true,
        latitude: parseFloat(directProtobufMatch[1]),
        longitude: parseFloat(directProtobufMatch[2]),
        source: 'google_maps_protobuf',
      });
    }

    // 2. Query param pin (?q={lat},{lon} or ?ll={lat},{lon})
    const qMatch = rawInput.match(/[?&](?:q|ll)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/);
    if (qMatch) {
      return res.json({
        success: true,
        latitude: parseFloat(qMatch[1]),
        longitude: parseFloat(qMatch[2]),
        source: 'google_maps_query',
      });
    }

    // 3. Viewport camera center in URL (@{lat},{lon})
    const viewportMatch = rawInput.match(/@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/);
    if (viewportMatch && /^https?:\/\//i.test(rawInput)) {
      return res.json({
        success: true,
        latitude: parseFloat(viewportMatch[1]),
        longitude: parseFloat(viewportMatch[2]),
        source: 'google_maps_viewport',
      });
    }

    // 4. Standalone raw coordinates string (e.g. "27.7280, 85.3300" or "@27.7280,85.3300")
    const coordMatch = rawInput.match(/^@?(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)$/);
    if (coordMatch) {
      const lat = parseFloat(coordMatch[1]);
      const lon = parseFloat(coordMatch[2]);
      if (!isNaN(lat) && !isNaN(lon)) {
        return res.json({
          success: true,
          latitude: lat,
          longitude: lon,
          source: 'coordinates',
        });
      }
    }

    // 3. If it looks like a URL (especially goo.gl / maps.app.goo.gl), follow redirects
    if (/^https?:\/\//i.test(rawInput)) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 6000);

        const response = await fetch(rawInput, {
          method: 'GET',
          redirect: 'follow',
          headers: {
            'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          signal: controller.signal,
        });
        clearTimeout(timeoutId);

        const finalUrl = response.url || rawInput;

        // Check resolved URL for coords
        const finalProtobuf = finalUrl.match(/!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)/);
        if (finalProtobuf) {
          return res.json({
            success: true,
            latitude: parseFloat(finalProtobuf[1]),
            longitude: parseFloat(finalProtobuf[2]),
            resolvedUrl: finalUrl,
            source: 'resolved_url_protobuf',
          });
        }

        const finalAt = finalUrl.match(/@(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/);
        if (finalAt) {
          return res.json({
            success: true,
            latitude: parseFloat(finalAt[1]),
            longitude: parseFloat(finalAt[2]),
            resolvedUrl: finalUrl,
            source: 'resolved_url_at',
          });
        }

        const finalQ = finalUrl.match(/[?&](?:q|ll)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)/);
        if (finalQ) {
          return res.json({
            success: true,
            latitude: parseFloat(finalQ[1]),
            longitude: parseFloat(finalQ[2]),
            resolvedUrl: finalUrl,
            source: 'resolved_url_query',
          });
        }

        // Try reading body for meta coordinates or center=
        const bodyText = await response.text();
        const metaMatch =
          bodyText.match(/center=(-?\d{1,2}\.\d+)%2C(-?\d{1,3}\.\d+)/i) ||
          bodyText.match(/itemprop="latitude"\s+content="(-?\d{1,2}\.\d+)".*?itemprop="longitude"\s+content="(-?\d{1,3}\.\d+)"/s) ||
          bodyText.match(/\[null,null,(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)\]/);

        if (metaMatch) {
          return res.json({
            success: true,
            latitude: parseFloat(metaMatch[1]),
            longitude: parseFloat(metaMatch[2]),
            resolvedUrl: finalUrl,
            source: 'resolved_html_meta',
          });
        }
      } catch (netErr) {
        // Network timeout on follow redirect
      }
    }

    return res.status(422).json({
      success: false,
      message: 'Could not extract valid coordinates from the provided Google Maps link or text.',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  searchPlaces,
  reverseGeocode,
  getPopularLocations,
  resolveLocationUrl,
  KATHMANDU_VALLEY_LANDMARKS,
};
