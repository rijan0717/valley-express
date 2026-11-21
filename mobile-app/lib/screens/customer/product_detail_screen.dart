import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme.dart';
import '../../widgets/valley_product_image.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedPackIndex = 0;
  bool _isFavorite = false;

  final List<Map<String, dynamic>> _packSizes = [
    {
      'name': 'Single Unit',
      'sub': 'Standard individual pack',
      'multiplier': 1,
      'discount': 0,
    },
    {
      'name': 'Party Pack of 4',
      'sub': '4 units chilled (Save 8%)',
      'multiplier': 4,
      'discount': 0.08,
    },
    {
      'name': 'Full Crate of 12',
      'sub': '12 units party pack (Save 12%)',
      'multiplier': 12,
      'discount': 0.12,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final p = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pack = _packSizes[_selectedPackIndex];
    final int mult = pack['multiplier'] as int;
    final double discount = pack['discount'] as double;
    final int basePackPrice = (p.price * mult * (1.0 - discount)).round();
    final int totalCheckoutPrice = basePackPrice * _quantity;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      body: SafeArea(
        child: Column(
          children: [
            // TOP APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'Product Details',
                    style: AppTheme.displayFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _isFavorite = !_isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFavorite ? '${p.name} added to favorites' : 'Removed from favorites',
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppTheme.navyBrand,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                            ),
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorite ? AppTheme.primaryOrange : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SCROLLABLE DETAILS
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HERO IMAGE SHOWCASE CARD
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ValleyProductImage(
                            imageUrl: p.images.isNotEmpty ? p.images.first : null,
                            height: 210,
                            fit: BoxFit.contain,
                          ),
                          if (p.isAlcohol)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '18+ ID Required',
                                  style: AppTheme.displayFont(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEPPER CAPSULE: [ - ] 01 [ + ]
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _quantity.toString().padLeft(2, '0'),
                                style: AppTheme.displayFont(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _quantity++),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PRODUCT TITLE & DISPATCH PROMISE
                    Text(
                      p.name,
                      style: AppTheme.displayFont(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (p.nameNe.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        p.nameNe,
                        style: AppTheme.bodyFont(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Available on 20-min late night dispatch in Kathmandu',
                            style: AppTheme.bodyFont(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // PRICE, STRIKE & REVIEWS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Rs. $basePackPrice',
                              style: AppTheme.displayFont(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rs. ${(basePackPrice * 1.12).round()}',
                              style: AppTheme.bodyFont(
                                fontSize: 13,
                                color: Colors.grey,
                              ).copyWith(decoration: TextDecoration.lineThrough),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '10% OFF',
                                style: AppTheme.displayFont(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: AppTheme.warningYellow),
                            const SizedBox(width: 4),
                            Text(
                              '4.8 (280+ Reviews)',
                              style: AppTheme.displayFont(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // CHOOSE PACK SIZE
                    Text(
                      'CHOOSE PACK SIZE',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Column(
                      children: List.generate(_packSizes.length, (idx) {
                        final item = _packSizes[idx];
                        final isSel = idx == _selectedPackIndex;
                        final mult = item['multiplier'] as int;
                        final disc = item['discount'] as double;
                        final packPrice = (p.price * mult * (1.0 - disc)).round();

                        return GestureDetector(
                          onTap: () => setState(() => _selectedPackIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? AppTheme.primaryOrange : (isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
                                width: isSel ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                      color: isSel ? AppTheme.primaryOrange : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: AppTheme.displayFont(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          item['sub'],
                                          style: AppTheme.bodyFont(
                                            fontSize: 11,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rs. $packPrice',
                                  style: AppTheme.displayFont(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // INSULATED LATE NIGHT GUARANTEE PROMISE CARD
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131824) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.chilledIce.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.chilledIce, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTheme.bodyFont(
                                  fontSize: 11,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Valley Express Delivery Promise: ',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.chilledIce),
                                  ),
                                  TextSpan(
                                    text: 'Sealed in insulated bags with ice packs. Delivered cold to your door in 20-30 mins.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FREQUENTLY PAIRED TOGETHER SECTION
                    Text(
                      'FREQUENTLY PAIRED TOGETHER',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPairingPill(
                            title: 'Crispy Wings',
                            price: 390,
                            icon: Icons.lunch_dining_rounded,
                            isDark: isDark,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Crispy Fried Wings added to basket'),
                                  backgroundColor: AppTheme.navyBrand,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPairingPill(
                            title: '2kg Tube Ice',
                            price: 120,
                            icon: Icons.ac_unit_rounded,
                            isDark: isDark,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pure Tube Ice Bag (2kg) added to basket'),
                                  backgroundColor: AppTheme.navyBrand,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildPairingPill(
                            title: 'Buff C-Momo',
                            price: 260,
                            icon: Icons.restaurant_rounded,
                            isDark: isDark,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Spicy Buff C-Momo added to basket'),
                                  backgroundColor: AppTheme.navyBrand,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PRODUCT STORY & COMPLIANCE
                    Text(
                      'PRODUCT STORY & COMPLIANCE',
                      style: AppTheme.displayFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.description.isNotEmpty
                          ? p.description
                          : 'Carefully stored in climate-controlled hubs in Kathmandu for maximum freshness. Perfect companion for late-night gatherings and party essentials.',
                      style: AppTheme.bodyFont(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (p.isAlcohol) ...[
                      Text(
                        'Alcohol Volume: ${p.alcoholPercentage > 0 ? "${p.alcoholPercentage}% ABV" : "Standard ABV"} • Mandatory 18+ ID Check on Delivery.',
                        style: AppTheme.bodyFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // STICKY BOTTOM CAPSULE: ADD TO BASKET
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  for (int i = 0; i < _quantity * mult; i++) {
                    cart.addItem(p);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${_quantity * mult}x ${p.name} to basket!'),
                      backgroundColor: AppTheme.primaryOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF11141D) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add To Basket',
                            style: AppTheme.displayFont(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$_quantity x ${pack['name']}',
                            style: AppTheme.bodyFont(color: const Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Rs. $totalCheckoutPrice',
                            style: AppTheme.displayFont(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairingPill({
    required String title,
    required int price,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTheme.displayFont(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '+ Rs. $price',
              style: AppTheme.displayFont(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
