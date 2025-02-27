import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
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

    // Copy the database from assets only if it does not exist.
    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load("assets/vendomed.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      print("Database copied from assets");
    } else {
      print("Database already exists at: $path");
    }

    try {
      // Open the database with version 2.
      final database = await openDatabase(
        path,
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
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
            print("Transactions table created via onUpgrade");
          }
        },
        onCreate: _onCreate,
      );
      print("Database connected: vendomed.db located at: $path");
      return database;
    } catch (error) {
      print("Failed to connect to database at: $path. Error: $error");
      rethrow;
    }
  }

  // Called when the database is first created.
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
    print("Transactions table created in onCreate");
  }

  // Inserts a transaction row into the transactions table.
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    int id = await database.insert("transactions", transaction);
    print("Inserted transaction id: $id");
    return id;
  }

  // Debug function to query and print all transactions.
  Future<void> debugPrintTransactions() async {
    final dbInstance = await db;
    List<Map<String, dynamic>> results = await dbInstance.query("transactions");
    print("Current transactions: $results");
  }

  // Call this when you want to close the database.
  void dispose() {
    _db?.close();
  }
}
