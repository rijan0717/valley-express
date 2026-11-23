import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_snackbar.dart';
import '../../widgets/avatar_upload_sheet.dart';
import '../../widgets/valley_loader.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'chat_screen.dart';
import 'chat_inbox_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'map_address_picker_screen.dart';
import 'order_tracking_screen.dart';
import 'notification_screen.dart';
import '../../widgets/valley_product_image.dart';
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
  final PageController _offersPageController = PageController();

  List<ProductModel> _products = [];
  List<dynamic> _categories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  String _currentDeliveryAddress = 'Baluwatar, Kathmandu';
  double _deliveryLat = 27.7280;
  double _deliveryLon = 85.3300;
  bool _loading = true;
  int _currentNavIndex = 0;
  int _currentOfferSlide = 0;
  DateTime? _lastBackPressTime;
  int _unreadNotifCount = 0;

  Future<void> _fetchUnreadNotifCount() async {
    try {
      final res = await _api.dio.get('/notifications/unread-count');
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _unreadNotifCount = (res.data['count'] ?? 0) as int;
          });
        }
      }
    } catch (_) {}
  }

  final GlobalKey _cartTargetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchUnreadNotifCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final unread = Provider.of<ChatUnreadProvider>(context, listen: false);
      unread.start(auth.user?.id);
      unread.addListener(_handleChatNotice);
    });
  }

  /// Day of the week for the status pill, nudging towards the offers rather
  /// than assuming every visit is a late-night one.
  String get _dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // DateTime.weekday is 1..7 starting at Monday.
    return days[DateTime.now().weekday - 1];
  }

  void _handleChatNotice() {
    if (!mounted) return;
    final unread = Provider.of<ChatUnreadProvider>(context, listen: false);
    final notice = unread.lastMessageNotice;
    if (notice != null && notice.isNotEmpty) {
      unread.clearNotice();
      ValleySnack.show(
        context,
        notice,
        icon: Icons.mark_chat_unread_rounded,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: AppTheme.primaryOrange,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<ChatUnreadProvider>(context, listen: false).removeListener(_handleChatNotice);
    } catch (_) {}
    _searchController.dispose();
    _offersPageController.dispose();
    super.dispose();
  }

  static final List<ProductModel> _curatedCatalog = [
    // Beers & Ciders
    ProductModel(
      id: 'beer-1',
      name: 'Gorkha Premium Lager Beer 650ml',
      nameNe: 'गोर्खा प्रिमियम बियर',
      price: 380,
      unit: '650ml Bottle • 5.0% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Authentically brewed in Nepal using finest malted barley, European hops and Himalayan spring water.',
      isAlcohol: true,
      alcoholPercentage: 5.0,
      images: ['https://images.unsplash.com/photo-1608270546103-9764516209ee?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'beer-2',
      name: 'Tuborg Classic Strong 650ml',
      nameNe: 'टुबोर्ग क्लासिक स्ट्रङ बियर',
      price: 410,
      unit: '650ml Bottle • 6.5% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Nepal\'s favorite strong lager beer with smooth malt flavor.',
      isAlcohol: true,
      alcoholPercentage: 6.5,
      images: ['https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'beer-3',
      name: 'Barasingha Belgian Witbier 650ml',
      nameNe: 'बारासिंघा बेल्जियन ह्विटबियर',
      price: 430,
      unit: '650ml Bottle • 5.0% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Craft brewed wheat beer infused with orange peel and coriander seeds.',
      isAlcohol: true,
      alcoholPercentage: 5.0,
      images: ['https://images.unsplash.com/photo-1571613316887-6f8d5cbf7ef7?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'beer-4',
      name: 'Somersby Apple Cider 330ml',
      nameNe: 'सोमर्सबी एप्पल साइडर',
      price: 260,
      unit: '330ml Can • 4.5% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Refreshing fermented apple cider with sparkling fruit crispness.',
      isAlcohol: true,
      alcoholPercentage: 4.5,
      images: ['https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'beer-5',
      name: 'Carlsberg Smooth Draught 650ml',
      nameNe: 'कार्लसबर्ग स्मूथ ड्राफ्ट',
      price: 440,
      unit: '650ml Bottle • 5.0% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Easy drinking premium lager with a smooth draught feel.',
      isAlcohol: true,
      alcoholPercentage: 5.0,
      images: ['https://images.unsplash.com/photo-1608270546103-9764516209ee?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'beer-6',
      name: 'Nepal Ice Super Strong Beer 650ml',
      nameNe: 'नेपाल आइस सुपर स्ट्रङ बियर',
      price: 360,
      unit: '650ml Bottle • 7.0% ABV',
      categoryName: 'Beers & Ciders',
      categorySlug: 'beers',
      categoryId: 'cat-beers',
      description: 'Classic robust lager brewed with Himalayan spring water.',
      isAlcohol: true,
      alcoholPercentage: 7.0,
      images: ['https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400&auto=format&fit=crop&q=80'],
    ),

    // Spirits & Rum
    ProductModel(
      id: 'spirit-1',
      name: 'Old Durbar Black Chimney 750ml',
      nameNe: 'ओल्ड दरबार ब्ल्याक चिम्नी',
      price: 3200,
      unit: '750ml Bottle • 42.8% ABV',
      categoryName: 'Whiskey & Spirits',
      categorySlug: 'spirits',
      categoryId: 'cat-spirits',
      description: 'Peated malt scotch blended with handcrafted Himalayan grain spirits.',
      isAlcohol: true,
      alcoholPercentage: 42.8,
      images: ['https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'spirit-2',
      name: 'Khukri XXX Himalayan Rum 750ml',
      nameNe: 'खुकुरी रम',
      price: 2150,
      unit: '750ml Bottle • 42.8% ABV',
      categoryName: 'Whiskey & Spirits',
      categorySlug: 'spirits',
      categoryId: 'cat-spirits',
      description: 'The legendary taste of the Himalayas aged in oak casks.',
      isAlcohol: true,
      alcoholPercentage: 42.8,
      images: ['https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'spirit-3',
      name: 'Jack Daniel\'s Tennessee 750ml',
      nameNe: 'ज्याक ड्यानियल्स नम्बर ७',
      price: 5400,
      unit: '750ml Bottle • 40.0% ABV',
      categoryName: 'Whiskey & Spirits',
      categorySlug: 'spirits',
      categoryId: 'cat-spirits',
      description: 'Charcoal mellowed drop by drop for world renowned sipping quality.',
      isAlcohol: true,
      alcoholPercentage: 40.0,
      images: ['https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'spirit-4',
      name: '8848 Pure Nepali Vodka 750ml',
      nameNe: '८८४८ भोड्का',
      price: 2200,
      unit: '750ml Bottle • 40.0% ABV',
      categoryName: 'Whiskey & Spirits',
      categorySlug: 'spirits',
      categoryId: 'cat-spirits',
      description: 'Five times distilled French winter wheat blended with mountain water.',
      isAlcohol: true,
      alcoholPercentage: 40.0,
      images: ['https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=400&auto=format&fit=crop&q=80'],
    ),

    // Mixers & Ice
    ProductModel(
      id: 'mixer-1',
      name: 'Pure Tube Ice Bag (2kg Sealed)',
      nameNe: 'प्योर आइस ब्याग (२ केजी)',
      price: 120,
      unit: '2000g Bag • Sealed Food Grade',
      categoryName: 'Mixers, Chasers & Ice',
      categorySlug: 'mixers',
      categoryId: 'cat-mixers',
      description: 'Hygienically produced food-grade tube ice cubes in double insulated packaging.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'mixer-2',
      name: 'Red Bull Energy Drink (250ml Can)',
      nameNe: 'रेड बुल इनर्जी ड्रिंक',
      price: 190,
      unit: '250ml Can • Chilled',
      categoryName: 'Mixers, Chasers & Ice',
      categorySlug: 'mixers',
      categoryId: 'cat-mixers',
      description: 'Vitalizes body and mind for your late night gatherings.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'mixer-3',
      name: 'Coca-Cola Pet Bottle (2.25L Mega)',
      nameNe: 'कोकाकोला २.२५ लिटर',
      price: 220,
      unit: '2.25L Bottle • Chilled',
      categoryName: 'Mixers, Chasers & Ice',
      categorySlug: 'mixers',
      categoryId: 'cat-mixers',
      description: 'Mega party size chilled Coca-Cola bottle.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'mixer-4',
      name: 'Schweppes Tonic Water (330ml Can)',
      nameNe: 'स्वेप्स टोनिक वाटर',
      price: 130,
      unit: '330ml Can • Chilled',
      categoryName: 'Mixers, Chasers & Ice',
      categorySlug: 'mixers',
      categoryId: 'cat-mixers',
      description: 'Crisp quinine tonic mixer for gin and spirits cocktails.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=400&auto=format&fit=crop&q=80'],
    ),

    // Hot Fast Food & Momos
    ProductModel(
      id: 'food-1',
      name: 'Spicy Buff C-Momo (10 pcs Plate)',
      nameNe: 'पिरो बफ सि-मोमो (१० पिस)',
      price: 260,
      unit: '10 pcs • Chef Hot Garlic Sauce',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Fresh steamed buff momos wok-tossed in signature fiery Kathmandu chili gravy.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1625398407796-82650a8c135f?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'food-2',
      name: 'Crispy Fried Chicken Wings (6 pcs)',
      nameNe: 'क्रिस्पी चिकेन विंग्स (६ पिस)',
      price: 390,
      unit: '6 pcs • Herb Dip',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Crispy golden fried wings tossed with Nepali Sichuan pepper and spicy dip.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'food-3',
      name: 'Chicken Steamed Momo (10 pcs Plate)',
      nameNe: 'चिकेन स्टिम मोमो (१० पिस)',
      price: 240,
      unit: '10 pcs • Tomato Achar',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Classic Kathmandu steamed chicken dumplings with fresh sesame-tomato chutney.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1625398407796-82650a8c135f?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'food-4',
      name: 'Chilli Chicken Dry (Chef Special Plate)',
      nameNe: 'चिल्ली चिकेन ड्राई',
      price: 380,
      unit: 'Plate • Wok Fried',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Tender chicken cubes wok-fried with bell peppers, onions, soy and hot green chilies.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'food-5',
      name: 'Pork Sekuwa Plate (Midnight Grill)',
      nameNe: 'पोर्क सेकुवा प्लेट',
      price: 450,
      unit: 'Plate • Marinated & Charcoal Grilled',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Traditional Dharan-style seasoned pork sekuwa served with radish pickle and puffed rice.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&auto=format&fit=crop&q=80'],
    ),
    ProductModel(
      id: 'food-6',
      name: 'Crispy French Fries with Garlic Dip',
      nameNe: 'फ्रेन्च फ्राइज गार्लिक सस',
      price: 180,
      unit: 'Bowl • Salted & Crispy',
      categoryName: 'Hot Fast Food',
      categorySlug: 'food',
      categoryId: 'cat-food',
      description: 'Double fried golden potato fries with house-made garlic mayo.',
      isAlcohol: false,
      images: ['https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&auto=format&fit=crop&q=80'],
    ),
  ];

  Future<void> _loadData() async {
    try {
      final pRes = await _api.dio.get('/products');
      final cRes = await _api.dio.get('/categories');
      if (mounted) {
        final List<ProductModel> fetched = (pRes.data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();

        // Merge with curated catalog without duplicating IDs
        final combined = [...fetched];
        for (var c in _curatedCatalog) {
          final exists = combined.any((p) => p.name.toLowerCase() == c.name.toLowerCase() || p.id == c.id);
          if (!exists) combined.add(c);
        }

        setState(() {
          _products = combined;
          _categories = cRes.data['categories'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = _curatedCatalog;
          _loading = false;
        });
      }
    }
  }

  List<ProductModel> _getCategoryProducts(String keyword) {
    return _products.where((p) {
      final matchCat = p.categoryName.toLowerCase().contains(keyword.toLowerCase()) ||
          p.categorySlug.toLowerCase().contains(keyword.toLowerCase());
      return matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = auth.user?.name.isNotEmpty == true ? auth.user!.name.split(' ').first : 'Prajina';

    // Active order check for floating tracker pill
    OrderModel? activeOrder;
    for (final o in orderProv.orders) {
      if (o.status != 'delivered' && o.status != 'cancelled') {
        activeOrder = o;
        break;
      }
    }

    final filtered = _products.where((p) {
      final matchesCategory = _selectedCategory.isEmpty ||
          p.categoryId == _selectedCategory ||
          p.categorySlug == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.nameNe.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final beerProducts = _getCategoryProducts('beer');
    final spiritProducts = _products.where((p) =>
      p.categoryName.toLowerCase().contains('whisky') ||
      p.categoryName.toLowerCase().contains('spirit') ||
      p.categoryName.toLowerCase().contains('rum') ||
      p.categoryName.toLowerCase().contains('vodka')
    ).toList();
    final mixerProducts = _getCategoryProducts('mixer').isNotEmpty
        ? _getCategoryProducts('mixer')
        : _products.where((p) =>
            p.categoryName.toLowerCase().contains('beverage') ||
            p.categoryName.toLowerCase().contains('soft') ||
            p.categoryName.toLowerCase().contains('ice')).toList();
    final foodProducts = _products.where((p) =>
      p.categoryName.toLowerCase().contains('snack') ||
      p.categoryName.toLowerCase().contains('food') ||
      p.categoryName.toLowerCase().contains('kitchen')
    ).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Press back again to exit app'),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.navyBrand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      body: SafeArea(
        child: _loading
            ? const ValleyLoaderScreen(label: "Loading tonight's catalog...")
            : ValleyRefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. NIGHT EXPRESS OPERATING PILL (8 PM - 4 AM)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(99),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.successGreen.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: AppTheme.bodyFont(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                children: [
                                  TextSpan(text: 'Happy ' + _dayName + ' • '),
                                  const TextSpan(
                                    text: 'See what is on offer',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryOrange),
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. USER HEADER (AVATAR, NAME, NOTIFICATION BELL, PROFILE)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primaryOrange, AppTheme.primaryDeep],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGlow,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: AvatarImage(
                                            url: auth.user!.avatarUrl!,
                                            size: 44,
                                            fallback: Center(
                                              child: Text(
                                                userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                                                style: AppTheme.displayFont(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                                            style: AppTheme.displayFont(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $userName',
                                      style: AppTheme.displayFont(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Craving midnight drinks & snacks?',
                                      style: AppTheme.bodyFont(
                                        fontSize: 11,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              // Notification Bell with Pulse Dot
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                  ).then((_) => _fetchUnreadNotifCount());
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
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        size: 20,
                                      ),
                                      if (_unreadNotifCount > 0)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryOrange,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.primaryOrange.withOpacity(0.8),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Profile Settings Button
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                                    Icons.person_outline_rounded,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. LOCATION PICKER BAR (DELIVER TO)
                      InkWell(
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
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppTheme.primaryOrange, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Deliver to: ',
                                style: AppTheme.bodyFont(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _currentDeliveryAddress,
                                  style: AppTheme.bodyFont(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primaryOrange),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. SEARCH PILL BAR
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: AppTheme.bodyFont(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search chilled beer, single malt, C-momos, ice bags...',
                            hintStyle: AppTheme.bodyFont(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryOrange, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ACTIVE ORDER FLOATING ALERT (IF ANY IN PROGRESS)
                      if (activeOrder != null) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryOrange.withOpacity(0.12),
                                  AppTheme.navyBrand.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${activeOrder.orderNo} in progress',
                                        style: AppTheme.displayFont(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Rider dispatched • Tap for live GPS tracking',
                                        style: AppTheme.bodyFont(fontSize: 11, color: AppTheme.primaryOrange),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryOrange),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // 5. CATEGORY GRID (CARDS WITH THUMBNAILS)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: AppTheme.displayFont(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          if (_selectedCategory.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = ''),
                              child: Text(
                                'Clear filter',
                                style: AppTheme.bodyFont(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickCategoryCard(
                              title: 'All Items',
                              icon: Icons.grid_view_rounded,
                              isSelected: _selectedCategory.isEmpty,
                              onTap: () => setState(() => _selectedCategory = ''),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildQuickCategoryCard(
                              title: 'Chilled Beers',
                              icon: Icons.sports_bar_rounded,
                              isSelected: _selectedCategory == 'beers' || _selectedCategory.contains('beer'),
                              onTap: () => setState(() => _selectedCategory = 'beers'),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildQuickCategoryCard(
                              title: 'Spirits & Rum',
                              icon: Icons.liquor_rounded,
                              isSelected: _selectedCategory == 'spirits' || _selectedCategory.contains('spirit'),
                              onTap: () => setState(() => _selectedCategory = 'spirits'),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildQuickCategoryCard(
                              title: 'Mixers & Ice',
                              icon: Icons.ac_unit_rounded,
                              isSelected: _selectedCategory == 'mixers' || _selectedCategory.contains('mixer'),
                              onTap: () => setState(() => _selectedCategory = 'mixers'),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildQuickCategoryCard(
                              title: 'Hot Fast Food',
                              icon: Icons.lunch_dining_rounded,
                              isSelected: _selectedCategory == 'food' || _selectedCategory.contains('food'),
                              onTap: () => setState(() => _selectedCategory = 'food'),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. OFFERS CAROUSEL SLIDER (MIDNIGHT SPECIAL & PARTY PACK)
                      SizedBox(
                        height: 140,
                        child: PageView(
                          controller: _offersPageController,
                          onPageChanged: (idx) => setState(() => _currentOfferSlide = idx),
                          children: [
                            // Slide 1: Midnight Special Up to 30%
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF4B26), Color(0xFFE03612)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryOrange.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'MIDNIGHT SPECIAL',
                                            style: AppTheme.displayFont(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Get Special Offers\nUp to 30% OFF',
                                          style: AppTheme.displayFont(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Claim Deal >',
                                            style: AppTheme.displayFont(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryOrange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.local_pizza_rounded, size: 76, color: Color(0x33FFFFFF)),
                                ],
                              ),
                            ),

                            // Slide 2: Party Pack Deal
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF003893), Color(0xFF0284C7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.navyBrand.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'PARTY PACK DEAL',
                                            style: AppTheme.displayFont(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '4x Chilled Beer + Wings\nRs. 1,499 Flat',
                                          style: AppTheme.displayFont(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Get Bundle >',
                                            style: AppTheme.displayFont(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.navyBrand,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.sports_bar_rounded, size: 76, color: Color(0x33FFFFFF)),
                                ],
                              ),
                            ),

                            // Slide 3: Weekend Chiller
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.chilledIce.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'ICE BAG COMPLIMENTARY',
                                            style: AppTheme.displayFont(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Free 2kg Tube Ice Bag\nOn orders above Rs. 2,000',
                                          style: AppTheme.displayFont(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Code: FREEICE',
                                            style: AppTheme.displayFont(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.chilledIce,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.ac_unit_rounded, size: 76, color: Color(0x33FFFFFF)),
                                ],
                              ),
                            ),

                            // Slide 4: Momo Madness
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE11D48), Color(0xFFFF4B26)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'MOMO MADNESS COMBO',
                                            style: AppTheme.displayFont(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Buy 2 Plates C-Momo\nGet Coke 500ml Free',
                                          style: AppTheme.displayFont(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Order Combo >',
                                            style: AppTheme.displayFont(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.fastfood_rounded, size: 76, color: Color(0x33FFFFFF)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Carousel Dots (4 dots)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(0, _currentOfferSlide),
                          const SizedBox(width: 6),
                          _buildDot(1, _currentOfferSlide),
                          const SizedBox(width: 6),
                          _buildDot(2, _currentOfferSlide),
                          const SizedBox(width: 6),
                          _buildDot(3, _currentOfferSlide),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 7. BEERS & CIDERS HORIZONTAL SLIDER
                      if (_searchQuery.isEmpty && _selectedCategory.isEmpty && beerProducts.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Beers & Ciders',
                          icon: Icons.sports_bar_rounded,
                          count: beerProducts.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: beerProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, idx) => _buildHorizontalProductCard(beerProducts[idx], cart, isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 8. WHISKEY & SPIRITS HORIZONTAL SLIDER
                      if (_searchQuery.isEmpty && _selectedCategory.isEmpty && spiritProducts.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Whiskey & Spirits',
                          icon: Icons.liquor_rounded,
                          count: spiritProducts.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: spiritProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, idx) => _buildHorizontalProductCard(spiritProducts[idx], cart, isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 9. MIXERS, CHASERS & ICE CUBES
                      if (_searchQuery.isEmpty && _selectedCategory.isEmpty && mixerProducts.isNotEmpty) ...[
                        _buildSectionHeader(
                          title: 'Mixers, Chasers & Ice Bags',
                          icon: Icons.ac_unit_rounded,
                          count: mixerProducts.length,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: mixerProducts.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (ctx, idx) => _buildHorizontalProductCard(mixerProducts[idx], cart, isDark),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 10. HOT KITCHEN / ALL CATALOG (2-COLUMN GRID)
                      _buildSectionHeader(
                        title: _selectedCategory.isNotEmpty
                            ? 'Selected Products'
                            : (_searchQuery.isNotEmpty ? 'Search Results' : 'Hot Kitchen & All Items'),
                        icon: Icons.fastfood_rounded,
                        count: filtered.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      filtered.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No products match "$_searchQuery"'
                                        : 'No products in this section.',
                                    style: AppTheme.bodyFont(color: Colors.grey, fontSize: 13),
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
                                return _buildGridProductCard(filtered[idx], cart, isDark);
                              },
                            ),

                      const SizedBox(height: 90), // Bottom navigation spacing
                    ],
                  ),
                ),
              ),
      ),

      // FLOATING CHAT BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Messages & Order Chats',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChatInboxScreen(),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
            Consumer<ChatUnreadProvider>(
              builder: (_, unread, __) => unread.total == 0
                  ? const SizedBox.shrink()
                  : Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.alertRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          unread.total > 9 ? '9+' : '${unread.total}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION & STICKY CART CAPSULE
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // STICKY FLOATING BASKET CAPSULE (MATCHING PROTOTYPE)
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
                  color: isDark ? const Color(0xFF11141D) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${cart.itemCount} Item${cart.itemCount > 1 ? 's' : ''} in Basket',
                            style: AppTheme.displayFont(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Kathmandu late night dispatch ready',
                            style: AppTheme.bodyFont(color: const Color(0xFF94A3B8), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${cart.subtotal}',
                      style: AppTheme.displayFont(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 18),
                    ),
                  ],
                ),
              ),
            ),

          // BOTTOM NAV BAR
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
                ),
              ),
            ),
            // Clear the Android gesture/navigation bar, which otherwise
            // sits on top of the tab labels.
            padding: EdgeInsets.only(
              top: 8,
              bottom: 8 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _currentNavIndex == 0,
                  onTap: () => setState(() => _currentNavIndex = 0),
                  isDark: isDark,
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
                  isDark: isDark,
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
                  isDark: isDark,
                ),
                Consumer<ChatUnreadProvider>(
                  builder: (_, unread, __) => _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    showDot: unread.total > 0,
                    isSelected: _currentNavIndex == 3,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    isDark: isDark,
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

  Widget _buildDot(int index, int current) {
    final active = index == current;
    return Container(
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryOrange : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildQuickCategoryCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange
              : (isDark ? AppTheme.darkSurfaceCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryOrange
                : (isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.displayFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.displayFont(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        Text(
          'See All ($count)',
          style: AppTheme.bodyFont(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(ProductModel p, CartProvider cart, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
      },
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 105,
                    width: double.infinity,
                    color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                    child: ValleyProductImage(
                      imageUrl: p.images.isNotEmpty ? p.images.first : null,
                      height: 105,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      p.isAlcohol ? '18+' : '-10%',
                      style: AppTheme.displayFont(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Builder(
                    builder: (btnCtx) => GestureDetector(
                      onTap: () {
                        FlyToCart.runFromContext(sourceContext: btnCtx, targetKey: _cartTargetKey);
                        cart.addItem(p);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.displayFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Rs. ${p.price}',
                  style: AppTheme.displayFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Rs. ${(p.price * 1.1).round()}',
                  style: AppTheme.bodyFont(
                    fontSize: 10,
                    color: Colors.grey,
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              p.unit.isNotEmpty ? p.unit : '650ml Bottle',
              style: AppTheme.bodyFont(
                fontSize: 10,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductCard(ProductModel p, CartProvider cart, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 105,
                    width: double.infinity,
                    color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
                    child: ValleyProductImage(
                      imageUrl: p.images.isNotEmpty ? p.images.first : null,
                      height: 105,
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
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '18+ Alcohol',
                        style: AppTheme.displayFont(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.displayFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  if (p.nameNe.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.nameNe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyFont(
                        fontSize: 10,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    p.unit.isNotEmpty ? p.unit : 'Standard Pack',
                    style: AppTheme.bodyFont(
                      fontSize: 10,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs. ${p.price}',
                      style: AppTheme.displayFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    Text(
                      'Rs. ${(p.price * 1.1).round()}',
                      style: AppTheme.bodyFont(
                        fontSize: 10,
                        color: Colors.grey,
                      ).copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                Builder(
                  builder: (buttonContext) => GestureDetector(
                    onTap: () {
                      FlyToCart.runFromContext(
                        sourceContext: buttonContext,
                        targetKey: _cartTargetKey,
                      );
                      cart.addItem(p);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withOpacity(0.35),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
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
    required bool isDark,
    int badgeCount = 0,
    bool showDot = false,
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
                color: isSelected
                    ? AppTheme.primaryOrange
                    : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              else if (showDot)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.alertRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.displayFont(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppTheme.primaryOrange
                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}
