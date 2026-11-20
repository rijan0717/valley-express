import React, { useState, useEffect, useRef } from 'react';
import api from '../api/client';
import { useModal } from '../context/ModalContext';

// Default Kathmandu Center Coordinates
const KATHMANDU_CENTER = { lat: 27.7172, lng: 85.3240 };

const POPULAR_ZONES = [
  { name: 'Baluwatar', lat: 27.7280, lng: 85.3300 },
  { name: 'Thamel', lat: 27.7154, lng: 85.3123 },
  { name: 'Jhamsikhel', lat: 27.6833, lng: 85.3125 },
  { name: 'Patan Durbar', lat: 27.6727, lng: 85.3253 },
  { name: 'New Baneshwor', lat: 27.6915, lng: 85.3420 },
  { name: 'Durbar Marg', lat: 27.7107, lng: 85.3172 },
  { name: 'Boudhanath', lat: 27.7215, lng: 85.3620 },
  { name: 'Maharajgunj', lat: 27.7371, lng: 85.3323 },
  { name: 'Koteshwor', lat: 27.6780, lng: 85.3490 },
  { name: 'Kalanki', lat: 27.6934, lng: 85.2818 },
  { name: 'Bhaktapur', lat: 27.6722, lng: 85.4280 },
];

export default function MapAddressPicker({
  initialLocation,
  onConfirm,
  onClose,
  isModal = true,
}) {
  const { showAlert } = useModal();
  const mapContainerRef = useRef(null);
  const leafletMapRef = useRef(null);
  const markerRef = useRef(null);

  const [currentCoords, setCurrentCoords] = useState(
    initialLocation?.coordinates
      ? { lat: initialLocation.coordinates[1], lng: initialLocation.coordinates[0] }
      : initialLocation?.latitude && initialLocation?.longitude
      ? { lat: initialLocation.latitude, lng: initialLocation.longitude }
      : KATHMANDU_CENTER
  );

  const [addressTitle, setAddressTitle] = useState(
    initialLocation?.addressText || initialLocation?.name || 'Baluwatar, Kathmandu'
  );
  const [displayAddress, setDisplayAddress] = useState(
    initialLocation?.formattedAddress || initialLocation?.displayAddress || 'Baluwatar, Kathmandu 44600, Nepal'
  );
  const [landmark, setLandmark] = useState(initialLocation?.landmark || '');
  const [contactPhone, setContactPhone] = useState(initialLocation?.contactPhone || '9841234567');

  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showSearchResults, setShowSearchResults] = useState(false);
  const [isReverseGeocoding, setIsReverseGeocoding] = useState(false);
  const [isDragging, setIsDragging] = useState(false);

  // Initialize or update Leaflet Map
  useEffect(() => {
    let map = leafletMapRef.current;

    const initMap = () => {
      if (!mapContainerRef.current) return;
      if (!window.L) {
        // Retry shortly if Leaflet script is still downloading
        const timer = setTimeout(initMap, 200);
        return () => clearTimeout(timer);
      }

      if (map) {
        map.remove();
      }

      // Create Leaflet instance
      map = window.L.map(mapContainerRef.current, {
        center: [currentCoords.lat, currentCoords.lng],
        zoom: 15,
        zoomControl: false,
      });

      // Free OpenStreetMap tile layer (Open API)
      window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(map);

      // Custom Valley Express Branded Orange Pin Marker
      const valleyPinIcon = window.L.divIcon({
        className: 'custom-valley-pin',
        html: `
          <div style="position: relative; display: flex; flex-direction: column; align-items: center; transform: translate(-50%, -100%);">
            <div style="background: #FF6B1A; color: #FFFFFF; font-weight: 700; font-size: 11px; padding: 3px 8px; border-radius: 12px; box-shadow: 0 2px 6px rgba(0,0,0,0.25); white-space: nowrap; margin-bottom: 2px; border: 1.5px solid #FFFFFF;">
              Drop-off Point
            </div>
            <svg width="36" height="44" viewBox="0 0 24 30" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 0C5.37258 0 0 5.37258 0 12C0 19.5 12 30 12 30C12 30 24 19.5 24 12C24 5.37258 18.6274 0 12 0Z" fill="#FF6B1A"/>
              <circle cx="12" cy="11" r="5" fill="#FFFFFF"/>
              <circle cx="12" cy="11" r="2.5" fill="#003893"/>
            </svg>
          </div>
        `,
        iconSize: [36, 44],
        iconAnchor: [18, 44],
      });

      const marker = window.L.marker([currentCoords.lat, currentCoords.lng], {
        icon: valleyPinIcon,
        draggable: true,
      }).addTo(map);

      markerRef.current = marker;

      // When marker is dragged
      marker.on('dragstart', () => {
        setIsDragging(true);
      });

      marker.on('dragend', (e) => {
        setIsDragging(false);
        const { lat, lng } = e.target.getLatLng();
        handleLocationSelect(lat, lng, true);
      });

      // When user clicks anywhere on map
      map.on('click', (e) => {
        const { lat, lng } = e.latlng;
        marker.setLatLng([lat, lng]);
        handleLocationSelect(lat, lng, true);
      });

      // When map finishes panning
      map.on('movestart', () => {
        setIsDragging(true);
      });

      map.on('moveend', () => {
        setIsDragging(false);
      });

      leafletMapRef.current = map;
    };

    initMap();

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, []);

  // Reverse geocode via Open API (Nominatim backend proxy)
  const handleLocationSelect = async (lat, lng, flyTo = false) => {
    setCurrentCoords({ lat, lng });

    if (flyTo && leafletMapRef.current) {
      leafletMapRef.current.panTo([lat, lng]);
    }
    if (markerRef.current) {
      markerRef.current.setLatLng([lat, lng]);
    }

    setIsReverseGeocoding(true);
    try {
      const res = await api.get(`/maps/reverse?lat=${lat}&lon=${lng}`);
      if (res.data.success && res.data.location) {
        setAddressTitle(res.data.location.name || `${lat.toFixed(4)}, ${lng.toFixed(4)}`);
        setDisplayAddress(res.data.location.displayAddress || `${res.data.location.area}, Kathmandu`);
      }
    } catch {
      // Fallback display
      setAddressTitle(`Selected Pin (${lat.toFixed(4)}, ${lng.toFixed(4)})`);
      setDisplayAddress(`Kathmandu Valley Coordinates: ${lat.toFixed(5)} N, ${lng.toFixed(5)} E`);
    } finally {
      setIsReverseGeocoding(false);
    }
  };

  // Debounced search places via Open API
  useEffect(() => {
    if (!searchQuery.trim() || searchQuery.trim().length < 2) {
      setSearchResults([]);
      setShowSearchResults(false);
      return;
    }

    const timer = setTimeout(async () => {
      setIsSearching(true);
      try {
        const res = await api.get(`/maps/search?q=${encodeURIComponent(searchQuery.trim())}`);
        if (res.data.success) {
          setSearchResults(res.data.results || []);
          setShowSearchResults(true);
        }
      } catch {
        // Fallback filter local
        const localMatches = POPULAR_ZONES.filter((z) =>
          z.name.toLowerCase().includes(searchQuery.toLowerCase())
        );
        setSearchResults(
          localMatches.map((m) => ({
            name: m.name,
            area: m.name,
            city: 'Kathmandu Valley',
            displayAddress: `${m.name}, Kathmandu Valley`,
            latitude: m.lat,
            longitude: m.lng,
          }))
        );
        setShowSearchResults(true);
      } finally {
        setIsSearching(false);
      }
    }, 350);

    return () => clearTimeout(timer);
  }, [searchQuery]);

  // Use GPS device geolocation
  const handleUseCurrentLocation = () => {
    if (!navigator.geolocation) {
      showAlert('Geolocation is not supported by your browser.', 'Location Error', 'warning');
      return;
    }

    setIsReverseGeocoding(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        if (leafletMapRef.current) {
          leafletMapRef.current.flyTo([latitude, longitude], 16);
        }
        handleLocationSelect(latitude, longitude, true);
      },
      () => {
        // Default to central Kathmandu if denied
        if (leafletMapRef.current) {
          leafletMapRef.current.flyTo([KATHMANDU_CENTER.lat, KATHMANDU_CENTER.lng], 15);
        }
        handleLocationSelect(KATHMANDU_CENTER.lat, KATHMANDU_CENTER.lng, true);
      },
      { enableHighAccuracy: true, timeout: 5000 }
    );
  };

  const handleConfirm = () => {
    const selectedLocationData = {
      addressText: addressTitle,
      landmark: landmark.trim(),
      formattedAddress: displayAddress,
      latitude: currentCoords.lat,
      longitude: currentCoords.lng,
      contactPhone: contactPhone.trim(),
      location: {
        type: 'Point',
        coordinates: [currentCoords.lng, currentCoords.lat], // GeoJSON standard: [longitude, latitude]
      },
    };

    if (onConfirm) {
      onConfirm(selectedLocationData);
    }
  };

  const content = (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        minHeight: isModal ? '540px' : '420px',
        display: 'flex',
        flexDirection: 'column',
        background: '#FFFFFF',
        borderRadius: isModal ? '8px' : '4px',
        overflow: 'hidden',
        boxShadow: isModal ? '0 8px 30px rgba(0,0,0,0.3)' : 'none',
      }}
    >
      {/* Top Floating Header & Search Bar (Pathao / Yango UX) */}
      <div
        style={{
          position: 'absolute',
          top: 12,
          left: 12,
          right: 12,
          zIndex: 1000,
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            background: '#FFFFFF',
            border: '2px solid #003893',
            borderRadius: '8px',
            padding: '4px 8px',
            boxShadow: '0 4px 12px rgba(0, 56, 147, 0.15)',
          }}
        >
          <span style={{ fontSize: '18px', marginRight: '8px', color: '#003893' }}>🔍</span>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onFocus={() => {
              if (searchResults.length > 0) setShowSearchResults(true);
            }}
            placeholder="Search Kathmandu chowk, street, landmark (e.g. Baluwatar, Thamel, Patan)..."
            style={{
              flex: 1,
              border: 'none',
              outline: 'none',
              fontSize: '13px',
              fontFamily: 'Poppins, sans-serif',
              fontWeight: 500,
              color: '#1F2A44',
              background: 'transparent',
              padding: '6px 0',
            }}
          />
          {searchQuery && (
            <button
              onClick={() => {
                setSearchQuery('');
                setSearchResults([]);
                setShowSearchResults(false);
              }}
              style={{
                border: 'none',
                background: 'transparent',
                color: '#666',
                cursor: 'pointer',
                fontWeight: 700,
                padding: '4px 8px',
              }}
            >
              ✕
            </button>
          )}
          {isModal && onClose && (
            <button
              onClick={onClose}
              style={{
                border: 'none',
                background: '#FF6B1A',
                color: '#FFFFFF',
                borderRadius: '4px',
                fontSize: '11px',
                fontWeight: 700,
                cursor: 'pointer',
                padding: '5px 10px',
                marginLeft: '6px',
              }}
            >
              Close
            </button>
          )}
        </div>

        {/* Live Search Suggestions Dropdown */}
        {showSearchResults && searchResults.length > 0 && (
          <div
            style={{
              background: '#FFFFFF',
              border: '1px solid #D1D5DB',
              borderRadius: '8px',
              maxHeight: '220px',
              overflowY: 'auto',
              boxShadow: '0 8px 24px rgba(0,0,0,0.18)',
            }}
          >
            {searchResults.map((item, idx) => (
              <div
                key={item.id || idx}
                onClick={() => {
                  setSearchQuery(item.name);
                  setShowSearchResults(false);
                  if (leafletMapRef.current) {
                    leafletMapRef.current.flyTo([item.latitude, item.longitude], 16);
                  }
                  handleLocationSelect(item.latitude, item.longitude, true);
                }}
                style={{
                  padding: '10px 14px',
                  borderBottom: idx < searchResults.length - 1 ? '1px solid #F3F4F6' : 'none',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '10px',
                  transition: 'background 0.15s',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.background = '#F8FAFC')}
                onMouseLeave={(e) => (e.currentTarget.style.background = '#FFFFFF')}
              >
                <span style={{ fontSize: '16px', color: '#FF6B1A' }}>📍</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '13px', fontWeight: 700, color: '#003893' }}>
                    {item.name}
                  </div>
                  <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '2px', lineHeight: 1.3 }}>
                    {item.displayAddress}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Quick Location Chips (Popular Kathmandu Hubs) */}
        <div
          style={{
            display: 'flex',
            gap: '6px',
            overflowX: 'auto',
            paddingBottom: '4px',
            scrollbarWidth: 'none',
          }}
        >
          {POPULAR_ZONES.map((zone) => (
            <button
              key={zone.name}
              type="button"
              onClick={() => {
                if (leafletMapRef.current) {
                  leafletMapRef.current.flyTo([zone.lat, zone.lng], 16);
                }
                handleLocationSelect(zone.lat, zone.lng, true);
              }}
              style={{
                background: currentCoords.lat === zone.lat ? '#003893' : '#FFFFFF',
                color: currentCoords.lat === zone.lat ? '#FFFFFF' : '#003893',
                border: '1px solid #003893',
                borderRadius: '16px',
                padding: '4px 10px',
                fontSize: '11px',
                fontWeight: 700,
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
              }}
            >
              📍 {zone.name}
            </button>
          ))}
        </div>
      </div>

      {/* Main Map Tile Container */}
      <div
        ref={mapContainerRef}
        style={{
          flex: 1,
          width: '100%',
          minHeight: '260px',
          background: '#E5E7EB',
          position: 'relative',
        }}
      />

      {/* Floating Center Crosshair Helper if dragging */}
      {isDragging && (
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            pointerEvents: 'none',
            zIndex: 900,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <div
            style={{
              width: '12px',
              height: '12px',
              borderRadius: '50%',
              background: '#FF6B1A',
              border: '2px solid #FFFFFF',
              boxShadow: '0 0 8px rgba(255, 107, 26, 0.8)',
            }}
          />
        </div>
      )}

      {/* Floating GPS Target Button */}
      <div
        style={{
          position: 'absolute',
          bottom: '210px',
          right: '16px',
          zIndex: 900,
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
        }}
      >
        <button
          type="button"
          onClick={handleUseCurrentLocation}
          title="Use My Current GPS Location"
          style={{
            width: '42px',
            height: '42px',
            borderRadius: '50%',
            background: '#FFFFFF',
            border: '2px solid #003893',
            color: '#003893',
            fontSize: '18px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
          }}
        >
          🎯
        </button>
        <button
          type="button"
          onClick={() => {
            if (leafletMapRef.current) leafletMapRef.current.zoomIn();
          }}
          style={{
            width: '36px',
            height: '36px',
            borderRadius: '4px',
            background: '#FFFFFF',
            border: '1px solid #D1D5DB',
            color: '#1F2A44',
            fontSize: '18px',
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          +
        </button>
        <button
          type="button"
          onClick={() => {
            if (leafletMapRef.current) leafletMapRef.current.zoomOut();
          }}
          style={{
            width: '36px',
            height: '36px',
            borderRadius: '4px',
            background: '#FFFFFF',
            border: '1px solid #D1D5DB',
            color: '#1F2A44',
            fontSize: '18px',
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          -
        </button>
      </div>

      {/* Bottom Sheet / Location Confirmation Card (Pathao / Yango Layout) */}
      <div
        style={{
          background: '#FFFFFF',
          borderTop: '2px solid #003893',
          padding: '14px 16px',
          zIndex: 950,
          boxShadow: '0 -4px 16px rgba(0,0,0,0.08)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ fontSize: '16px', color: '#FF6B1A' }}>📍</span>
              <span style={{ fontSize: '14px', fontWeight: 700, color: '#003893' }}>
                {isReverseGeocoding ? 'Detecting Street Address...' : addressTitle}
              </span>
            </div>
            <div style={{ fontSize: '11px', color: '#1F2A44', marginTop: '2px', maxWidth: '380px' }}>
              {displayAddress}
            </div>
          </div>
          <span
            style={{
              fontSize: '10px',
              fontFamily: 'monospace',
              background: '#F3F4F6',
              border: '1px solid #D1D5DB',
              padding: '2px 6px',
              borderRadius: '4px',
              color: '#003893',
              fontWeight: 700,
              whiteSpace: 'nowrap',
            }}
          >
            {currentCoords.lat.toFixed(4)}N, {currentCoords.lng.toFixed(4)}E
          </span>
        </div>

        {/* Specific Landmark / House info */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '12px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '10px', fontWeight: 700, color: '#1F2A44', marginBottom: '3px' }}>
              Nearby Landmark / Gate / House No.
            </label>
            <input
              type="text"
              value={landmark}
              onChange={(e) => setLandmark(e.target.value)}
              placeholder="e.g. Near Russian Embassy, House #42"
              style={{
                width: '100%',
                padding: '6px 8px',
                border: '1px solid #D1D5DB',
                borderRadius: '4px',
                fontSize: '12px',
                color: '#1F2A44',
                outline: 'none',
              }}
            />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '10px', fontWeight: 700, color: '#1F2A44', marginBottom: '3px' }}>
              Rider Contact Phone
            </label>
            <input
              type="text"
              value={contactPhone}
              onChange={(e) => setContactPhone(e.target.value)}
              placeholder="e.g. 9841234567"
              style={{
                width: '100%',
                padding: '6px 8px',
                border: '1px solid #D1D5DB',
                borderRadius: '4px',
                fontSize: '12px',
                color: '#1F2A44',
                outline: 'none',
              }}
            />
          </div>
        </div>

        {/* Action Button */}
        <button
          type="button"
          onClick={handleConfirm}
          disabled={isReverseGeocoding}
          style={{
            width: '100%',
            background: '#FF6B1A',
            color: '#FFFFFF',
            border: 'none',
            borderRadius: '4px',
            padding: '12px',
            fontSize: '14px',
            fontWeight: 700,
            cursor: isReverseGeocoding ? 'not-allowed' : 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            boxShadow: '0 2px 6px rgba(255, 107, 26, 0.4)',
          }}
        >
          <span>✓ Confirm Delivery Location</span>
          <span style={{ fontSize: '11px', opacity: 0.9 }}>({addressTitle.split(',')[0]})</span>
        </button>
      </div>
    </div>
  );

  if (isModal) {
    return (
      <div
        style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0, 0, 0, 0.6)',
          zIndex: 2000,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '16px',
        }}
      >
        <div style={{ width: '100%', maxWidth: '640px', height: '620px', position: 'relative' }}>
          {content}
        </div>
      </div>
    );
  }

  return content;
}
