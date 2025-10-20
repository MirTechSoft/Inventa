class Sale {
  int? id;
  int itemId;
  String shopkeeperName;
  int quantity;
  String date; // ISO string

  Sale({
    this.id,
    required this.itemId,
    required this.shopkeeperName,
    required this.quantity,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'shopkeeperName': shopkeeperName,
      'quantity': quantity,
      'date': date,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> m) {
    return Sale(
      id: m['id'],
      itemId: m['itemId'],
      shopkeeperName: m['shopkeeperName'],
      quantity: m['quantity'],
      date: m['date'],
    );
  }
}
