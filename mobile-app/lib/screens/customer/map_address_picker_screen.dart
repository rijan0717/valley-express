import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class SelectedLocation {
  final String addressText;
  final String landmark;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String contactPhone;

  SelectedLocation({
    required this.addressText,
    required this.landmark,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
  });
}

class MapAddressPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;
  final String initialAddress;
  final String initialLandmark;

  const MapAddressPickerScreen({
    super.key,
    this.initialLat = 27.7280,
    this.initialLon = 85.3300,
    this.initialAddress = 'Baluwatar, Kathmandu',
    this.initialLandmark = '',
  });

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  final ApiClient _api = ApiClient();
  final _searchController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController(text: '9841234567');

  late double _currentLat;
  late double _currentLon;
  int _zoom = 15;

  String _addressTitle = '';
  String _formattedAddress = '';
  bool _isReverseGeocoding = false;
  bool _isDragging = false;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Popular Kathmandu Valley Quick Zones
  final List<Map<String, dynamic>> _popularZones = [
    {'name': 'Baluwatar', 'lat': 27.7280, 'lon': 85.3300},
    {'name': 'Thamel', 'lat': 27.7154, 'lon': 85.3123},
    {'name': 'Jhamsikhel', 'lat': 27.6833, 'lon': 85.3125},
    {'name': 'Patan Durbar', 'lat': 27.6727, 'lon': 85.3253},
    {'name': 'New Baneshwor', 'lat': 27.6915, 'lon': 85.3420},
    {'name': 'Durbar Marg', 'lat': 27.7107, 'lon': 85.3172},
    {'name': 'Boudhanath', 'lat': 27.7215, 'lon': 85.3620},
    {'name': 'Maharajgunj', 'lat': 27.7371, 'lon': 85.3323},
    {'name': 'Koteshwor', 'lat': 27.6780, 'lon': 85.3490},
    {'name': 'Kalanki', 'lat': 27.6934, 'lon': 85.2818},
    {'name': 'Bhaktapur', 'lat': 27.6722, 'lon': 85.4280},
  ];

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLon = widget.initialLon;
    _addressTitle = widget.initialAddress;
    _formattedAddress = '$widget.initialAddress, Kathmandu Valley, Nepal';
    _landmarkController.text = widget.initialLandmark;
    _reverseGeocode(_currentLat, _currentLon);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Slippy tile mathematical converters
  int _lon2tileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _lat2tileY(double lat, int zoom) {
    final rad = lat * pi / 180.0;
    return ((1.0 - log(tan(rad) + 1.0 / cos(rad)) / pi) / 2.0 * (1 << zoom)).floor();
  }

  // Reverse geocoding via Open API
  Future<void> _reverseGeocode(double lat, double lon) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final res = await _api.dio.get('/maps/reverse', queryParameters: {'lat': lat, 'lon': lon});
      if (res.data['success'] == true && res.data['location'] != null) {
        final loc = res.data['location'];
        if (mounted) {
          setState(() {
            _addressTitle = loc['name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
            _formattedAddress = loc['displayAddress'] ?? '${loc['area']}, Kathmandu';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressTitle = 'Kathmandu Pin (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
          _formattedAddress = 'Selected Coordinates: $lat, $lon (Kathmandu Valley)';
        });
      }
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // Search places via Open API
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final res = await _api.dio.get('/maps/search', queryParameters: {'q': query.trim()});
        if (res.data['success'] == true && mounted) {
          setState(() {
            _searchResults = res.data['results'] ?? [];
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          final matches = _popularZones
              .where((z) => z['name'].toString().toLowerCase().contains(query.toLowerCase()))
              .toList();
          setState(() {
            _searchResults = matches.map((m) => {
              'name': m['name'],
              'area': m['name'],
              'city': 'Kathmandu Valley',
              'displayAddress': '${m['name']}, Kathmandu Valley',
              'latitude': m['lat'],
              'longitude': m['lon'],
            }).toList();
            _isSearching = false;
          });
        }
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> item) {
    final double lat = (item['latitude'] as num).toDouble();
    final double lon = (item['longitude'] as num).toDouble();
    _searchController.text = item['name'] ?? '';
    setState(() {
      _currentLat = lat;
      _currentLon = lon;
      _addressTitle = item['name'] ?? '';
      _formattedAddress = item['displayAddress'] ?? '';
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Convert screen pixel delta to geographic coordinate delta
    final double factor = 360.0 / (256.0 * (1 << _zoom));
    setState(() {
      _isDragging = true;
      _currentLon -= details.delta.dx * factor;
      _currentLat += details.delta.dy * factor * cos(_currentLat * pi / 180.0);
      _currentLat = _currentLat.clamp(27.5000, 27.9000);
      _currentLon = _currentLon.clamp(85.1000, 85.6000);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _reverseGeocode(_currentLat, _currentLon);
  }

  void _confirmLocation() {
    final result = SelectedLocation(
      addressText: _addressTitle,
      landmark: _landmarkController.text.trim(),
      formattedAddress: _formattedAddress,
      latitude: _currentLat,
      longitude: _currentLon,
      contactPhone: _phoneController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final int centerTileX = _lon2tileX(_currentLon, _zoom);
    final int centerTileY = _lat2tileY(_currentLat, _zoom);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery on Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Interactive OpenStreetMap Tile Canvas
          GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              color: const Color(0xFFE5E7EB),
              width: double.infinity,
              height: double.infinity,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final centerX = width / 2;
                    final centerY = height / 2;

                    // Render 3x3 OpenStreetMap Slippy Raster Tiles
                    return Stack(
                      children: [
                        for (int dx = -1; dx <= 1; dx++)
                          for (int dy = -1; dy <= 1; dy++)
                            Positioned(
                              left: centerX + (dx * 256.0) - 128.0,
                              top: centerY + (dy * 256.0) - 128.0,
                              width: 256.0,
                              height: 256.0,
                              child: Image.network(
                                'https://tile.openstreetmap.org/$_zoom/${centerTileX + dx}/${centerTileY + dy}.png',
                                fit: BoxFit.cover,
                                headers: const {
                                  'User-Agent': 'ValleyExpressFlutterApp/1.0',
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 32),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Center Draggable Pin (Pathao / Yango Floating Marker)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(0, _isDragging ? -14 : 0, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Text(
                          'Drop-off Point',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(Icons.location_on, size: 44, color: AppTheme.accent),
                    ],
                  ),
                ),
                // Shadow dot on ground
                Container(
                  width: _isDragging ? 8 : 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x59000000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 28), // Pin offset compensation
              ],
            ),
          ),

          // 3. Floating Top Search Bar & Suggestions
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Search Input Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.brandBlue, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.search, color: AppTheme.brandBlue, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Search Kathmandu chowk, street, area...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                    ],
                  ),
                ),

                // Search Results Dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                      itemBuilder: (context, idx) {
                        final item = _searchResults[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place, color: AppTheme.accent, size: 20),
                          title: Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.brandBlue),
                          ),
                          subtitle: Text(
                            item['displayAddress'] ?? '',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),

                // Popular Kathmandu Hub Chips
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularZones.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final zone = _popularZones[idx];
                      return ActionChip(
                        label: Text(
                          '📍 ${zone['name']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.brandBlue),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.brandBlue, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () {
                          setState(() {
                            _currentLat = zone['lat'];
                            _currentLon = zone['lon'];
                          });
                          _reverseGeocode(_currentLat, _currentLon);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. Zoom Controls & Location Button (Floating Right)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brandBlue,
                  onPressed: () {
                    if (_zoom < 18) setState(() => _zoom++);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brandBlue,
                  onPressed: () {
                    if (_zoom > 12) setState(() => _zoom--);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'myLoc',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.accent,
                  tooltip: 'Reset to Baluwatar Center',
                  onPressed: () {
                    setState(() {
                      _currentLat = 27.7280;
                      _currentLon = 85.3300;
                    });
                    _reverseGeocode(_currentLat, _currentLon);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // 5. Bottom Sheet Confirmation Card (Pathao / Yango Layout)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Name & GPS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.accent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isReverseGeocoding ? 'Detecting Street Name...' : _addressTitle,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.brandBlue),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formattedAddress,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMain),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '${_currentLat.toStringAsFixed(4)}N, ${_currentLon.toStringAsFixed(4)}E',
                            style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppTheme.brandBlue, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Specific Landmark & Rider Notes
                    TextField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Nearby Landmark / Gate / House No.',
                        hintText: 'e.g. Near Russian Embassy, House #42',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 14),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: _isReverseGeocoding ? null : _confirmLocation,
                      child: Text(
                        _isReverseGeocoding
                          ? 'Locating Pin...'
                          : 'Confirm Delivery Address (${_addressTitle.split(',')[0]})',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
