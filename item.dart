class Item {
  int? id;
  int categoryId;
  String name;
  int quantity;
  double purchasePrice;
  double salePrice;

  Item({
    this.id,
    required this.categoryId,
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
    };
  }

  factory Item.fromMap(Map<String, dynamic> m) {
    return Item(
      id: m['id'],
      categoryId: m['categoryId'],
      name: m['name'],
      quantity: m['quantity'],
      purchasePrice: (m['purchasePrice'] as num).toDouble(),
      salePrice: (m['salePrice'] as num).toDouble(),
    );
  }
}
