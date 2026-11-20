import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import 'order_tracking_screen.dart';
import 'map_address_picker_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiClient _api = ApiClient();
  final _addressController = TextEditingController(text: 'Baluwatar, Kathmandu');
  final _landmarkController = TextEditingController(text: 'Near Russian Embassy, House #42');
  final _couponController = TextEditingController(text: 'VALLEYFIRST');
  double _latitude = 27.7280;
  double _longitude = 85.3300;
  String _formattedAddress = 'Baluwatar Chowk, Kathmandu 44600, Nepal';
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
      setState(() {
        _discount = 0;
        _couponStatus = 'Invalid or expired coupon code';
      });
    }
  }

  Future<void> _handleCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (cart.hasAlcohol && !_ageConfirmed && !(auth.user?.ageConfirmed ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Legal Compliance: You must verify you are 18+ years old to order alcohol.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final itemsPayload = cart.items.values
        .map((item) => {
              'product': item.product.id,
              'quantity': item.quantity,
            })
        .toList();

    final int currentTotal = (cart.subtotal + cart.deliveryFee - _discount).clamp(0, 9999999);

    final order = await orderProv.placeOrder(
      items: itemsPayload,
      addressText: _addressController.text.trim(),
      landmark: _landmarkController.text.trim(),
      formattedAddress: _formattedAddress,
      latitude: _latitude,
      longitude: _longitude,
      offerCode: _discount > 0 ? _couponController.text.trim() : null,
      paymentMethod: _paymentMethod,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (order != null) {
      cart.clear();
      if (_paymentMethod != 'cash_on_delivery') {
        await _showOnlinePaymentDialog(order, currentTotal);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Check server connection.')),
      );
    }
  }

  Future<void> _showOnlinePaymentDialog(OrderModel order, int totalAmount) async {
    final isEsewa = _paymentMethod == 'esewa';
    final walletName = isEsewa ? 'eSewa' : 'Khalti';
    final brandColor = isEsewa ? const Color(0xFF60BB46) : const Color(0xFF5C2D91);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brandColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: brandColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$walletName Payment Gateway',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Secure e-Payment Sandbox (Nepal)',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Reference', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.brandBlue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain)),
                      Text('Rs. $totalAmount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: brandColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await _api.dio.post('/payments/verify', data: {
                    'orderId': order.id,
                    'method': _paymentMethod,
                    'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
                  });
                } catch (_) {}
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                  );
                }
              },
              child: Text(
                'Simulate & Pay with $walletName',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                );
              },
              child: const Text('Continue (Payment Pending)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final grandTotal = (cart.subtotal + cart.deliveryFee - _discount).clamp(0, 9999999);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Cart & Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
                      color: AppTheme.accent.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Basket is Empty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Explore snacks, drinks & mixers in Kathmandu', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandBlue),
                    child: const Text('Browse Catalog'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Item List Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'YOUR ITEMS (${cart.itemCount})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () => cart.clear(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w600)),
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
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${item.product.price} × ${item.quantity}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppTheme.textMuted),
                                      onPressed: () => cart.removeSingleItem(item.product.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, size: 22, color: AppTheme.accent),
                                      onPressed: () => cart.addItem(item.product),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery Address with Map Picker
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DELIVERY ADDRESS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openMapPicker,
                              child: const Text(
                                'EDIT ON MAP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: AppTheme.accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _addressController.text,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                                  ),
                                  if (_landmarkController.text.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _landmarkController.text,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'GPS: ${_latitude.toStringAsFixed(4)}N, ${_longitude.toStringAsFixed(4)}E',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textSubtle, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Coupon / Promo Code Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter Promo Code',
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
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(64, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _discount > 0 ? AppTheme.success : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],

                  // Alcohol Legal Verification Checkbox
                  if (cart.hasAlcohol) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accent),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _ageConfirmed,
                            activeColor: AppTheme.accent,
                            onChanged: (val) => setState(() => _ageConfirmed = val ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I verify I am 18+ years of age. I agree to present a valid physical ID to the rider upon delivery.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Payment Method Selector Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment_rounded, color: AppTheme.brandBlue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'PAYMENT METHOD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.brandBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          id: 'cash_on_delivery',
                          title: 'Cash on Delivery',
                          subtitle: 'Pay cash or Scan on delivery',
                          badge: 'Popular',
                          icon: Icons.money_rounded,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentOption(
                          id: 'esewa',
                          title: 'eSewa Mobile Wallet',
                          subtitle: 'Instant e-Payment Sandbox',
                          badge: 'Digital',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF60BB46),
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentOption(
                          id: 'khalti',
                          title: 'Khalti Digital Wallet',
                          subtitle: 'Khalti balance or e-Banking',
                          badge: 'Digital',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFF5C2D91),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill Breakdown Card (matching Figma)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', 'Rs. ${cart.subtotal}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Delivery Fee',
                          cart.deliveryFee == 0 ? 'FREE' : 'Rs. ${cart.deliveryFee}',
                          isAccent: cart.deliveryFee == 0,
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('Promo Discount', '- Rs. $_discount', isGreen: true),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: AppTheme.border),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textMain),
                            ),
                            Text(
                              'Rs. $grandTotal',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.accent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Place Order Button (Big Orange Button)
                  ElevatedButton(
                    onPressed: _submitting ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppTheme.background, strokeWidth: 2),
                          )
                        : Text(
                            'PLACE ORDER • Rs. $grandTotal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : AppTheme.background,
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF0F5FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTheme.textMain : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : AppTheme.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isAccent = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isGreen
                ? AppTheme.success
                : isAccent
                    ? AppTheme.accent
                    : AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
