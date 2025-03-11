// database_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "vendomed.db");

    // Create the directory if it doesn't exist.
    await Directory(dirname(path)).create(recursive: true);

    // Always copy the database from assets (this will overwrite any existing local DB).
    await _copyDatabaseFromAssets(path);
    print("Database copied from assets to: $path");

    try {
      // Open the database.
      final database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      print("Database connected: vendomed.db located at: $path");
      return database;
    } catch (error) {
      print("Failed to connect to database at: $path. Error: $error");
      rethrow;
    }
  }

  // Copy vendomed.db from assets to the specified path.
  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load("assets/vendomed.db");
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  // Called only if the database is newly created.
  Future _onCreate(Database db, int version) async {
    // Create the transactions table if needed.
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
    print("Transactions table created in onCreate");

    // Create the users table if it doesn't exist.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        rfid TEXT,
        name TEXT,
        email TEXT,
        expiration TEXT,
        points TEXT
      )
    ''');
    print("Users table created in onCreate");
  }

  // ========== TRANSACTIONS TABLE METHODS ==========

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    int id = await database.insert("transactions", transaction);
    print("Inserted transaction id: $id");
    return id;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final database = await db;
    return await database.query("transactions");
  }

  Future<void> debugPrintTransactions() async {
    final dbInstance = await db;
    List<Map<String, dynamic>> results = await dbInstance.query("transactions");
    print("Current transactions: $results");
  }

  // ========== USERS TABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final database = await db;
    return await database.query('users');
  }

  Future<int> insertUser(Map<String, dynamic> userData) async {
    final database = await db;
    return await database.insert('users', userData);
  }

  Future<int> updateUser(Map<String, dynamic> userData, int userId) async {
    final database = await db;
    return await database.update(
      'users',
      userData,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int userId) async {
    final database = await db;
    return await database.delete(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ========== CLOSE DB ==========

  void dispose() {
    _db?.close();
  }
}
