import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'map_address_picker_screen.dart';
import '../../widgets/valley_product_image.dart';
import '../../widgets/unread_badge.dart';
import '../../widgets/fly_to_cart.dart';
import '../../providers/chat_unread_provider.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  List<dynamic> _categories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  String _currentDeliveryAddress = 'Baluwatar, Kathmandu';
  double _deliveryLat = 27.7280;
  double _deliveryLon = 85.3300;
  bool _loading = true;
  int _currentNavIndex = 0;
  // Landing point for the add-to-cart flight animation
  final GlobalKey _cartTargetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      Provider.of<ChatUnreadProvider>(context, listen: false).start();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final pRes = await _api.dio.get('/products');
      final cRes = await _api.dio.get('/categories');
      if (mounted) {
        setState(() {
          _products = (pRes.data['products'] as List)
              .map((p) => ProductModel.fromJson(p))
              .toList();
          _categories = cRes.data['categories'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('beer') || lower.contains('cider')) return Icons.sports_bar_outlined;
    if (lower.contains('whisky') || lower.contains('spirit') || lower.contains('rum') || lower.contains('vodka')) {
      return Icons.liquor_outlined;
    }
    if (lower.contains('wine')) return Icons.wine_bar_outlined;
    if (lower.contains('snack') || lower.contains('food')) return Icons.lunch_dining_outlined;
    if (lower.contains('beverage') || lower.contains('soft') || lower.contains('juice')) {
      return Icons.local_drink_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final userName = auth.user?.name.isNotEmpty == true ? auth.user!.name : 'Friend';

    // Filter products by selected category and live search text
    final filtered = _products.where((p) {
      final matchesCategory = _selectedCategory.isEmpty ||
          p.categoryId == _selectedCategory ||
          p.categorySlug == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.nameNe.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: _loading
            ? const ValleyLoaderScreen(label: "Loading tonight's menu...")
            : ValleyRefresh(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Menu Button, Deliver To Dropdown, Dark Navy Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Profile / Menu Icon Button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppTheme.inputBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: AppTheme.textMain, size: 22),
                            ),
                          ),

                          // Deliver to Map selector (taps into Map Address Picker)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: InkWell(
                                onTap: () async {
                                  final SelectedLocation? res = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MapAddressPickerScreen(
                                        initialLat: _deliveryLat,
                                        initialLon: _deliveryLon,
                                        initialAddress: _currentDeliveryAddress,
                                      ),
                                    ),
                                  );
                                  if (res != null) {
                                    setState(() {
                                      _currentDeliveryAddress = res.addressText;
                                      _deliveryLat = res.latitude;
                                      _deliveryLon = res.longitude;
                                    });
                                  }
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DELIVER TO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.accent,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.accent),
                                      ],
                                    ),
                                    Text(
                                      _currentDeliveryAddress,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Dark Navy Cart Button with Orange Badge (matching Figma)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.darkNavy,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppTheme.background,
                                    size: 20,
                                  ),
                                ),
                                if (cart.itemCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                      child: Center(
                                        child: Text(
                                          '${cart.itemCount}',
                                          style: const TextStyle(
                                            color: AppTheme.background,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Greeting Text: "Hey [Name], Good Afternoon!"
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hey $userName, ',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            TextSpan(
                              text: _timeGreeting,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search & Filter Bar (matching Figma input container)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search drinks, snacks, dishes...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : const Icon(Icons.tune_rounded, color: AppTheme.textMuted, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "All Categories" Header & Horizontal Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategory = ''),
                            child: const Text(
                              'See All >',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Categories List
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "All" chip
                            _buildCategoryChip(
                              name: 'All',
                              icon: Icons.grid_view_rounded,
                              isSelected: _selectedCategory.isEmpty,
                              onTap: () => setState(() => _selectedCategory = ''),
                            ),
                            const SizedBox(width: 10),
                            ..._categories.map((c) {
                              final catId = c['_id'] ?? c['slug'] ?? '';
                              final name = c['name'] ?? '';
                              final isSel = _selectedCategory == catId || _selectedCategory == c['slug'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _buildCategoryChip(
                                  name: name,
                                  icon: _getCategoryIcon(name),
                                  isSelected: isSel,
                                  onTap: () => setState(() => _selectedCategory = catId),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Promotional "Hurry Offers!" Card (matching Figma)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded,
                                            size: 11, color: AppTheme.accent),
                                        SizedBox(width: 3),
                                        Text(
                                          'KATHMANDU 30-MIN EXPRESS',
                                          style: TextStyle(
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hurry Offers!\nGet 15% Discount',
                                    style: TextStyle(
                                      color: AppTheme.background,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Use promo code VALLEYFIRST at checkout',
                                    style: TextStyle(
                                      color: Color(0xFFFFECE0),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_offer_rounded,
                                color: AppTheme.accent,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // "Popular Kathmandu Catalog" 2-Column Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Beverages & Snacks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                          Text(
                            '${filtered.length} Items',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      filtered.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSubtle),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No products match "$_searchQuery"'
                                        : 'No products in this category.',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, idx) {
                                final p = filtered[idx];
                                return _buildProductCard(p, cart);
                              },
                            ),
                      const SizedBox(height: 80), // Padding for bottom nav/floating bar
                    ],
                  ),
                ),
              ),
      ),

      // Direct Customer Support Chat FAB
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chat with Admin',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Consumer<ChatUnreadProvider>(
              builder: (_, unread, __) => unread.total == 0
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: UnreadBadge(
                        count: unread.total,
                        background: Colors.white,
                        foreground: AppTheme.accent,
                      ),
                    ),
            ),
          ],
        ),
        onPressed: () {
          final orderProv = Provider.of<OrderProvider>(context, listen: false);
          OrderModel? activeOrder;
          for (final o in orderProv.orders) {
            if (o.status != 'delivered' && o.status != 'cancelled') {
              activeOrder = o;
              break;
            }
          }
          if (activeOrder == null && orderProv.orders.isNotEmpty) {
            activeOrder = orderProv.orders.first;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                orderId: activeOrder?.id,
                orderNo: activeOrder?.orderNo,
              ),
            ),
          );
        },
      ),

      // Bottom Navigation Bar & Floating Basket Bar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Cart Basket Bar
          if (cart.items.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.accent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${cart.itemCount} item(s) in basket',
                            style: const TextStyle(color: AppTheme.background, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Subtotal: Rs. ${cart.subtotal}',
                            style: const TextStyle(color: Color(0xFFFFECE0), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'View Basket >',
                      style: TextStyle(
                        color: AppTheme.background,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Bar Navigation
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentNavIndex == 0,
                  onTap: () => setState(() => _currentNavIndex = 0),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  badgeCount: orderProv.orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').length,
                  isSelected: _currentNavIndex == 1,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                  },
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  iconKey: _cartTargetKey,
                  badgeCount: cart.itemCount,
                  isSelected: _currentNavIndex == 2,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: _currentNavIndex == 3,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.background : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.background : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel p, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Container with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: AppTheme.inputBg,
                    child: ValleyProductImage(
                      imageUrl: p.images.isNotEmpty ? p.images.first : null,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (p.isAlcohol)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '18+ Alcohol',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.textMain,
                    ),
                  ),
                  if (p.nameNe.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.nameNe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    p.unit,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSubtle),
                  ),
                ],
              ),
            ),

            // Bottom Row: Price & Circular Orange '+' Add Button (matching Figma)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${p.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textMain,
                  ),
                ),
                Builder(
                  builder: (buttonContext) => GestureDetector(
                  onTap: () {
                    // Fly before adding, so the marker starts from the button
                    // while it is still on screen
                    FlyToCart.runFromContext(
                      sourceContext: buttonContext,
                      targetKey: _cartTargetKey,
                    );
                    cart.addItem(p);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${p.name} added to basket'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppTheme.darkNavy,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.background,
                      size: 20,
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
    Key? iconKey,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            key: iconKey,
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppTheme.accent : AppTheme.textMuted,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: AppTheme.background,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
