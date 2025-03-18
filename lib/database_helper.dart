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

  // Initialize the database by checking if it exists; if not, copy from assets and then open.
  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "vendomed.db");

    // Create the directory if it doesn't exist.
    await Directory(dirname(path)).create(recursive: true);

    final dbFile = File(path);
    if (!await dbFile.exists()) {
      await _copyDatabaseFromAssets(path);
      print("Database copied from assets to: $path");
    } else {
      print("Database already exists at: $path");
    }

    try {
      // Bump version to 2 so that _onUpgrade is triggered if needed
      final database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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

    // Create the stocks table.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        BATCH_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT,
        product_id TEXT,
        amount TEXT,
        status TEXT,
        count TEXT
      )
    ''');
    print("Stocks table created in onCreate");

    // Create the batch_expiry table if it doesn't exist.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS batch_expiry (
        batch_expiry_id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        expiration_date TEXT NOT NULL,
        supplier TEXT NOT NULL,
        date_received TEXT NOT NULL,
        FOREIGN KEY(batch_id) REFERENCES stocks(BATCH_ID)
      )
    ''');
    print("batch_expiry table created in onCreate");
  }

  // Called when the database version is upgraded (e.g., from 1 to 2).
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create batch_expiry table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS batch_expiry (
          batch_expiry_id INTEGER PRIMARY KEY AUTOINCREMENT,
          batch_id INTEGER NOT NULL,
          expiration_date TEXT NOT NULL,
          supplier TEXT NOT NULL,
          date_received TEXT NOT NULL,
          FOREIGN KEY(batch_id) REFERENCES stocks(BATCH_ID)
        )
      ''');
      print("batch_expiry table created in onUpgrade");
    }
  }

  // Private helper method to update the transactions stream.
  Future<void> _updateTransactionStream() async {
    final transactions = await getTransactions();
    _transactionStreamController.add(transactions);
  }

  // ========== TRANSACTIONS TABLE METHODS ==========

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    int id = await database.insert("transactions", transaction);
    print("Inserted transaction id: $id");
    await _updateTransactionStream();
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

  Future<int> updateUserByRFID(Map<String, dynamic> userData, String rfid) async {
    final database = await db;
    return await database.update(
      'users',
      userData,
      where: 'rfid = ?',
      whereArgs: [rfid],
    );
  }

  Future<int> deleteUserByRFID(String rfid) async {
    final database = await db;
    return await database.delete(
      'users',
      where: 'rfid = ?',
      whereArgs: [rfid],
    );
  }

  // ========== STOCKS TABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getAllStocks() async {
    final database = await db;
    return await database.query('stocks');
  }

  Future<int> insertStock(Map<String, dynamic> stockData) async {
    final database = await db;
    return await database.insert('stocks', stockData);
  }

  // Updates an existing stock record by BATCH_ID.
  Future<int> updateStockByBatchId(Map<String, dynamic> stockData, int batchId) async {
    final database = await db;
    return await database.update(
      'stocks',
      stockData,
      where: 'BATCH_ID = ?',
      whereArgs: [batchId],
    );
  }

  // Alternative update method by product_name if needed.
  Future<int> updateStock(Map<String, dynamic> stockData, String productName) async {
    final database = await db;
    return await database.update(
      'stocks',
      stockData,
      where: 'product_name = ?',
      whereArgs: [productName],
    );
  }

  Future<int> deleteStock(String productName) async {
    final database = await db;
    return await database.delete(
      'stocks',
      where: 'product_name = ?',
      whereArgs: [productName],
    );
  }

  // ========== BATCH_EXPIRY TABLE METHODS ==========

  // Insert a new record into batch_expiry
  Future<int> insertBatchExpiry(Map<String, dynamic> data) async {
    final database = await db;
    return await database.insert('batch_expiry', data);
  }

  // Get all expiry records
  Future<List<Map<String, dynamic>>> getAllBatchExpiry() async {
    final database = await db;
    return await database.query('batch_expiry');
  }

  // Get expiry records by batch_id
  Future<List<Map<String, dynamic>>> getBatchExpiryByBatchId(int batchId) async {
    final database = await db;
    return await database.query(
      'batch_expiry',
      where: 'batch_id = ?',
      whereArgs: [batchId],
    );
  }

  // Update a record by batch_expiry_id
  Future<int> updateBatchExpiry(int batchExpiryId, Map<String, dynamic> data) async {
    final database = await db;
    return await database.update(
      'batch_expiry',
      data,
      where: 'batch_expiry_id = ?',
      whereArgs: [batchExpiryId],
    );
  }

  // Delete a record by batch_expiry_id
  Future<int> deleteBatchExpiry(int batchExpiryId) async {
    final database = await db;
    return await database.delete(
      'batch_expiry',
      where: 'batch_expiry_id = ?',
      whereArgs: [batchExpiryId],
    );
  }

  // ========== CLOSE DB ==========

  void dispose() {
    _db?.close();
    _transactionStreamController.close();
  }
}
