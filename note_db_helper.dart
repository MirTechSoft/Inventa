import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NoteDBHelper {
  static final NoteDBHelper _instance = NoteDBHelper._internal();
  factory NoteDBHelper() => _instance;
  NoteDBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), "notes.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertNote(String content) async {
    final db = await database;
    return await db.insert("notes", {"content": content});
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return await db.query("notes", orderBy: "id DESC");
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete("notes", where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateNote(int id, String content) async {
    final db = await database;
    return await db.update(
      "notes",
      {"content": content},
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
