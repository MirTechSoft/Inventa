import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/database_helper.dart';
import '../models/sale.dart';

class SaleDetailScreen extends StatefulWidget {
  final String shopkeeper;

  SaleDetailScreen({required this.shopkeeper});

  @override
  _SaleDetailScreenState createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> _salesList = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final rows = await db.getSalesByShopkeeper(widget.shopkeeper);
    final copy = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    setState(() => _salesList = copy);
  }

  double get totalAmount {
    return _salesList.fold(0.0, (sum, s) {
      final salePrice = ((s['salePrice'] ?? 0) as num).toDouble();
      final qty = ((s['quantity'] ?? 0) as num).toDouble();
      return sum + salePrice * qty;
    });
  }

  double get totalProfit {
    return _salesList.fold(0.0, (sum, s) {
      final salePrice = ((s['salePrice'] ?? 0) as num).toDouble();
      final purchasePrice = ((s['purchasePrice'] ?? 0) as num).toDouble();
      final qty = ((s['quantity'] ?? 0) as num).toDouble();
      return sum + (salePrice - purchasePrice) * qty;
    });
  }

  // ------------------- Quantity Edit -------------------
  Future<void> _editItem(int index) async {
    final item = _salesList[index];
    final qtyController =
        TextEditingController(text: ((item['quantity'] ?? 0)).toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Edit Quantity - ${item['itemName'] ?? 'Item'}",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: "Quantity",
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue[200],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.lightBlue)),
            ),
            onPressed: () async {
              final newQty =
                  int.tryParse(qtyController.text) ?? (item['quantity'] ?? 0);
              if (newQty <= 0) return;

              final oldQty = (item['quantity'] ?? 0) as int;

              final sale = Sale(
                id: ((item['saleId'] ?? 0) as num).toInt(),
                itemId: ((item['itemId'] ?? 0) as num).toInt(),
                shopkeeperName: widget.shopkeeper,
                quantity: newQty,
                date: item['date'] ?? DateTime.now().toIso8601String(),
              );

              await db.updateSaleAndStock(sale,
                  oldQty: oldQty, newQty: newQty);
              setState(() => item['quantity'] = newQty);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // ------------------- Sale Price Edit (Permanent per Shopkeeper) -------------------
  Future<void> _editSalePrice(int index) async {
    final item = _salesList[index];
    final priceController = TextEditingController(
        text: ((item['salePrice'] ?? 0)).toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Edit Sale Price - ${item['itemName'] ?? 'Item'}",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: "Sale Price",
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue[200],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.lightBlue)),
            ),
            onPressed: () async {
              final newPrice =
                  double.tryParse(priceController.text) ??
                      (item['salePrice'] ?? 0);
              if (newPrice <= 0) return;

              final itemId = ((item['itemId'] ?? 0) as num).toInt();

              // ✅ Update DB permanently for this item only
              await db.updateSalePrice(itemId, newPrice);

              // ✅ Reload only this shopkeeper's sales
              await _loadSales();

              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // ------------------- Delete Sale -------------------
  Future<void> _deleteItem(int index) async {
    final item = _salesList[index];
    final saleId = ((item['saleId'] ?? 0) as num).toInt();
    final itemId = ((item['itemId'] ?? 0) as num).toInt();
    final qty = ((item['quantity'] ?? 0) as num).toInt();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete sale', style: TextStyle(color: Colors.black)),
        content: Text('Delete this sale and restore stock?',
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.black))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    if (confirm != true) return;
    await db.deleteSaleAndRestoreStock(
        saleId: saleId, itemId: itemId, qty: qty);
    setState(() => _salesList.removeAt(index));
  }

  // ------------------- Generate PDF -------------------
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Shopkeeper: ${widget.shopkeeper}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Items:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ..._salesList.map((s) {
                final qty = ((s['quantity'] ?? 0) as num).toDouble();
                final salePrice = ((s['salePrice'] ?? 0) as num).toDouble();
                final amount = salePrice * qty;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        '${s['categoryName'] ?? 'Category'} - ${s['itemName'] ?? 'Item'}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('Quantity: ${qty.toInt()}'),
                    pw.Text('Sale Price: Rs. ${salePrice.toStringAsFixed(2)}'),
                    pw.Text(
                        'Total Amount: Rs. ${amount.toStringAsFixed(2)}'),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),
              pw.Divider(),
              pw.Text(
                  'Total Amount: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final date = _salesList.isNotEmpty
        ? (_salesList.first['date'] ?? DateTime.now().toString())
        : DateTime.now().toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[400],
        title: Text('Invoice - ${widget.shopkeeper}',
            style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.black),
            onPressed: _generatePdf,
            tooltip: 'Export PDF (Profit hidden)',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shopkeeper: ${widget.shopkeeper}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text(
                  'Date: ${DateTime.parse(date).toLocal().toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.black)),
              SizedBox(height: 16),
              Text('Items:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Divider(),
              Expanded(
                child: _salesList.isEmpty
                    ? Center(
                        child: Text('No items for this shopkeeper',
                            style: TextStyle(color: Colors.black)))
                    : ListView.builder(
                        itemCount: _salesList.length,
                        itemBuilder: (_, i) {
                          final s = _salesList[i];
                          final qty =
                              ((s['quantity'] ?? 0) as num).toDouble();
                          final salePrice =
                              ((s['salePrice'] ?? 0) as num).toDouble();
                          final purchasePrice =
                              ((s['purchasePrice'] ?? 0) as num).toDouble();
                          final amount = salePrice * qty;
                          final profit = (salePrice - purchasePrice) * qty;

                          return Card(
                            color: Colors.lightBlue[100],
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${s['categoryName'] ?? 'Unknown Category'} - ${s['itemName'] ?? 'Item'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    SizedBox(height: 4),
                                    Text('Quantity: ${qty.toInt()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    Text(
                                        'Sale Price: Rs. ${salePrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    Text(
                                        'Profit: Rs. ${profit.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                    SizedBox(height: 6),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(
                                              'Rs. ${amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black)),
                                          Row(children: [
                                            IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _editItem(i)),
                                            IconButton(
                                                icon: Icon(Icons
                                                    .price_change,
                                                    color: Colors.green),
                                                onPressed: () =>
                                                    _editSalePrice(
                                                        i)),
                                            IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteItem(i)),
                                          ])
                                        ])
                                  ]),
                            ),
                          );
                        },
                      ),
              ),
              Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          'Total Amount: Rs. ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text(
                          'Total Profit: Rs. ${totalProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16,
                              color:
                                  Color.fromARGB(255, 33, 150, 243),
                              fontWeight: FontWeight.bold)),
                    ]),
              ),
            ]),
      ),
    );
  }
}
