import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'order_tracking_screen.dart';
import 'map_address_picker_screen.dart';
import '../auth/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiClient _api = ApiClient();
  final _addressController = TextEditingController(text: 'Smriti Marg, Thapathali');
  final _landmarkController = TextEditingController(text: 'House #42, Near Russian Embassy gate');
  final _couponController = TextEditingController(text: 'VALLEYFIRST');
  double _latitude = 27.7280;
  double _longitude = 85.3300;
  String _formattedAddress = 'Smriti Marg, Thapathali, Kathmandu-11, Bagamati Province, 44617, Nepal';
  bool _ageConfirmed = false;
  bool _submitting = false;
  int _discount = 0;
  String _couponStatus = '';
  String _paymentMethod = 'cash_on_delivery';

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final SelectedLocation? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapAddressPickerScreen(
          initialLat: _latitude,
          initialLon: _longitude,
          initialAddress: _addressController.text,
          initialLandmark: _landmarkController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result.addressText;
        _landmarkController.text = result.landmark;
        _formattedAddress = result.formattedAddress;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _validateCoupon(int subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    try {
      final res = await _api.dio.post('/offers/validate', data: {
        'code': code,
        'orderAmount': subtotal,
      });
      if (res.data['success'] == true) {
        setState(() {
          _discount = (res.data['offer']['discountAmount'] as num).toInt();
          _couponStatus = 'Discount of Rs. $_discount applied!';
        });
      }
    } catch (e) {
      // Offline fallback: VALLEYFIRST gives 15% discount
      if (code.toUpperCase() == 'VALLEYFIRST') {
        setState(() {
          _discount = (subtotal * 0.15).round();
          _couponStatus = 'VALLEYFIRST 15% discount applied (-Rs. $_discount)!';
        });
      } else {
        setState(() {
          _discount = 0;
          _couponStatus = 'Invalid or expired coupon code';
        });
      }
    }
  }

  void _promptLocationConfirmModal() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final grandTotal = (cart.subtotal + cart.deliveryFee - _discount).clamp(0, 9999999);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to place an order.'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (cart.hasAlcohol && !_ageConfirmed && !(auth.user?.ageConfirmed ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legal Compliance: You must verify you are 18+ years old to order alcohol.'),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
      return;
    }

    // Modal matching redesign prototype lines 4515-4528
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on_rounded, color: AppTheme.primaryOrange, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Delivery Location',
                        style: AppTheme.displayFont(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Kathmandu Night Express • Avg 24 mins',
                        style: AppTheme.bodyFont(fontSize: 11, color: AppTheme.successGreen, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _addressController.text,
                    style: AppTheme.displayFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formattedAddress,
                    style: AppTheme.bodyFont(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  if (_landmarkController.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 14, color: AppTheme.primaryOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Landmark: ${_landmarkController.text}',
                            style: AppTheme.bodyFont(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleCheckout();
              },
              child: Text(
                'Confirm Location & Place Order (Rs. $grandTotal)',
                style: AppTheme.displayFont(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openMapPicker();
              },
              child: Text(
                'Change Pin on Map',
                style: AppTheme.bodyFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _submitting = true);

    final itemsPayload = cart.items.values
        .map((item) => {
              'product': item.product.id,
              'quantity': item.quantity,
            })
        .toList();

    final bool isAgeVerified = _ageConfirmed || (auth.user?.ageConfirmed ?? false);

    final order = await orderProv.placeOrder(
      items: itemsPayload,
      addressText: _addressController.text.trim(),
      landmark: _landmarkController.text.trim(),
      formattedAddress: _formattedAddress,
      latitude: _latitude,
      longitude: _longitude,
      contactPhone: auth.user?.phone,
      offerCode: _discount > 0 ? _couponController.text.trim() : null,
      paymentMethod: _paymentMethod,
      ageConfirmed: isAgeVerified,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (order != null) {
      cart.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
      );
    } else {
      final msg = orderProv.errorMessage ?? 'Failed to place order. Check network connection.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryOrange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grandTotal = (cart.subtotal + cart.deliveryFee - _discount).clamp(0, 9999999);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          'Cart & Checkout',
          style: AppTheme.displayFont(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.primaryOrange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Basket is Empty',
                    style: AppTheme.displayFont(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Explore cold beers, snacks, mixers & ice bags in Kathmandu',
                    style: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Browse Menu',
                      style: AppTheme.displayFont(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. YOUR ITEMS CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'YOUR ITEMS (${cart.itemCount})',
                              style: AppTheme.displayFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => cart.clear(),
                              child: Text(
                                'Clear All',
                                style: AppTheme.bodyFont(
                                  fontSize: 11,
                                  color: AppTheme.alertRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        ...cart.items.values.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: AppTheme.displayFont(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${item.product.price} × ${item.quantity}',
                                        style: AppTheme.displayFont(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // STEPPER PILL: [ - ] QTY [ + ]
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => cart.removeSingleItem(item.product.id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(Icons.remove, size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '${item.quantity}',
                                          style: AppTheme.displayFont(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => cart.addItem(item.product),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(Icons.add, size: 16, color: AppTheme.primaryOrange),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. DELIVERY ADDRESS CARD (MATCHING REDESIGN SCREEN 4)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DELIVERY ADDRESS',
                              style: AppTheme.displayFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openMapPicker,
                              child: Text(
                                'EDIT ON MAP',
                                style: AppTheme.displayFont(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _openMapPicker,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.location_on_rounded, color: AppTheme.primaryOrange, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _addressController.text,
                                      style: AppTheme.displayFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _landmarkController.text.isNotEmpty
                                          ? _landmarkController.text
                                          : _formattedAddress,
                                      style: AppTheme.bodyFont(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. PROMO CODE INPUT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppTheme.primaryOrange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTheme.displayFont(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter Coupon (VALLEYFIRST)',
                              hintStyle: AppTheme.bodyFont(fontSize: 12, color: Colors.grey),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _validateCoupon(cart.subtotal),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            minimumSize: const Size(64, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Apply', style: AppTheme.displayFont(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  if (_couponStatus.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _couponStatus,
                        style: AppTheme.bodyFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _discount > 0 ? AppTheme.successGreen : AppTheme.alertRed,
                        ),
                      ),
                    ),
                  ],

                  // 4. ALCOHOL 18+ CHECKBOX
                  if (cart.hasAlcohol) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _ageConfirmed,
                            activeColor: AppTheme.primaryOrange,
                            onChanged: (val) => setState(() => _ageConfirmed = val ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'I verify I am 18+ years of age. I agree to present a valid physical ID to the rider upon delivery.',
                              style: AppTheme.bodyFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 5. PAYMENT METHOD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYMENT METHOD',
                          style: AppTheme.displayFont(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentTile(
                          id: 'cash_on_delivery',
                          title: 'Cash on Delivery (or Fonepay QR)',
                          badge: 'Preferred',
                          icon: Icons.payments_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentTile(
                          id: 'esewa',
                          title: 'eSewa Mobile Wallet',
                          badge: 'Digital',
                          icon: Icons.account_balance_wallet_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentTile(
                          id: 'khalti',
                          title: 'Khalti Digital Wallet',
                          badge: 'Digital',
                          icon: Icons.account_balance_wallet_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. BILL BREAKDOWN
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildBillRow('Subtotal', 'Rs. ${cart.subtotal}', isDark: isDark),
                        const SizedBox(height: 8),
                        _buildBillRow(
                          'Night Delivery Fee',
                          cart.deliveryFee == 0 ? 'FREE' : 'Rs. ${cart.deliveryFee}',
                          isAccent: cart.deliveryFee == 0,
                          isDark: isDark,
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildBillRow('Promo Discount', '- Rs. $_discount', isGreen: true, isDark: isDark),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: AppTheme.displayFont(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Rs. $grandTotal',
                              style: AppTheme.displayFont(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 7. PLACE ORDER BUTTON
                  ElevatedButton(
                    onPressed: _submitting ? null : _promptLocationConfirmModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppTheme.primaryOrange.withOpacity(0.35),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'PLACE ORDER • Rs. $grandTotal',
                            style: AppTheme.displayFont(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentTile({
    required String id,
    required String title,
    required String badge,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withOpacity(0.08)
              : (isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : (isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryOrange : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.displayFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryOrange : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: AppTheme.displayFont(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    bool isAccent = false,
    bool isGreen = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyFont(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.displayFont(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isGreen
                ? AppTheme.successGreen
                : (isAccent
                    ? AppTheme.primaryOrange
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
          ),
        ),
      ],
    );
  }
}
