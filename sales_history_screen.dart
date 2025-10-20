import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/item.dart';
import 'sale_detail_screen.dart';
import 'payment_status_screen.dart'; // ✅ Payment screen import

class SalesHistoryScreen extends StatefulWidget {
  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final db = DatabaseHelper();
  Map<String, List<Map<String, dynamic>>> groupedSales = {};
  bool _isLoading = true; // ✅ Loading indicator

  final skyBlue = Colors.lightBlue[400]; // ✅ Sky blue color

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
  }

  Future<void> _loadSalesHistory() async {
    setState(() => _isLoading = true); // start loading
    try {
      final sales = await db.getAllSales(); // List<Sale>
      Map<String, List<Map<String, dynamic>>> tempGrouped = {};

      for (var s in sales) {
        Item? item = await db.getItemById(s.itemId);
        if (item != null) {
          final amount = item.salePrice * s.quantity;
          final profit = (item.salePrice - item.purchasePrice) * s.quantity;

          final detail = {
            "sale": s,
            "item": item,
            "itemName": item.name,
            "qty": s.quantity,
            "salePrice": item.salePrice,
            "amount": amount,
            "profit": profit,
            "date": s.date,
          };

          if (!tempGrouped.containsKey(s.shopkeeperName)) {
            tempGrouped[s.shopkeeperName] = [];
          }
          tempGrouped[s.shopkeeperName]!.add(detail);
        }
      }

      if (mounted) {
        setState(() {
          groupedSales = tempGrouped;
          _isLoading = false; // stop loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error loading sales: $e");
    }
  }

  Future<void> deleteShopkeeperSales(String shopkeeper) async {
    final salesList = groupedSales[shopkeeper] ?? [];
    for (var s in salesList) {
      final sale = s["sale"];
      final item = s["item"];
      if (sale != null && item != null) {
        await db.deleteSaleAndRestoreStock(
          saleId: sale.id!,
          itemId: item.id!,
          qty: sale.quantity,
        );
      }
    }

    if (mounted) {
      setState(() {
        groupedSales.remove(shopkeeper);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sales History", style: TextStyle(color: Colors.black)),
        backgroundColor: skyBlue,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: skyBlue)) // ✅ loader color
          : groupedSales.isEmpty
              ? Center(child: Text("No sales recorded yet"))
              : ListView(
                  children: groupedSales.entries.map((entry) {
                    final shopkeeper = entry.key;
                    final salesList = entry.value;

                    final totalAmount =
                        salesList.fold(0.0, (sum, s) => sum + (s["amount"] ?? 0));
                    final totalProfit =
                        salesList.fold(0.0, (sum, s) => sum + (s["profit"] ?? 0));

                    return Card(
                      color: Colors.lightBlue[50], // ✅ card color
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          "$shopkeeper",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        subtitle: Text(
                            "Total: Rs. $totalAmount | Profit: Rs. $totalProfit",
                            style: TextStyle(color: Colors.black)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PaymentStatusScreen(shopkeeper: shopkeeper),
                                  ),
                                );
                                // ✅ Refresh after returning
                                _loadSalesHistory();
                              },
                              child: Text("Payment Status",
                                  style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue[200],
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text("Delete Sales"),
                                    content: Text(
                                        "Are you sure you want to delete all sales of $shopkeeper?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await deleteShopkeeperSales(shopkeeper);
                                }
                              },
                            ),
                            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SaleDetailScreen(shopkeeper: shopkeeper),
                            ),
                          );
                          // ✅ Refresh after returning
                          _loadSalesHistory();
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
