import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/sale.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'stock_sales.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER,
        name TEXT,
        quantity INTEGER,
        purchasePrice REAL,
        salePrice REAL,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER,
        shopkeeperName TEXT,
        quantity INTEGER,
        date TEXT,
        FOREIGN KEY(itemId) REFERENCES items(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopkeeperName TEXT,
        amount REAL,
        status TEXT,
        date TEXT
      )
    ''');
  }

  // ---------------- Categories ----------------
  Future<int> insertCategory(Category c) async {
    final dbClient = await database;
    return await dbClient.insert('categories', c.toMap());
  }

  Future<List<Category>> getCategories() async {
    final dbClient = await database;
    final res = await dbClient.query('categories', orderBy: 'name');
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final dbClient = await database;
    return await dbClient.delete('categories', where: 'id=?', whereArgs: [id]);
  }

  // ---------------- Items ----------------
  Future<int> insertItem(Item item) async {
    final dbClient = await database;
    return await dbClient.insert('items', item.toMap());
  }

  Future<List<Item>> getItemsByCategory(int categoryId) async {
    final dbClient = await database;
    final res = await dbClient.query(
      'items',
      where: 'categoryId=?',
      whereArgs: [categoryId],
      orderBy: 'name',
    );
    return res.map((m) => Item.fromMap(m)).toList();
  }

  Future<Item?> getItemById(int id) async {
    final dbClient = await database;
    final res = await dbClient.query(
      "items",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return Item.fromMap(res.first);
    }
    return null;
  }

  Future<int> updateItem(Item item) async {
    final dbClient = await database;
    return await dbClient.update(
      'items',
      item.toMap(),
      where: 'id=?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final dbClient = await database;
    return await dbClient.delete('items', where: 'id=?', whereArgs: [id]);
  }

  // ---------------- Sales ----------------
  Future<void> insertSaleAndReduceStock(Sale sale) async {
    final dbClient = await database;
    await dbClient.transaction((txn) async {
      // insert sale
      await txn.insert('sales', sale.toMap());

      // get item
      final items =
          await txn.query('items', where: 'id=?', whereArgs: [sale.itemId], limit: 1);
      if (items.isEmpty) throw Exception('Item not found');

      final currentQty = items.first['quantity'] as int;
      final newQty = currentQty - sale.quantity;
      if (newQty < 0) throw Exception('Not enough stock');

      await txn.update(
        'items',
        {'quantity': newQty},
        where: 'id=?',
        whereArgs: [sale.itemId],
      );
    });
  }

  Future<List<Sale>> getAllSales() async {
    final dbClient = await database;
    final res = await dbClient.query('sales', orderBy: 'date DESC');
    return res.map((m) => Sale.fromMap(m)).toList();
  }

  // ✅ Update Sale + adjust stock
  Future<void> updateSaleAndStock(Sale sale,
      {required int oldQty, required int newQty}) async {
    final dbClient = await database;

    await dbClient.transaction((txn) async {
      // Update sale qty
      await txn.update(
        'sales',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [sale.id],
      );

      // Stock adjust
      final diff = oldQty - newQty;
      if (diff != 0) {
        await txn.rawUpdate(
          'UPDATE items SET quantity = quantity + ? WHERE id = ?',
          [diff, sale.itemId],
        );
      }
    });
  }

  // ✅ Delete sale + restore stock
  Future<void> deleteSaleAndRestoreStock(
      {required int saleId, required int itemId, required int qty}) async {
    final dbClient = await database;

    await dbClient.transaction((txn) async {
      // Delete sale
      await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);

      // Restore stock
      await txn.rawUpdate(
        'UPDATE items SET quantity = quantity + ? WHERE id = ?',
        [qty, itemId],
      );
    });
  }

  // ---------------- Payments ----------------
  Future<int> insertPayment(String shopkeeper, double amount, String status,
      {String? date}) async {
    final dbClient = await database;
    return await dbClient.insert('payments', {
      'shopkeeperName': shopkeeper,
      'amount': amount,
      'status': status,
      'date': date ?? DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentsByShopkeeper(
      String shopkeeper) async {
    final dbClient = await database;
    final res = await dbClient.query(
      'payments',
      where: 'shopkeeperName = ?',
      whereArgs: [shopkeeper],
      orderBy: 'date ASC',
    );
    return res;
  }

  Future<int> updatePaymentStatus(
      int id, double amount, String status, {String? date}) async {
    final dbClient = await database;
    return await dbClient.update(
      'payments',
      {
        'amount': amount,
        'status': status,
        'date': date ?? DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePayment(int id) async {
    final dbClient = await database;
    return await dbClient.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Extra Queries (JOINs) ----------------

  // ✅ Get all sales with JOIN (category + item name included)
  Future<List<Map<String, dynamic>>> getSalesWithDetails() async {
    final dbClient = await database;
    final res = await dbClient.rawQuery('''
      SELECT 
        s.id AS saleId,
        s.itemId,
        s.shopkeeperName,
        s.quantity,
        s.date,
        i.name AS itemName,
        i.salePrice,
        i.purchasePrice,
        c.name AS categoryName
      FROM sales s
      JOIN items i ON s.itemId = i.id
      JOIN categories c ON i.categoryId = c.id
      ORDER BY s.date DESC
    ''');
    return res;
  }

  // ✅ Get sales by shopkeeper (for detail screen)
  Future<List<Map<String, dynamic>>> getSalesByShopkeeper(String shopkeeper) async {
    final dbClient = await database;
    final res = await dbClient.rawQuery('''
      SELECT 
        s.id AS saleId,
        s.itemId,
        s.shopkeeperName,
        s.quantity,
        s.date,
        i.name AS itemName,
        i.salePrice,
        i.purchasePrice,
        c.name AS categoryName
      FROM sales s
      JOIN items i ON s.itemId = i.id
      JOIN categories c ON i.categoryId = c.id
      WHERE s.shopkeeperName = ?
      ORDER BY s.date DESC
    ''', [shopkeeper]);
    return res;
  }

  // ✅ Update Sale Price (fix)
  Future<int> updateSalePrice(int itemId, double newPrice) async {
    final dbClient = await database;
    return await dbClient.update(
      'items',
      {'salePrice': newPrice},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future close() async {
    final dbClient = await database;
    dbClient.close();
  }
}
