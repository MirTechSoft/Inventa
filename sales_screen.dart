import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/sale.dart';

class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final db = DatabaseHelper();
  List<Category> categories = [];
  List<Item> items = [];

  Category? selectedCategory;
  Item? selectedItem;

  final shopkeeperCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> cart = [];

  final skyBlue = Colors.lightBlue[400];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future _loadCategories() async {
    final cats = await db.getCategories();
    setState(() => categories = cats);
  }

  Future _loadItemsForCategory(int categoryId) async {
    final its = await db.getItemsByCategory(categoryId);
    setState(() {
      items = its;
      selectedItem = its.firstWhere((it) => it.quantity > 0);
    });
  }

  void _onCategoryChanged(Category? c) {
    setState(() {
      selectedCategory = c;
      items = [];
      selectedItem = null;
    });
    if (c != null) _loadItemsForCategory(c.id!);
  }

  void _showMessage(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addToCart() {
    final q = int.tryParse(qtyCtrl.text) ?? 0;
    if (selectedItem == null || selectedCategory == null || q <= 0) {
      _showMessage('Select item & valid quantity', Colors.red[200]!);
      return;
    }

    if (selectedItem!.quantity <= 0) {
      _showMessage('This item is out of stock', Colors.red[200]!);
      return;
    }

    if (q > selectedItem!.quantity) {
      _showMessage('Quantity exceeds available stock', Colors.red[200]!);
      return;
    }

    if (cart.length >= 30) {
      _showMessage('Max 30 items allowed', Colors.red[200]!);
      return;
    }

    final item = selectedItem!;
    final amount = item.salePrice * q;
    final profitPerUnit = item.salePrice - item.purchasePrice;
    final profit = profitPerUnit * q;

    setState(() {
      cart.add({
        "shopkeeper": shopkeeperCtrl.text.trim(),
        "categoryName": selectedCategory!.name,
        "itemId": item.id!,
        "itemName": item.name,
        "qty": q,
        "salePrice": item.salePrice,
        "amount": amount,
        "profitPerUnit": profitPerUnit,
        "profit": profit,
        "date": selectedDate.toIso8601String(),
      });
    });
  }

  void _removeFromCart(int index) {
    setState(() => cart.removeAt(index));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: skyBlue!),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _saveSale() async {
    final shop = shopkeeperCtrl.text.trim();
    if (shop.isEmpty || cart.isEmpty) {
      _showMessage('Enter shopkeeper & add items', Colors.red[200]!);
      return;
    }

    try {
      for (var c in cart) {
        final sale = Sale(
          itemId: c["itemId"],
          shopkeeperName: shop,
          quantity: c["qty"],
          date: selectedDate.toIso8601String(),
        );
        await db.insertSaleAndReduceStock(sale);
      }

      _showMessage('Sale saved successfully', Colors.lightBlue[200]!);
      setState(() {
        cart.clear();
        shopkeeperCtrl.clear();
        qtyCtrl.text = "1";
        selectedDate = DateTime.now();
      });
    } catch (e) {
      _showMessage('Error: ${e.toString()}', Colors.red[200]!);
    }
  }

  @override
  void dispose() {
    shopkeeperCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = cart.fold(0, (sum, item) => sum + (item["amount"] as num));
    double totalProfit = cart.fold(0, (sum, item) => sum + (item["profit"] as num));

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales', style: TextStyle(color: Colors.black)),
        backgroundColor: skyBlue,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            // Shopkeeper
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: shopkeeperCtrl,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: "Shopkeeper's Name",
                    labelStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Date picker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.calendar_today, color: skyBlue),
                onTap: _pickDate,
              ),
            ),
            SizedBox(height: 12),

            // Category dropdown
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<Category>(
                  hint: Text('Select Category', style: TextStyle(color: Colors.black)),
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: TextStyle(color: Colors.black))))
                      .toList(),
                  onChanged: _onCategoryChanged,
                  decoration: InputDecoration(border: InputBorder.none),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Item dropdown
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<Item>(
                  hint: Text('Select Item', style: TextStyle(color: Colors.black)),
                  value: selectedItem,
                  items: items.map((it) {
                    bool outOfStock = it.quantity <= 0;
                    return DropdownMenuItem<Item>(
                      value: outOfStock ? null : it,
                      enabled: !outOfStock,
                      child: Text(
                        '${it.name} (Stock: ${it.quantity}) ${outOfStock ? "- Out of Stock" : ""}',
                        style: TextStyle(
                          color: outOfStock ? Colors.red : Colors.black,
                          fontStyle: outOfStock ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Item? it) => setState(() => selectedItem = it),
                  decoration: InputDecoration(border: InputBorder.none),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Quantity
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: qtyCtrl,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton(
              onPressed: _addToCart,
              child: Text("Add Item to Cart", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            Divider(height: 30, thickness: 1),

            Text("Cart Items:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),

            ...cart.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return Card(
                color: Colors.lightBlue[50],
                margin: EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${c["categoryName"]} - ${c["itemName"]}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                      SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: "Quantity: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "${c["qty"]}"),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: "Sale Price: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "Rs. ${c["salePrice"]}"),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: "Total Amount: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "Rs. ${c["amount"]}"),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(text: "Profit: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "Rs. ${c["profit"]}"),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromCart(i),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (cart.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(thickness: 1),
              Card(
                color: Colors.lightBlue[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(text: "Total Amount: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "Rs. $totalAmount"),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(text: "Total Profit: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: "Rs. $totalProfit"),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saveSale,
                        child: Text("Save Sale", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: skyBlue,
                          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
