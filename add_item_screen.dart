import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/item.dart';

class AddItemScreen extends StatefulWidget {
  final int categoryId;
  final Item? item; // null -> add, not null -> edit
  AddItemScreen({required this.categoryId, this.item});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseHelper();

  late TextEditingController nameCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController pPriceCtrl;
  late TextEditingController sPriceCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    qtyCtrl = TextEditingController(
        text: widget.item != null ? widget.item!.quantity.toString() : '0');
    pPriceCtrl = TextEditingController(
        text: widget.item != null ? widget.item!.purchasePrice.toString() : '0');
    sPriceCtrl = TextEditingController(
        text: widget.item != null ? widget.item!.salePrice.toString() : '0');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    pPriceCtrl.dispose();
    sPriceCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameCtrl.text.trim();
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final pPrice = double.tryParse(pPriceCtrl.text) ?? 0;
    final sPrice = double.tryParse(sPriceCtrl.text) ?? 0;

    final item = Item(
      id: widget.item?.id,
      categoryId: widget.categoryId,
      name: name,
      quantity: qty,
      purchasePrice: pPrice,
      salePrice: sPrice,
    );

    if (widget.item == null) {
      await db.insertItem(item);
    } else {
      await db.updateItem(item);
    }
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.lightBlue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[200], // Sky blue appbar
        title: Text(
          isEdit ? 'Edit Item' : 'Add Item',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: _inputDecoration('Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: _inputDecoration('Quantity'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: pPriceCtrl,
                decoration: _inputDecoration('Purchase Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: sPriceCtrl,
                decoration: _inputDecoration('Sale Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[100], // Light blue
                  foregroundColor: Colors.black, // Black text
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEdit ? 'Update Item' : 'Add Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
