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

  // A broadcast StreamController to notify listeners when transactions update.
  final StreamController<List<Map<String, dynamic>>> _transactionStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  DatabaseHelper._internal();

  // Getter to obtain the database instance. Initializes the database if necessary.
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Expose the transactions stream so UI widgets can listen for updates.
  Stream<List<Map<String, dynamic>>> get transactionStream =>
      _transactionStreamController.stream;

  // Initialize the database by copying from assets and opening the database.
  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "vendomed.db");

    // Create the directory if it doesn't exist.
    await Directory(dirname(path)).create(recursive: true);

    // Copy the database from assets to the local path (overwrites any existing DB).
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

  // Copy vendomed.db from the assets folder to the specified local path.
  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load("assets/vendomed.db");
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  // Called when the database is created for the first time.
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

  // Private helper method to update the transactions stream.
  Future<void> _updateTransactionStream() async {
    final transactions = await getTransactions();
    _transactionStreamController.add(transactions);
  }

  // ========== TRANSACTIONS TABLE METHODS ==========

  // Inserts a transaction record and updates the stream.
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    int id = await database.insert("transactions", transaction);
    print("Inserted transaction id: $id");
    await _updateTransactionStream();
    return id;
  }

  // Retrieves all transaction records.
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final database = await db;
    return await database.query("transactions");
  }

  // Utility method for debugging: prints out all current transactions.
  Future<void> debugPrintTransactions() async {
    final dbInstance = await db;
    List<Map<String, dynamic>> results = await dbInstance.query("transactions");
    print("Current transactions: $results");
  }

  // ========== USERS TABLE METHODS ==========

  // Retrieves all users.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final database = await db;
    return await database.query('users');
  }

  // Inserts a new user record into the users table.
  Future<int> insertUser(Map<String, dynamic> userData) async {
    final database = await db;
    return await database.insert('users', userData);
  }

  // Updates an existing user record.
  Future<int> updateUser(Map<String, dynamic> userData, int userId) async {
    final database = await db;
    return await database.update(
      'users',
      userData,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Deletes a user record.
  Future<int> deleteUser(int userId) async {
    final database = await db;
    return await database.delete(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ========== CLOSE DB ==========

  // Call this method to properly close the database connection and stream when done.
  void dispose() {
    _db?.close();
    _transactionStreamController.close();
  }
}
