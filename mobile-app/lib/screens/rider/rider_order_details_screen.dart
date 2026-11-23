import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../customer/chat_screen.dart';

class RiderOrderDetailsScreen extends StatefulWidget {
  final dynamic order;
  final bool isAvailable;
  final Future<void> Function(String orderId, String newStatus)? onStatusChanged;
  final Future<void> Function(String orderId, String orderNo)? onClaimOrder;

  const RiderOrderDetailsScreen({
    super.key,
    required this.order,
    this.isAvailable = false,
    this.onStatusChanged,
    this.onClaimOrder,
  });

  @override
  State<RiderOrderDetailsScreen> createState() => _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  bool _actionLoading = false;
  late dynamic _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  String get _orderId => _currentOrder['_id']?.toString() ?? '';
  String get _orderNo => _currentOrder['orderNo'] ?? 'VX-Order';
  String get _status => _currentOrder['status'] ?? 'placed';
  num get _total => (_currentOrder['total'] ?? 0) as num;
  num get _deliveryFee => (_currentOrder['deliveryFee'] ?? _currentOrder['deliveryCharge'] ?? 50) as num;
  num get _itemsSubtotal => (_total - _deliveryFee).clamp(0, _total);
  String get _paymentMethod => _currentOrder['paymentMethod'] ?? 'cash_on_delivery';
  bool get _isCOD => _paymentMethod == 'cash_on_delivery';

  String get _customerName =>
      _currentOrder['customer']?['name'] ?? _currentOrder['customerName'] ?? 'Customer';
  String get _customerPhone =>
      _currentOrder['deliveryAddress']?['contactPhone'] ??
      _currentOrder['customer']?['phone'] ??
      _currentOrder['customerPhone'] ??
      '';

  String get _addressText =>
      _currentOrder['deliveryAddress']?['addressText'] ??
      _currentOrder['address']?['addressText'] ??
      'Kathmandu Valley';
  String get _landmark =>
      _currentOrder['deliveryAddress']?['landmark'] ??
      _currentOrder['address']?['landmark'] ??
      '';

  double get _lat {
    final coords = _currentOrder['deliveryAddress']?['location']?['coordinates'] ??
        _currentOrder['address']?['location']?['coordinates'];
    if (coords is List && coords.length >= 2) {
      return (coords[1] as num).toDouble();
    }
    return ((_currentOrder['deliveryAddress']?['latitude'] ??
        _currentOrder['address']?['latitude'] ??
        27.7172) as num).toDouble();
  }

  double get _lon {
    final coords = _currentOrder['deliveryAddress']?['location']?['coordinates'] ??
        _currentOrder['address']?['location']?['coordinates'];
    if (coords is List && coords.length >= 2) {
      return (coords[0] as num).toDouble();
    }
    return ((_currentOrder['deliveryAddress']?['longitude'] ??
        _currentOrder['address']?['longitude'] ??
        85.3240) as num).toDouble();
  }

  String _formatTimeAgo(dynamic raw) {
    if (raw == null) return '';
    DateTime dt;
    if (raw is DateTime) {
      dt = raw;
    } else {
      dt = DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) {
      final rem = diff.inMinutes % 60;
      if (rem == 0) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
      return '${diff.inHours} hr ${rem}m ago';
    }
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  String _calculateEta(double lat, double lon) {
    const hubLat = 27.7172;
    const hubLon = 85.3240;
    final dLat = (lat - hubLat).abs();
    final dLon = (lon - hubLon).abs();
    final distKm = ((dLat + dLon) * 111).clamp(0.8, 18.0);
    final mins = (distKm * 4.2 + 3).round();
    return '~$mins mins (${distKm.toStringAsFixed(1)} km away)';
  }

  Future<void> _launchGoogleMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lon');
    try {
      if (kIsWeb) {
        await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
      } else {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Google Maps navigation to $_addressText')),
        );
      }
    }
  }

  Future<void> _callCustomer() async {
    if (_customerPhone.isEmpty) return;
    final cleanPhone = _customerPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer phone ($cleanPhone) copied to clipboard'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer phone ($cleanPhone) copied to clipboard'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (widget.isAvailable) {
      if (widget.onClaimOrder != null) {
        setState(() => _actionLoading = true);
        await widget.onClaimOrder!(_orderId, _orderNo);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    final isPicked = _status == 'on_the_way' || _status == 'picked_up';
    if (!isPicked) {
      // Transition from assigned -> on_the_way
      setState(() => _actionLoading = true);
      if (widget.onStatusChanged != null) {
        await widget.onStatusChanged!(_orderId, 'on_the_way');
        if (mounted) {
          setState(() {
            _actionLoading = false;
            _currentOrder['status'] = 'on_the_way';
          });
        }
      }
    } else {
      // Confirm Delivery with Modal
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm Handover & Delivery',
            style: AppTheme.displayFont(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you have safely delivered Order #$_orderNo to $_customerName?',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isCOD ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isCOD ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCOD ? Icons.payments_rounded : Icons.check_circle_rounded,
                      color: _isCOD ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isCOD
                            ? 'Collect Cash from Customer: Rs. ${_total.toStringAsFixed(0)}'
                            : 'Order is Prepaid Online. No cash collection required.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _isCOD ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm Delivered', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

      if (confirmed == true && widget.onStatusChanged != null) {
        setState(() => _actionLoading = true);
        await widget.onStatusChanged!(_orderId, 'delivered');
        if (mounted) {
          setState(() {
            _actionLoading = false;
            _currentOrder['status'] = 'delivered';
          });
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDelivered = _status == 'delivered';
    final isEnRoute = _status == 'on_the_way' || _status == 'picked_up';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBgApp : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : AppTheme.navyBrand,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Order #$_orderNo',
                  style: AppTheme.displayFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.navyBrand,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isAvailable
                        ? const Color(0xFF003893)
                        : (isDelivered
                            ? AppTheme.successGreen
                            : (isEnRoute ? const Color(0xFF10B981) : AppTheme.primaryOrange)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.isAvailable
                        ? 'OPEN REQUEST'
                        : (isDelivered
                            ? 'DELIVERED'
                            : (isEnRoute ? 'ON THE WAY' : 'ASSIGNED TO YOU')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Placed ${_formatTimeAgo(_currentOrder['createdAt'])}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Visual Status Tracker / Stepper
            _buildStatusTracker(isDark),
            const SizedBox(height: 16),

            // 2. Customer & Communication Card
            _buildCustomerCard(isDark),
            const SizedBox(height: 16),

            // 3. Pickup & Drop-Off Route Card
            _buildRouteCard(isDark),
            const SizedBox(height: 16),

            // 4. Ordered Items & Financial Summary
            _buildItemsAndPricingCard(isDark),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: isDelivered
              ? Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Delivered Successfully • Cash Reconciled',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isAvailable
                          ? const Color(0xFF003893)
                          : (isEnRoute ? AppTheme.successGreen : AppTheme.primaryOrange),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _actionLoading ? null : _handlePrimaryAction,
                    child: _actionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isAvailable
                                    ? Icons.bolt_rounded
                                    : (isEnRoute ? Icons.done_all_rounded : Icons.two_wheeler_rounded),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isAvailable
                                    ? 'Accept & Claim Order Assignment'
                                    : (isEnRoute
                                        ? 'Hand Over & Confirm Delivered (Rs. ${_total.toStringAsFixed(0)})'
                                        : 'Picked from Hub & Start Delivery'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                  ),
                ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 1. VISUAL STATUS TRACKER STEPPER
  // ----------------------------------------------------
  Widget _buildStatusTracker(bool isDark) {
    int currentStep = 1;
    if (_status == 'preparing' || _status == 'rider_assigned') {
      currentStep = 2;
    } else if (_status == 'picked_up') {
      currentStep = 3;
    } else if (_status == 'on_the_way') {
      currentStep = 4;
    } else if (_status == 'delivered') {
      currentStep = 5;
    }

    final steps = [
      {'title': 'Order Placed', 'subtitle': 'Order received in system'},
      {'title': 'Kitchen & Assign', 'subtitle': 'Assigned to Kathmandu Fleet'},
      {'title': 'Picked Up', 'subtitle': 'Collected from Valley Hub'},
      {'title': 'Out for Delivery', 'subtitle': 'Rider en route to customer'},
      {'title': 'Delivered', 'subtitle': 'Doorstep handover & payment'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Delivery Status',
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.navyBrand,
                ),
              ),
              Text(
                'Step $currentStep of 5',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper Items
          Column(
            children: List.generate(steps.length, (i) {
              final stepIndex = i + 1;
              final isPassed = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;
              final isLast = i == steps.length - 1;

              Color dotColor;
              if (isPassed) {
                dotColor = AppTheme.successGreen;
              } else if (isCurrent) {
                dotColor = AppTheme.primaryOrange;
              } else {
                dotColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isPassed
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : Text(
                                  '$stepIndex',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 26,
                          color: isPassed
                              ? AppTheme.successGreen
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i]['title']!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent
                                  ? (isDark ? Colors.white : AppTheme.navyBrand)
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                          Text(
                            steps[i]['subtitle']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 2. CUSTOMER & COMMUNICATION CARD
  // ----------------------------------------------------
  Widget _buildCustomerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Details',
            style: AppTheme.displayFont(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.navyBrand,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF003893),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _customerName.isNotEmpty ? _customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _customerPhone.isNotEmpty ? _customerPhone : 'No direct phone listed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Call and Chat Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _customerPhone.isNotEmpty ? _callCustomer : null,
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                    side: const BorderSide(color: AppTheme.primaryOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          orderId: _orderId,
                          orderNo: _orderNo,
                          channel: ChatChannel.delivery,
                          title: _customerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 3. PICKUP & DROP-OFF ROUTE CARD
  // ----------------------------------------------------
  Widget _buildRouteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup & Navigation Route',
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.navyBrand,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  _calculateEta(_lat, _lon),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pickup Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP HUB',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryOrange),
                    ),
                    Text(
                      'Valley Central Hub',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Naxal / Gairidhara Base, Kathmandu',
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Drop-off Point
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: AppTheme.successGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP-OFF LOCATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.successGreen),
                    ),
                    Text(
                      _addressText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    if (_landmark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Landmark: Near $_landmark',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      'GPS: ${_lat.toStringAsFixed(4)}°N, ${_lon.toStringAsFixed(4)}°E',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Google Maps Navigation CTA
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003893),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _launchGoogleMaps,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('Start Turn-by-Turn GPS Navigation', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 4. ORDERED ITEMS & FINANCIAL SUMMARY
  // ----------------------------------------------------
  Widget _buildItemsAndPricingCard(bool isDark) {
    final items = _currentOrder['items'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items (${items.length})',
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.navyBrand,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isCOD ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isCOD ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  _isCOD ? 'Cash on Delivery' : 'Prepaid Online',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _isCOD ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items listing
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Order items detailed list from store',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey),
              ),
            )
          else
            Column(
              children: items.map((it) {
                final name = it['name'] ?? 'Product';
                final qty = it['quantity'] ?? 1;
                final price = (it['price'] ?? 0) as num;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${qty}x  $name',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rs. ${(price * qty).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Financial Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items Subtotal',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              Text(
                'Rs. ${_itemsSubtotal.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.lightTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Charge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003893)),
              ),
              Text(
                'Rs. ${_deliveryFee.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF003893)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total (${_isCOD ? "COD Collect" : "Paid"})',
                style: AppTheme.displayFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                'Rs. ${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
