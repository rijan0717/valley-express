import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme.dart';
import '../../widgets/valley_product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  int _selectedSizeIndex = 0;
  bool _isFavorite = false;

  final List<String> _sizeOptions = ['Single Unit', 'Pack of 6', 'Crate (12x)'];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final p = widget.product;
    final int itemPrice = p.price * (_selectedSizeIndex == 0 ? 1 : (_selectedSizeIndex == 1 ? 6 : 12));
    final int totalPrice = itemPrice * _quantity;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Navigation Bar (Circular Back Button & Favorite Heart Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.inputBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppTheme.textMain, size: 20),
                    ),
                  ),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Saved to favorites' : 'Removed from favorites'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppTheme.darkNavy,
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.inputBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? AppTheme.accent : AppTheme.textMain,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Card Container (matching Figma reference)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Center(
                        child: ValleyProductImage(
                          imageUrl: p.images.isNotEmpty
                              ? p.images[_selectedImageIndex < p.images.length ? _selectedImageIndex : 0]
                              : null,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Multi-image selector if multiple photos exist
                    if (p.images.length > 1) ...[
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: p.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isSel = idx == _selectedImageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedImageIndex = idx),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.inputBg,
                                  border: Border.all(
                                    color: isSel ? AppTheme.accent : AppTheme.border,
                                    width: isSel ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ValleyProductImage(
                                    imageUrl: p.images[idx],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Store / Hub Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, size: 14, color: AppTheme.brandBlue),
                          SizedBox(width: 4),
                          Text(
                            'Valley Express Central Hub • Kathmandu Express',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title & Nepali Translation
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        height: 1.25,
                      ),
                    ),
                    if (p.nameNe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.nameNe,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Rating, Free Delivery & Time Badges Row (matching Figma)
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                        ),
                        SizedBox(width: 14),
                        Icon(Icons.delivery_dining_outlined, size: 18, color: AppTheme.accent),
                        SizedBox(width: 4),
                        Text(
                          'Free Express',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        SizedBox(width: 14),
                        Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 4),
                        Text(
                          '20-30 min',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Alcohol ID Compliance Badge if restricted
                    if (p.isAlcohol) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Age 18+ Mandatory ID check upon delivery${p.alcoholPercentage > 0 ? " • ${p.alcoholPercentage}% ABV" : ""}',
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Packaging / Size Selector Chips (matching Figma)
                    const Text(
                      'PACKAGE OPTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_sizeOptions.length, (idx) {
                        final isSel = idx == _selectedSizeIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSizeIndex = idx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.accent : AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? AppTheme.accent : AppTheme.border,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                _sizeOptions[idx],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? AppTheme.background : AppTheme.textMain,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Highlights Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildHighlightTag(Icons.ac_unit_rounded, 'Chilled & Cold Storage'),
                        _buildHighlightTag(Icons.verified_outlined, p.unit),
                        _buildHighlightTag(Icons.payments_outlined, 'Cash / eSewa on Arrival'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description Section
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.description.isNotEmpty
                          ? p.description
                          : 'Fresh, chilled beverages and snacks swiftly delivered across Kathmandu, Lalitpur, and Bhaktapur within 30 minutes with real-time live map tracking.',
                      style: const TextStyle(color: AppTheme.textMuted, height: 1.5, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Bar: Price, Navy Stepper & Big Orange ADD TO CART button (matching Figma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  // Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      Text(
                        'Rs. $totalPrice',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Dark Navy Stepper Capsule (- 1 +)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity -= 1);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.background.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 14, color: AppTheme.background),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: AppTheme.background,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _quantity += 1),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.background.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 14, color: AppTheme.background),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Big Orange ADD TO CART button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < _quantity; i++) {
                          cart.addItem(p);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $_quantity x ${p.name} to basket'),
                            backgroundColor: AppTheme.darkNavy,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildHighlightTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMain),
          ),
        ],
      ),
    );
  }
}
