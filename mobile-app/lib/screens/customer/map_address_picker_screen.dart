import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/preferences_provider.dart';

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
  final _phoneController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();

  MapLibreMapController? _mapController;
  late double _currentLat;
  late double _currentLon;
  double _currentZoom = 15.0;

  String _addressTitle = '';
  String _formattedAddress = '';
  bool _isReverseGeocoding = false;
  bool _isDragging = false;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // 'idle' | 'locating' | 'found' | 'error'
  String _locateState = 'idle';
  int? _gpsAccuracy;
  String _searchedTerm = '';

  // Popular Quick Zones across Nepal (including Smriti Marg, Thapathali matching prototype)
  List<Map<String, dynamic>> _popularZones = [
    {
      'name': 'Smriti Marg, Thapathali',
      'lat': 27.6938,
      'lon': 85.3210,
      'full': 'Smriti Marg, Thapathali, Kathmandu-11, Bagamati Province, 44617, Nepal',
      'landmark': 'House #42, Near Russian Embassy gate',
    },
    {
      'name': 'Baluwatar',
      'lat': 27.7280,
      'lon': 85.3300,
      'full': 'Baluwatar Chowk, Ward 4, Kathmandu, Nepal',
      'landmark': 'Near Russian Embassy / Prime Minister Residence',
    },
    {
      'name': 'Thamel',
      'lat': 27.7154,
      'lon': 85.3123,
      'full': 'Z-Street, Near Chhiring Plaza, Thamel, Kathmandu, Nepal',
      'landmark': 'Mandala Street / Chaksibari Marg',
    },
    {
      'name': 'Jhamsikhel',
      'lat': 27.6833,
      'lon': 85.3125,
      'full': 'Restaurant Lane, Ward 3, Jhamsikhel, Lalitpur, Nepal',
      'landmark': 'Near St. Mary\'s High School',
    },
    {
      'name': 'Patan Durbar',
      'lat': 27.6727,
      'lon': 85.3253,
      'full': 'Mangal Bazaar, Ward 12, Patan, Lalitpur, Nepal',
      'landmark': 'Near Krishna Mandir',
    },
    {
      'name': 'Naxal Central Hub',
      'lat': 27.7150,
      'lon': 85.3280,
      'full': 'Bhagwati Bahal, Naxal, Kathmandu, Nepal',
      'landmark': 'Valley Express Central Hub',
    },
    {
      'name': 'New Baneshwor',
      'lat': 27.6915,
      'lon': 85.3420,
      'full': 'Baneshwor Chowk, Kathmandu-10, Nepal',
      'landmark': 'Near International Convention Centre (ICC)',
    },
    {
      'name': 'Durbar Marg',
      'lat': 27.7107,
      'lon': 85.3172,
      'full': 'Kingsway Avenue, Narayanhiti, Kathmandu, Nepal',
      'landmark': 'Opposite Hotel Annapurna',
    },
    {
      'name': 'Lazimpat',
      'lat': 27.7220,
      'lon': 85.3180,
      'full': 'Lazimpat Road, Ward 2, Kathmandu, Nepal',
      'landmark': 'Near Hotel Shanker & Radisson',
    },
    {
      'name': 'Boudhanath',
      'lat': 27.7215,
      'lon': 85.3620,
      'full': 'Stupa Circle, Boudha, Kathmandu, Nepal',
      'landmark': 'Main Stupa Gate',
    },
    {
      'name': 'Maharajgunj',
      'lat': 27.7371,
      'lon': 85.3323,
      'full': 'Maharajgunj Chowk, Ring Road, Kathmandu, Nepal',
      'landmark': 'Near Teaching Hospital',
    },
    {
      'name': 'Koteshwor',
      'lat': 27.6780,
      'lon': 85.3490,
      'full': 'Koteshwor Intersection, Kathmandu-32, Nepal',
      'landmark': 'Near Jadibuti / Tinkune bridge',
    },
    {
      'name': 'Tripureshwor',
      'lat': 27.6950,
      'lon': 85.3140,
      'full': 'Tripureshwor Chowk, Ward 11, Kathmandu, Nepal',
      'landmark': 'Near Dasharath Stadium & WTC',
    },
    {
      'name': 'Maitighar',
      'lat': 27.6920,
      'lon': 85.3230,
      'full': 'Maitighar Mandala Circle, Kathmandu, Nepal',
      'landmark': 'Near St. Xavier\'s College',
    },
  ];

  static final List<Map<String, dynamic>> _kathmanduDatabase = [
    {
      'name': 'Smriti Marg, Thapathali',
      'area': 'Thapathali',
      'city': 'Kathmandu',
      'displayAddress': 'Smriti Marg, Thapathali, Kathmandu-11, Bagamati Province, 44617, Nepal',
      'landmark': 'House #42, Near Russian Embassy gate / Norvic',
      'latitude': 27.6938,
      'longitude': 85.3210,
      'aliases': ['smriti', 'smriti marg', 'smriti marga', 'smirti', 'smirti marg', 'smirti marga', 'thapathali', 'norvic', 'russian embassy', 'bagamati corridor'],
    },
    {
      'name': 'Baluwatar',
      'area': 'Baluwatar',
      'city': 'Kathmandu',
      'displayAddress': 'Baluwatar Chowk, Ward 4, Kathmandu, Nepal',
      'landmark': 'Near Russian Embassy / Prime Minister Residence',
      'latitude': 27.7280,
      'longitude': 85.3300,
      'aliases': ['baluwatar', 'tundidevi', 'prime minister', 'gairidhara', 'russian'],
    },
    {
      'name': 'Thamel',
      'area': 'Thamel',
      'city': 'Kathmandu',
      'displayAddress': 'Z-Street, Near Chhiring Plaza, Thamel, Kathmandu, Nepal',
      'landmark': 'Mandala Street / Chaksibari Marg',
      'latitude': 27.7154,
      'longitude': 85.3123,
      'aliases': ['thamel', 'z-street', 'chaksibari', 'mandala', 'tridevi'],
    },
    {
      'name': 'Jhamsikhel',
      'area': 'Jhamsikhel',
      'city': 'Lalitpur',
      'displayAddress': 'Restaurant Lane, Ward 3, Jhamsikhel, Lalitpur, Nepal',
      'landmark': 'Near St. Mary\'s High School',
      'latitude': 27.6833,
      'longitude': 85.3125,
      'aliases': ['jhamsikhel', 'st marys', 'restaurant lane', 'sanepa'],
    },
    {
      'name': 'Patan Durbar Square',
      'area': 'Patan',
      'city': 'Lalitpur',
      'displayAddress': 'Mangal Bazaar, Ward 12, Patan, Lalitpur, Nepal',
      'landmark': 'Near Krishna Mandir',
      'latitude': 27.6727,
      'longitude': 85.3253,
      'aliases': ['patan', 'mangal bazaar', 'durbar square', 'krishna mandir', 'jawalakhel'],
    },
    {
      'name': 'Naxal Central Hub',
      'area': 'Naxal',
      'city': 'Kathmandu',
      'displayAddress': 'Bhagwati Bahal, Naxal / Gairidhara, Kathmandu, Nepal',
      'landmark': 'Valley Express Central Chilling Hub',
      'latitude': 27.7150,
      'longitude': 85.3280,
      'aliases': ['naxal', 'gairidhara', 'bhagwati bahal', 'central hub', 'police headquarter'],
    },
    {
      'name': 'New Baneshwor',
      'area': 'Baneshwor',
      'city': 'Kathmandu',
      'displayAddress': 'Baneshwor Chowk, Kathmandu-10, Nepal',
      'landmark': 'Near International Convention Centre (ICC)',
      'latitude': 27.6915,
      'longitude': 85.3420,
      'aliases': ['baneshwor', 'new baneshwor', 'icc', 'shankhamul', 'purano baneshwor'],
    },
    {
      'name': 'Durbar Marg (Kingsway)',
      'area': 'Durbar Marg',
      'city': 'Kathmandu',
      'displayAddress': 'Kingsway Avenue, Narayanhiti, Kathmandu, Nepal',
      'landmark': 'Opposite Hotel Annapurna',
      'latitude': 27.7107,
      'longitude': 85.3172,
      'aliases': ['durbarmarg', 'durbar marg', 'kingsway', 'narayanhiti', 'annapurna'],
    },
    {
      'name': 'Lazimpat',
      'area': 'Lazimpat',
      'city': 'Kathmandu',
      'displayAddress': 'Lazimpat Road, Ward 2, Kathmandu, Nepal',
      'landmark': 'Near Hotel Shanker & Radisson',
      'latitude': 27.7220,
      'longitude': 85.3180,
      'aliases': ['lazimpat', 'radisson', 'hotel shanker', 'british embassy'],
    },
    {
      'name': 'Boudhanath Stupa',
      'area': 'Boudha',
      'city': 'Kathmandu',
      'displayAddress': 'Stupa Circle, Boudha, Kathmandu, Nepal',
      'landmark': 'Main Stupa Gate',
      'latitude': 27.7215,
      'longitude': 85.3620,
      'aliases': ['boudha', 'boudhanath', 'chabahil', 'stupa'],
    },
    {
      'name': 'Maharajgunj',
      'area': 'Maharajgunj',
      'city': 'Kathmandu',
      'displayAddress': 'Maharajgunj Chowk, Ring Road, Kathmandu, Nepal',
      'landmark': 'Near Teaching Hospital / US Embassy',
      'latitude': 27.7371,
      'longitude': 85.3323,
      'aliases': ['maharajgunj', 'teaching hospital', 'us embassy', 'panipokhari'],
    },
    {
      'name': 'Koteshwor Chowk',
      'area': 'Koteshwor',
      'city': 'Kathmandu',
      'displayAddress': 'Koteshwor Intersection, Kathmandu-32, Nepal',
      'landmark': 'Near Jadibuti / Tinkune bridge',
      'latitude': 27.6780,
      'longitude': 85.3490,
      'aliases': ['koteshwor', 'tinkune', 'jadibuti', 'sinamangal'],
    },
    {
      'name': 'Tripureshwor',
      'area': 'Tripureshwor',
      'city': 'Kathmandu',
      'displayAddress': 'Tripureshwor Chowk, Ward 11, Kathmandu, Nepal',
      'landmark': 'Near Dasharath Stadium & World Trade Centre',
      'latitude': 27.6950,
      'longitude': 85.3140,
      'aliases': ['tripureshwor', 'dasharath stadium', 'wtc', 'world trade center'],
    },
    {
      'name': 'Maitighar Mandala',
      'area': 'Maitighar',
      'city': 'Kathmandu',
      'displayAddress': 'Maitighar Mandala Circle, Kathmandu, Nepal',
      'landmark': 'Near St. Xavier\'s College',
      'latitude': 27.6920,
      'longitude': 85.3230,
      'aliases': ['maitighar', 'mandala', 'st xaviers', 'babarmahal'],
    },
    {
      'name': 'Kupondole',
      'area': 'Kupondole',
      'city': 'Lalitpur',
      'displayAddress': 'Kupondole Heights, Lalitpur, Nepal',
      'landmark': 'Near UN House & Bagmati Bridge',
      'latitude': 27.6880,
      'longitude': 85.3170,
      'aliases': ['kupondole', 'un house', 'bagmati bridge'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLon = widget.initialLon;
    _addressTitle = widget.initialAddress;
    _formattedAddress = '${widget.initialAddress}, Nepal';
    _landmarkController.text = widget.initialLandmark;
    _reverseGeocode(_currentLat, _currentLon);
    _landmarkController.addListener(_onLandmarkChanged);

    // Pre-fill the delivery contact from the signed-in account rather than a
    // fixed test number, which riders would otherwise be handed verbatim.
    final phone = context.read<AuthProvider>().user?.phone ?? '';
    if (phone.isNotEmpty) _phoneController.text = phone;
  }

  @override
  void dispose() {
    _landmarkController.removeListener(_onLandmarkChanged);
    _searchController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _googleMapsLinkController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onLandmarkChanged() {
    final text = _landmarkController.text.trim();
    if (text.contains('maps.app.goo.gl') ||
        text.contains('goo.gl/maps') ||
        text.contains('google.com/maps') ||
        RegExp(r'@?(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)').hasMatch(text)) {
      _parseAndApplyLocation(text);
      _landmarkController.clear();
    }
  }

  Future<void> _useCurrentLocation() async {
    final prefs = context.read<PreferencesProvider>();
    if (!prefs.locationSharing) {
      _showLocationMessage(
        'Location sharing is turned off in your profile. Turn it on, or search for your area below.',
      );
      return;
    }

    setState(() {
      _locateState = 'locating';
      _searchResults = [];
      _searchedTerm = '';
      _searchController.clear();
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locateState = 'error');
        _showLocationMessage('Location services are disabled on this device.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => _locateState = 'error');
        _showLocationMessage('Location permission was declined.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locateState = 'error');
        _showLocationMessage('Location is blocked in settings. Please enable it to use GPS.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;
      setState(() {
        _locateState = 'found';
        _gpsAccuracy = position.accuracy.round();
        _currentLat = position.latitude;
        _currentLon = position.longitude;
        _currentZoom = 17.0;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLat, _currentLon),
            zoom: 17.0,
          ),
        ),
      );

      _reverseGeocode(position.latitude, position.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locateState = 'error');
      _showLocationMessage('Could not get a GPS fix. Try again outdoors or search below.');
    }
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.darkNavy,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _shareLocation() async {
    final landmark = _landmarkController.text.trim();
    final text = '$_addressTitle${landmark.isNotEmpty ? ' ($landmark)' : ''}\n'
        '${_currentLat.toStringAsFixed(5)}, ${_currentLon.toStringAsFixed(5)}\n'
        'https://www.openstreetmap.org/?mlat=$_currentLat&mlon=$_currentLon'
        '#map=18/$_currentLat/$_currentLon';

    await Clipboard.setData(ClipboardData(text: text));
    _showLocationMessage('Drop-off location copied to clipboard.');
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final res = await _api.dio.get('/maps/reverse', queryParameters: {'lat': lat, 'lon': lon});
      if (res.data['success'] == true && res.data['location'] != null) {
        final loc = res.data['location'];
        if (mounted) {
          setState(() {
            _addressTitle = loc['name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
            _formattedAddress = loc['displayAddress'] ?? '${loc['area']}, Nepal';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressTitle = 'Selected Pin (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
          _formattedAddress = 'Coordinates: ${lat.toStringAsFixed(5)}° N, ${lon.toStringAsFixed(5)}° E';
        });
      }
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _executeSearch(String query) async {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchedTerm = '';
      });
      return;
    }

    // Check if query is a Google Maps link or coordinates
    if (trimmed.contains('maps') ||
        trimmed.contains('goo.gl') ||
        RegExp(r'@?(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)').hasMatch(trimmed)) {
      final handled = await _parseAndApplyLocation(trimmed);
      if (handled) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }
    }

    _searchedTerm = trimmed;
    setState(() => _isSearching = true);

    final qLower = trimmed.toLowerCase();
    final qNormalized = qLower.replaceAll('smirti', 'smriti');

    // Local instant fuzzy matching across all Kathmandu landmarks
    final localMatches = _kathmanduDatabase.where((item) {
      final name = item['name'].toString().toLowerCase();
      final area = item['area'].toString().toLowerCase();
      final addr = item['displayAddress'].toString().toLowerCase();
      final lmk = (item['landmark'] ?? '').toString().toLowerCase();
      final aliases = (item['aliases'] as List<String>?) ?? [];

      return name.contains(qLower) ||
          name.contains(qNormalized) ||
          area.contains(qLower) ||
          area.contains(qNormalized) ||
          addr.contains(qLower) ||
          addr.contains(qNormalized) ||
          lmk.contains(qLower) ||
          aliases.any((a) => a.contains(qLower) || a.contains(qNormalized) || qLower.contains(a));
    }).map((m) => Map<String, dynamic>.from(m)).toList();

    if (localMatches.isNotEmpty && mounted) {
      setState(() {
        _searchResults = localMatches;
        _isSearching = false;
      });
    }

    try {
      final res = await _api.dio.get('/maps/search', queryParameters: {'q': trimmed});
      if (res.data['success'] == true && mounted) {
        final List<dynamic> remote = res.data['results'] ?? [];
        final combined = [...localMatches];
        // Matched on id, then position — not on name. Streets and localities
        // routinely return several distinct points sharing one name, and
        // comparing names threw all but the first of them away.
        String keyOf(dynamic item) {
          final id = item['id'];
          if (id != null && id.toString().isNotEmpty) return 'id:$id';
          final lat = (item['latitude'] as num?)?.toStringAsFixed(5);
          final lon = (item['longitude'] as num?)?.toStringAsFixed(5);
          return 'at:$lat,$lon';
        }

        final seen = combined.map(keyOf).toSet();
        for (final r in remote) {
          if (seen.add(keyOf(r))) combined.add(r);
        }
        setState(() {
          _searchResults = combined;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = localMatches;
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchedTerm = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(query);
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
      if (item['landmark'] != null && item['landmark'].toString().isNotEmpty) {
        _landmarkController.text = item['landmark'];
      }
      _searchResults = [];
      _searchedTerm = '';
      _isSearching = false;
      _currentZoom = 16.0;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 16.0,
        ),
      ),
    );

    FocusScope.of(context).unfocus();
  }

  void _applyNewCoordinates(double lat, double lon, {String? customTitle}) {
    setState(() {
      _currentLat = lat;
      _currentLon = lon;
      _currentZoom = 17.0;
      if (customTitle != null && customTitle.isNotEmpty) {
        _addressTitle = customTitle;
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 17.0,
        ),
      ),
    );

    _reverseGeocode(lat, lon);
  }

  Future<void> _openInGoogleMaps() async {
    final urlString = 'https://www.google.com/maps/search/?api=1&query=$_currentLat,$_currentLon';
    final uri = Uri.parse(urlString);
    try {
      if (kIsWeb) {
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } else {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
      _showLocationMessage('Redirecting to Google Maps… Copy your location and paste it here.');
    } catch (e) {
      _showLocationMessage('Could not open Google Maps: $e');
    }
  }

  Future<bool> _parseAndApplyLocation(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      _showLocationMessage('Please enter or paste a Google Maps link or coordinates.');
      return false;
    }

    _googleMapsLinkController.text = text;

    // 1. Direct regex checks for coordinates or protobuf url
    final protoRegex = RegExp(r'!3d(-?\d{1,2}\.\d+)!4d(-?\d{1,3}\.\d+)');
    final qRegex = RegExp(r'[?&](?:q|ll)=(-?\d{1,2}\.\d+),(-?\d{1,3}\.\d+)');
    final coordRegex = RegExp(r'@?(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)');

    Match? match = protoRegex.firstMatch(text);
    match ??= qRegex.firstMatch(text);
    match ??= coordRegex.firstMatch(text);

    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lon = double.tryParse(match.group(2) ?? '');
      if (lat != null && lon != null) {
        _applyNewCoordinates(lat, lon);
        _showLocationMessage('Location updated from Google Maps (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})');
        return true;
      }
    }

    // 2. If it's a link (like maps.app.goo.gl or goo.gl/maps), resolve via backend
    if (text.toLowerCase().startsWith('http://') || text.toLowerCase().startsWith('https://')) {
      _showLocationMessage('Resolving Google Maps link…');
      try {
        final res = await _api.dio.post('/maps/resolve-url', data: {'url': text});
        if (res.data['success'] == true) {
          final lat = (res.data['latitude'] as num).toDouble();
          final lon = (res.data['longitude'] as num).toDouble();
          _applyNewCoordinates(lat, lon);
          _showLocationMessage('Google Maps location pinpointed (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})');
          return true;
        }
      } catch (err) {
        _showLocationMessage('Could not extract coordinates from this link. Try copying the coordinates directly.');
        return false;
      }
    }

    return false;
  }

  Future<void> _showPasteLocationDialog() async {
    final pasteController = TextEditingController();

    // Check clipboard automatically for quick pre-fill
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipData?.text != null && clipData!.text!.trim().isNotEmpty) {
        final clipText = clipData.text!.trim();
        if (clipText.contains('maps') ||
            clipText.contains('goo.gl') ||
            RegExp(r'(-?\d{1,2}\.\d+)[,\s]+(-?\d{1,3}\.\d+)').hasMatch(clipText)) {
          pasteController.text = clipText;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isResolving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFFDC2626), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paste Google Maps Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2A44),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Share link, maps URL, or coordinates',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: pasteController,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              decoration: const InputDecoration(
                                hintText: 'https://maps.app.goo.gl/... or 27.7280, 85.3300',
                                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                              ),
                              maxLines: 2,
                              minLines: 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_paste_go_rounded, size: 20, color: AppTheme.accent),
                            tooltip: 'Paste from clipboard',
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                setModalState(() {
                                  pasteController.text = data!.text!.trim();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Redirect to Google Maps button
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E40AF),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _openInGoogleMaps,
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text(
                              'Open Maps',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Apply button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: isResolving
                                ? null
                                : () async {
                                    setModalState(() => isResolving = true);
                                    final success = await _parseAndApplyLocation(pasteController.text);
                                    setModalState(() => isResolving = false);
                                    if (success && mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                            icon: isResolving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              isResolving ? 'Locating…' : 'Apply Location',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. High-Performance MapLibre Vector Map Engine (OpenFreeMap Liberty Style)
          Positioned.fill(
            child: MapLibreMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat, _currentLon),
                zoom: _currentZoom,
              ),
              styleString: MapLibreStyles.openfreemapLiberty,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (position) {
                _currentLat = position.target.latitude;
                _currentLon = position.target.longitude;
                _currentZoom = position.zoom;
                if (!_isDragging) {
                  setState(() => _isDragging = true);
                }
              },
              onCameraIdle: () {
                if (_isDragging) {
                  setState(() => _isDragging = false);
                }
                final target = _mapController?.cameraPosition?.target;
                if (target != null) {
                  _currentLat = target.latitude;
                  _currentLon = target.longitude;
                  _reverseGeocode(_currentLat, _currentLon);
                }
              },
              trackCameraPosition: true,
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.topRight,
              compassViewMargins: const Point(16, 120),
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              minMaxZoomPreference: const MinMaxZoomPreference(8.0, 19.0),
              attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            ),
          ),

          // 2. Modern Center Drop-Off Pin (Uber / Wolt Style with Ground Ripple & Lift)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, _isDragging ? -18 : 0, 0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2A44),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Deliver here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ground Contact Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _isDragging ? 6 : 14,
                  height: _isDragging ? 3 : 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(_isDragging ? 0.2 : 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // 3. Floating Modern Search Bar & Quick Location Chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Top Search Bar Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2A44), size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: (val) {
                            if (val.trim().length >= 2) {
                              _executeSearch(val);
                            }
                          },
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search chowk, street or area in Nepal...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1F2A44)),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _searchedTerm = '';
                              _isSearching = false;
                            });
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.search, color: Color(0xFF003893), size: 20),
                        ),
                    ],
                  ),
                ),

                // No place found card
                if (_searchResults.isEmpty && !_isSearching && _searchedTerm.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No place found for "$_searchedTerm"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2A44),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _searchedTerm = ''),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try searching a nearby chowk or landmark, use current GPS, or move the pin directly on the map.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _useCurrentLocation,
                          child: const Row(
                            children: [
                              Icon(Icons.my_location, size: 15, color: Color(0xFF003893)),
                              SizedBox(width: 6),
                              Text(
                                'Use my current location',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003893)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Live Search Dropdown Suggestions
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          dense: true,
                          onTap: _useCurrentLocation,
                          leading: const Icon(Icons.my_location, size: 18, color: Color(0xFF003893)),
                          title: Text(
                            _locateState == 'locating' ? 'Locating you…' : 'Use my current GPS location',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF003893)),
                          ),
                          subtitle: const Text(
                            'Precise delivery spot via device GPS',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, idx) {
                              final item = _searchResults[idx];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_rounded, color: AppTheme.accent, size: 20),
                                title: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F2A44)),
                                ),
                                subtitle: Text(
                                  item['displayAddress'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSearchResult(item),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Popular Hub & Google Maps Action Chips
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Google Maps Redirect Chip
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFEA4335)),
                        label: const Text(
                          'Google Maps ↗',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEA4335)),
                        ),
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: _openInGoogleMaps,
                      ),
                      const SizedBox(width: 6),
                      // Paste from Google Maps Chip
                      ActionChip(
                        avatar: const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF003893)),
                        label: const Text(
                          'Paste Maps Link',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF003893)),
                        ),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: () async {
                          final clip = await Clipboard.getData(Clipboard.kTextPlain);
                          if (clip?.text != null && clip!.text!.trim().isNotEmpty) {
                            _googleMapsLinkController.text = clip.text!.trim();
                            _parseAndApplyLocation(clip.text!.trim());
                          } else {
                            _showPasteLocationDialog();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ..._popularZones.map((zone) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.place_outlined, size: 14, color: Color(0xFF003893)),
                          label: Text(
                            zone['name'],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF003893)),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentLat = zone['lat'];
                              _currentLon = zone['lon'];
                              _addressTitle = zone['name'];
                              _formattedAddress = zone['full'] ?? '${zone['name']}, Nepal';
                              if (zone['landmark'] != null) {
                                _landmarkController.text = zone['landmark'];
                              }
                              _searchResults = [];
                              _searchedTerm = '';
                              _isSearching = false;
                              _currentZoom = 16.0;
                            });
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(zone['lat'], zone['lon']),
                                  zoom: 16.0,
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Floating Map Navigation Action Buttons (Right Side)
          Positioned(
            right: 14,
            bottom: 270,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapFloatingBtn(
                  icon: Icons.my_location,
                  tooltip: 'My Location',
                  color: _locateState == 'locating'
                      ? AppTheme.accent
                      : const Color(0xFF003893),
                  isLoading: _locateState == 'locating',
                  onTap: _useCurrentLocation,
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.share_location_rounded,
                  tooltip: 'Share Pin',
                  onTap: _shareLocation,
                ),
                const SizedBox(height: 8),
                _buildMapFloatingBtn(
                  icon: Icons.open_in_new_rounded,
                  tooltip: 'Open in Google Maps',
                  color: const Color(0xFFEA4335),
                  onTap: _openInGoogleMaps,
                ),
              ],
            ),
          ),

          // 5. Sleek Bottom Address Sheet (Uber/Pathao Style)
          Positioned(
            left: 0,
            right: 0,
            // The map must not squash, so the Scaffold does not resize for
            // the keyboard; the sheet lifts itself instead, which otherwise
            // left the address fields hidden behind it while typing.
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Drag Pill
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Location Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _addressTitle.isNotEmpty ? _addressTitle : 'Drop-off Location',
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F2A44),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      _gpsAccuracy != null
                                          ? 'GPS: ~${_gpsAccuracy}m'
                                          : '${_currentLat.toStringAsFixed(4)}°N, ${_currentLon.toStringAsFixed(4)}°E',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (_isReverseGeocoding)
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accent),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Identifying address details…', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                )
                              else
                                Text(
                                  _formattedAddress.isNotEmpty ? _formattedAddress : 'Selected coordinates on map',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Google Maps Location Section (Direct Input & Redirect)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Two Primary Action Buttons: Open in Google Maps OR Paste from Clipboard
                          Row(
                            children: [
                              // Option 1: Open / Redirect to Google Maps
                              Expanded(
                                child: InkWell(
                                  onTap: _openInGoogleMaps,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFEA4335)),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Open Google Maps ↗',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEA4335),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Option 2: Quick Paste from Clipboard
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final clip = await Clipboard.getData(Clipboard.kTextPlain);
                                    if (clip?.text != null && clip!.text!.trim().isNotEmpty) {
                                      _googleMapsLinkController.text = clip.text!.trim();
                                      _parseAndApplyLocation(clip.text!.trim());
                                    } else {
                                      _showPasteLocationDialog();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Paste Location',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1D4ED8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Direct Paste Input Field with Apply Button
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            padding: const EdgeInsets.only(left: 10, right: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 18, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _googleMapsLinkController,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                                    decoration: const InputDecoration(
                                      hintText: 'Paste Google Maps link or coordinates...',
                                      hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                    ),
                                    onSubmitted: (val) => _parseAndApplyLocation(val),
                                  ),
                                ),
                                if (_googleMapsLinkController.text.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _googleMapsLinkController.clear();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.close_rounded, size: 15, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                InkWell(
                                  onTap: () {
                                    if (_googleMapsLinkController.text.trim().isNotEmpty) {
                                      _parseAndApplyLocation(_googleMapsLinkController.text.trim());
                                    } else {
                                      _showPasteLocationDialog();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Landmark text input
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, color: Color(0xFF94A3B8), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _landmarkController,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF1F2A44)),
                              decoration: const InputDecoration(
                                hintText: 'Nearby Landmark / Gate / House No. (Optional)',
                                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Primary Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirmLocation,
                        child: Text(
                          'Confirm Delivery Address (${_addressTitle.split(',').first.trim()})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildMapFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    Color color = const Color(0xFF003893),
    bool isLoading = false,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  )
                : Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
