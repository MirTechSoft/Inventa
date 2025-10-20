import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/category.dart';
import '../models/item.dart';
import 'add_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final db = DatabaseHelper();
  List<Category> categories = [];
  Map<int, double> categoryTotalValue = {};
  bool isLoading = true;

  final skyBlue = Colors.lightBlue[400];
  final lightBlue = Colors.lightBlue[100];

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future _loadCats() async {
    setState(() => isLoading = true);
    final cats = await db.getCategories();
    Map<int, double> totals = {};
    for (var c in cats) {
      final items = await db.getItemsByCategory(c.id!);
      double total = 0;
      for (var item in items) {
        // ✅ yahan Purchase Price * Quantity lagaya
        total += item.purchasePrice * item.quantity;
      }
      totals[c.id!] = total;
    }

    setState(() {
      categories = cats;
      categoryTotalValue = totals;
      isLoading = false;
    });
  }

  void _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Add Category',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.black))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightBlue,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await db.insertCategory(Category(name: name));
              Navigator.pop(context);
              _loadCats();
            },
            child: Text('Add',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _openCategoryItems(Category c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryItemsScreen(category: c),
      ),
    ).then((_) => _loadCats());
  }

  Future<void> _deleteCategory(Category c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Category',
            style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete "${c.name}"?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.black))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[300],
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteCategory(c.id!);
      _loadCats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "${c.name}" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: skyBlue,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: skyBlue))
          : categories.isEmpty
              ? Center(
                  child: Text('No categories. Add one.',
                      style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final totalValue = categoryTotalValue[c.id!] ?? 0;
                    return Card(
                      color: lightBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.lightBlue, width: 1)),
                      margin:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(c.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        subtitle: Text(
                            'Total Value: Rs. ${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.black87)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(c),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.black54, size: 18),
                          ],
                        ),
                        onTap: () => _openCategoryItems(c),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightBlue,
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.inventory_2, color: Colors.black),
        tooltip: 'Add Category',
      ),
    );
  }
}

// ----------------- Category Items screen -----------------
class CategoryItemsScreen extends StatefulWidget {
  final Category category;
  CategoryItemsScreen({required this.category});

  @override
  _CategoryItemsScreenState createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final db = DatabaseHelper();
  List<Item> items = [];
  double totalCategoryValue = 0;
  bool isLoading = true;

  final skyBlue = Colors.lightBlue[400];
  final lightBlue = Colors.lightBlue[100];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future _loadItems() async {
    setState(() => isLoading = true);
    final res = await db.getItemsByCategory(widget.category.id!);
    double total = 0;
    for (var it in res) {
      // ✅ Purchase Price * Quantity
      total += it.purchasePrice * it.quantity;
    }

    setState(() {
      items = res;
      totalCategoryValue = total;
      isLoading = false;
    });
  }

  void _goAddItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(categoryId: widget.category.id!),
      ),
    ).then((_) => _loadItems());
  }

  void _deleteItem(int id) async {
    await db.deleteItem(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: skyBlue,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 2,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: skyBlue))
          : Column(
              children: [
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Category Total Value: Rs. ${totalCategoryValue.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text('No items in this category.',
                              style: TextStyle(color: Colors.black54)))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final it = items[i];
                            // ✅ Purchase Price * Quantity
                            final total = it.purchasePrice * it.quantity;
                            return Card(
                              color: lightBlue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.lightBlue, width: 1)),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(it.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Stock: ${it.quantity}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black)),
                                    Text('Sale Price: Rs. ${it.salePrice}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black)),
                                    Text(
                                        'Purchase Price: Rs. ${it.purchasePrice}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black)),
                                    Text(
                                        'Total Amount: Rs. ${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  onSelected: (v) {
                                    if (v == 'delete') _deleteItem(it.id!);
                                    if (v == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddItemScreen(
                                              categoryId: it.categoryId,
                                              item: it),
                                        ),
                                      ).then((_) => _loadItems());
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        child: Text('Edit',
                                            style: TextStyle(
                                                color: Colors.black)),
                                        value: 'edit'),
                                    PopupMenuItem(
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color: Colors.black)),
                                        value: 'delete'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightBlue,
        onPressed: _goAddItem,
        child: Icon(Icons.inventory_2,
            color: Colors.black),
        tooltip: 'Add Item',
      ),
    );
  }
}
