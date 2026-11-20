class ProductModel {
  final String id;
  final String name;
  final String nameNe;
  final String description;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final int price;
  final int? discountPrice;
  final int stock;
  final String unit;
  final List<String> images;
  final bool isAlcohol;
  final double alcoholPercentage;
  final bool isFeatured;

  ProductModel({
    required this.id,
    required this.name,
    this.nameNe = '',
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    this.categorySlug = '',
    required this.price,
    this.discountPrice,
    this.stock = 0,
    this.unit = 'item',
    this.images = const [],
    this.isAlcohol = false,
    this.alcoholPercentage = 0.0,
    this.isFeatured = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String catId = '';
    String catName = '';
    String catSlug = '';

    if (json['category'] != null) {
      if (json['category'] is Map) {
        catId = json['category']['_id'] ?? json['category']['id'] ?? '';
        catName = json['category']['name'] ?? '';
        catSlug = json['category']['slug'] ?? '';
      } else {
        catId = json['category'].toString();
      }
    }

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      nameNe: json['nameNe'] ?? '',
      description: json['description'] ?? '',
      categoryId: catId,
      categoryName: catName,
      categorySlug: catSlug,
      price: (json['price'] as num?)?.toInt() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toInt(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] ?? 'item',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isAlcohol: json['isAlcohol'] ?? false,
      alcoholPercentage: (json['alcoholPercentage'] as num?)?.toDouble() ?? 0.0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}
