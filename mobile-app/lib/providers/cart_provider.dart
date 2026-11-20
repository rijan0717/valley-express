import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../core/constants.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);
  int get totalQuantity => itemCount;

  int get subtotal => _items.values.fold(0, (sum, i) => sum + i.totalPrice);

  bool get hasAlcohol => _items.values.any((i) => i.product.isAlcohol);

  int get deliveryFee =>
      subtotal >= AppConstants.freeDeliveryThreshold || subtotal == 0
          ? 0
          : AppConstants.defaultDeliveryFee;

  int get grandTotal => subtotal + deliveryFee;

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      _items[product.id] = CartItemModel(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    if (!_items.containsKey(productId)) return;
    _items[productId]!.quantity += delta;
    if (_items[productId]!.quantity <= 0) {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    updateQuantity(productId, -1);
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
