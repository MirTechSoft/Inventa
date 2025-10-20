import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'shop.db');
    return await openDatabase(
      path,
      version: 3, // ✅ version 3 tak upgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sales table
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopkeeperName TEXT,
        itemId INTEGER,
        quantity INTEGER,
        amount REAL,
        date TEXT
      )
    ''');

    // Payments table (✅ profit + message column add kiya)
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopkeeperName TEXT,
        amount REAL,
        profit REAL,
        status TEXT,
        date TEXT,
        message TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE payments ADD COLUMN profit REAL;");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE payments ADD COLUMN message TEXT;");
    }
  }

  // ------------------- Payments -------------------
  Future<int> insertPayment(
    String shopkeeper,
    double amount,
    String status, {
    required String date,
    required double profit,
    String? message,
  }) async {
    final dbClient = await database;
    return await dbClient.insert(
      'payments',
      {
        'shopkeeperName': shopkeeper,
        'amount': amount,
        'profit': profit,
        'status': status,
        'date': date,
        'message': message ?? "",
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      int id, double amount, String status, String date,
      {required double profit, String? message}) async {
    final dbClient = await database;
    return await dbClient.update(
      'payments',
      {
        'amount': amount,
        'profit': profit,
        'status': status,
        'date': date,
        'message': message ?? "",
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ NEW: Update only message field
  Future<int> updatePaymentMessage(int id, String message) async {
    final dbClient = await database;
    return await dbClient.update(
      'payments',
      {
        'message': message,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePayment(int id) async {
    final dbClient = await database;
    return await dbClient.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Sales -------------------
  Future<int> insertSale(
      String shopkeeper, int itemId, int quantity, double amount, String date) async {
    final dbClient = await database;
    return await dbClient.insert(
      'sales',
      {
        'shopkeeperName': shopkeeper,
        'itemId': itemId,
        'quantity': quantity,
        'amount': amount,
        'date': date,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByShopkeeper(
      String shopkeeper) async {
    final dbClient = await database;
    final res = await dbClient.query(
      'sales',
      where: 'shopkeeperName = ?',
      whereArgs: [shopkeeper],
    );
    return res;
  }

  Future<void> deleteSaleAndRestoreStock(
      {required int saleId, required int itemId, required int qty}) async {
    final dbClient = await database;
    await dbClient.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  Future close() async {
    final dbClient = await database;
    dbClient.close();
  }
}
