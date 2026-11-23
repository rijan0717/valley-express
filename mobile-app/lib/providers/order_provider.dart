import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/order.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/orders/my');
      if (res.data['success'] == true) {
        _orders = (res.data['orders'] as List<dynamic>)
            .map((e) => OrderModel.fromJson(e))
            .toList();
        if (_orders.isNotEmpty) {
          _currentOrder = _orders.first;
        }
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressText,
    String? landmark,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    String? contactPhone,
    String? offerCode,
    String paymentMethod = 'cash_on_delivery',
    bool ageConfirmed = false,
    int coinsToRedeem = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final double lon = longitude ?? 85.3300;
      final double lat = latitude ?? 27.7280;

      final res = await _api.dio.post('/orders', data: {
        'items': items,
        'address': {
          'addressText': addressText,
          'landmark': landmark ?? '',
          'formattedAddress': formattedAddress ?? addressText,
          'location': {
            'type': 'Point',
            'coordinates': [lon, lat],
          },
          'contactPhone': (contactPhone != null && contactPhone.isNotEmpty) ? contactPhone : '9841234567',
        },
        'paymentMethod': paymentMethod,
        if (offerCode != null && offerCode.isNotEmpty) 'offerCode': offerCode,
        'ageConfirmed': ageConfirmed,
        // A count, never a discount: the server works out what the coins are
        // worth and validates them against the real balance.
        if (coinsToRedeem > 0) 'coinsToRedeem': coinsToRedeem,
      });

      if (res.data['success'] == true) {
        final newOrder = OrderModel.fromJson(res.data['order']);
        _orders.insert(0, newOrder);
        _currentOrder = newOrder;
        _isLoading = false;
        notifyListeners();
        return newOrder;
      }
    } catch (e) {
      if (e is DioException) {
        _errorMessage = e.response?.data?['message'] ?? e.message;
      } else {
        _errorMessage = e.toString();
      }
      debugPrint('[placeOrder Error] $_errorMessage');
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  void setCurrentOrder(OrderModel order) {
    _currentOrder = order;
    notifyListeners();
  }

  void updateOrderStatus(Map<String, dynamic> updatedJson) {
    final updated = OrderModel.fromJson(updatedJson);
    final index = _orders.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      _orders[index] = updated;
    }
    if (_currentOrder?.id == updated.id) {
      _currentOrder = updated;
    }
    notifyListeners();
  }
}
