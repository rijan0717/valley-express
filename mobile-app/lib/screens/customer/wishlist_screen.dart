import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_product_image.dart';
import '../../widgets/valley_snackbar.dart';

/// The products a customer saved, with a straight path back into the cart.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.dio.get('/wishlist');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() {
          _products = res.data['products'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ValleySnack.error(context, friendlyApiError(e, 'Could not load your saved drinks.'));
    }
  }

  Future<void> _remove(String id, String name) async {
    // Drop it from the list first so the tap feels immediate, and put it back
    // if the server disagrees.
    final index = _products.indexWhere((p) => p['_id'] == id);
    if (index < 0) return;
    final removed = _products[index];
    setState(() => _products.removeAt(index));

    try {
      await _api.dio.delete('/wishlist/$id');
      if (!mounted) return;
      ValleySnack.show(context, '$name removed from your list');
    } catch (e) {
      if (!mounted) return;
      setState(() => _products.insert(index, removed));
      ValleySnack.error(context, friendlyApiError(e, 'Could not remove that item.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: const Text('Saved Drinks'),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: 'Loading your saved drinks...')
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.primaryOrange,
              child: _products.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      children: [_buildEmpty(isDark)],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _buildRow(_products[i], isDark),
                    ),
            ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 42,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          const SizedBox(height: 14),
          Text(
            'Nothing saved yet',
            style: AppTheme.displayFont(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the heart on any drink to keep it here for next time.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic product, bool isDark) {
    final id = (product['_id'] ?? '').toString();
    final name = (product['name'] ?? 'Product').toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final images = product['images'];
    final imageUrl = (images is List && images.isNotEmpty) ? images.first.toString() : null;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final inStock = stock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 62,
              height: 62,
              child: ValleyProductImage(imageUrl: imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.displayFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: AppTheme.displayFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                if (!inStock) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Out of stock',
                    style: AppTheme.bodyFont(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Remove',
                onPressed: () => _remove(id, name),
                icon: const Icon(Icons.favorite_rounded,
                    size: 19, color: AppTheme.primaryOrange),
              ),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: inStock ? () => _addToCart(product, name) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: AppTheme.displayFont(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToCart(dynamic product, String name) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(ProductModel.fromJson(Map<String, dynamic>.from(product)));
    ValleySnack.success(context, '$name added to your basket');
  }
}
