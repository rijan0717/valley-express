class OrderItemModel {
  final String product;
  final String name;
  final int price;
  final int quantity;
  final bool isAlcohol;

  OrderItemModel({
    required this.product,
    required this.name,
    required this.price,
    required this.quantity,
    this.isAlcohol = false,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      product: json['product'] is Map ? json['product']['_id'] : json['product'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isAlcohol: json['isAlcohol'] ?? false,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNo;
  final List<OrderItemModel> items;
  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int total;
  final String status;
  final String paymentMethod;
  final String addressText;
  final String? landmark;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? riderName;
  final String? riderPhone;
  final String? riderAvatarUrl;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNo,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.addressText,
    this.landmark,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.riderName,
    this.riderPhone,
    this.riderAvatarUrl,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final deliveryAddr = json['deliveryAddress'] ?? json['address'] ?? {};
    final coords = deliveryAddr['location']?['coordinates'] as List<dynamic>?;
    double? lon = coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : null;
    double? lat = coords != null && coords.length > 1 ? (coords[1] as num).toDouble() : null;

    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      orderNo: json['orderNo'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'placed',
      paymentMethod: json['paymentMethod'] ?? 'cash_on_delivery',
      addressText: deliveryAddr['addressText'] ?? 'Kathmandu Valley',
      landmark: deliveryAddr['landmark'],
      formattedAddress: deliveryAddr['formattedAddress'],
      latitude: lat,
      longitude: lon,
      riderName: json['rider']?['name'],
      riderPhone: json['rider']?['phone'],
      riderAvatarUrl: json['rider']?['avatarUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
