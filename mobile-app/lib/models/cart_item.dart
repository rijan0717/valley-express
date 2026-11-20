import 'product.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  int get totalPrice => (product.discountPrice ?? product.price) * quantity;
}
