import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _db;
  Timer? _updateTimer;

  DatabaseHelper._internal() {
    _startAutoUpdate();
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "vendomed.db");

    // Always copy the vendomed.db from assets to the device
    await Directory(dirname(path)).create(recursive: true);
    ByteData data = await rootBundle.load("assets/vendomed.db");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);

    try {
      final database = await openDatabase(path, version: 1, onCreate: _onCreate);
      print("Database connected: vendomed.db located at: $path");
      return database;
    } catch (error) {
      print("Failed to connect to database at: $path. Error: $error");
      rethrow;
    }
  }

  // Updated onCreate with IF NOT EXISTS so that it won't error if the table exists
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price NUMERIC NOT NULL,
        total_amount NUMERIC NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL CHECK (payment_method IN ('GCash', 'Cash/Coins')),
        user_type TEXT NOT NULL CHECK (user_type IN ('RFID User', 'Guest'))
      )
    ''');
  }

  void _startAutoUpdate() {
    _updateTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _refreshDatabase();
    });
  }

  Future<void> _refreshDatabase() async {
    _db?.close();
    _db = await _initDb();
    print("Database refreshed");
  }

  // Inserts a transaction row into the transactions table.
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    return await database.insert("transactions", transaction);
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
