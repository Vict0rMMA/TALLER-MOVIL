class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String image;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      // El precio puede venir como int o double en el JSON
      price: (json['price'] as num? ?? 0).toDouble(),
      image: json['image'] as String? ?? '',
    );
  }
}
