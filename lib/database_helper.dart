import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  static Database? _db;

  // Broadcast stream for transactions.
  final StreamController<List<Map<String, dynamic>>> _transactionStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  DatabaseHelper._internal();

  /// Returns the initialized [Database], bumping version to 3.
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Stream<List<Map<String, dynamic>>> get transactionStream =>
      _transactionStreamController.stream;

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "vendomed.db");

    // Ensure directory exists
    await Directory(dirname(path)).create(recursive: true);

    // Copy from assets if first run
    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
      print("Database copied from assets to: $path");
    }

    // Open with version 3
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load("assets/vendomed.db");
    List<int> bytes = data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  /// Create all tables at version 3 schema
  Future _onCreate(Database db, int version) async {
    // ---- TRANSACTIONS ----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        transaction_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        rfid             TEXT    NOT NULL,
        medicine         TEXT    NOT NULL,
        quantity         INTEGER NOT NULL,
        unit_price       NUMERIC NOT NULL,
        total_amount     NUMERIC NOT NULL,
        date             TEXT    NOT NULL,
        payment_method   TEXT    NOT NULL CHECK (payment_method IN ('GCash', 'Cash/Coins')),
        user_type        TEXT    NOT NULL CHECK (user_type    IN ('RFID User', 'Guest'))
      )
    ''');

    // ---- USERS ----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        rfid       TEXT,
        name       TEXT,
        email      TEXT,
        expiration TEXT,
        points     TEXT
      )
    ''');

    // ---- STOCKS ----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        BATCH_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name  TEXT,
        product_id    TEXT,
        amount        TEXT,
        status        TEXT,
        count         TEXT
      )
    ''');

    // ---- BATCH_EXPIRY ----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS batch_expiry (
        batch_expiry_id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id        INTEGER NOT NULL,
        expiration_date TEXT    NOT NULL,
        supplier        TEXT    NOT NULL,
        date_received   TEXT    NOT NULL,
        FOREIGN KEY(batch_id) REFERENCES stocks(BATCH_ID)
      )
    ''');

    print("Database created with version $version");
  }

  /// Migrate from older versions up to v3
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // create batch_expiry if missing (v2 upgrade)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS batch_expiry (
          batch_expiry_id INTEGER PRIMARY KEY AUTOINCREMENT,
          batch_id        INTEGER NOT NULL,
          expiration_date TEXT    NOT NULL,
          supplier        TEXT    NOT NULL,
          date_received   TEXT    NOT NULL,
          FOREIGN KEY(batch_id) REFERENCES stocks(BATCH_ID)
        )
      ''');
      print("Upgraded to v2: batch_expiry created");
    }

    if (oldVersion < 3) {
      // add rfid column to transactions (v3 upgrade)
      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN rfid TEXT DEFAULT ''
      ''');
      print("Upgraded to v3: rfid column added to transactions");
    }
  }

  Future<void> _updateTransactionStream() async {
    final transactions = await getTransactions();
    _transactionStreamController.add(transactions);
  }

  // ========== TRANSACTIONS TABLE METHODS ==========

  /// Inserts a transaction record. Make sure your `transaction` map
  /// includes keys: rfid, medicine, quantity, unit_price, total_amount, date, payment_method, user_type.
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    final id = await database.insert("transactions", transaction);
    await _updateTransactionStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final database = await db;
    return database.query("transactions");
  }

  /// Returns a map of medicine → totalQty for a given RFID & date (YYYY‑MM‑DD).
  Future<Map<String, int>> getDailyPurchaseCounts({
    required String rfid,
    required String date, // in 'YYYY-MM-DD' format
  }) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''
      SELECT medicine, SUM(quantity) AS totalQty
      FROM transactions
      WHERE rfid = ?
        AND date(date) = ?
      GROUP BY medicine
      ''',
      [rfid, date],
    );

    // Convert to Map<String,int>
    final result = <String, int>{};
    for (var row in rows) {
      final name = row['medicine'] as String;
      final qty = row['totalQty'] is int
          ? row['totalQty'] as int
          : int.tryParse(row['totalQty'].toString()) ?? 0;
      result[name] = qty;
    }
    return result;
  }

  // ========== USERS TABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final database = await db;
    return database.query('users');
  }

  Future<int> insertUser(Map<String, dynamic> userData) async {
    final database = await db;
    return database.insert('users', userData);
  }

  Future<int> updateUser(Map<String, dynamic> userData, int userId) async {
    final database = await db;
    return database.update('users', userData,
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> deleteUser(int userId) async {
    final database = await db;
    return database
        .delete('users', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> updateUserByRFID(
      Map<String, dynamic> userData, String rfid) async =>
      (await db).update('users', userData,
          where: 'rfid = ?', whereArgs: [rfid]);

  Future<int> deleteUserByRFID(String rfid) async =>
      (await db).delete('users', where: 'rfid = ?', whereArgs: [rfid]);

  // ========== STOCKS TABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getAllStocks() async =>
      (await db).query('stocks');

  Future<int> insertStock(Map<String, dynamic> stockData) async =>
      (await db).insert('stocks', stockData);

  Future<int> updateStockByBatchId(
      Map<String, dynamic> stockData, int batchId) async =>
      (await db).update('stocks', stockData,
          where: 'BATCH_ID = ?', whereArgs: [batchId]);

  Future<int> updateStock(
      Map<String, dynamic> stockData, String productName) async =>
      (await db).update('stocks', stockData,
          where: 'product_name = ?', whereArgs: [productName]);

  Future<int> deleteStock(String productName) async =>
      (await db).delete('stocks',
          where: 'product_name = ?', whereArgs: [productName]);

  // ========== BATCH_EXPIRY TABLE METHODS ==========

  Future<int> insertBatchExpiry(Map<String, dynamic> data) async =>
      (await db).insert('batch_expiry', data);

  Future<List<Map<String, dynamic>>> getAllBatchExpiry() async =>
      (await db).query('batch_expiry');

  Future<List<Map<String, dynamic>>> getBatchExpiryByBatchId(
      int batchId) async =>
      (await db).query('batch_expiry',
          where: 'batch_id = ?', whereArgs: [batchId]);

  Future<int> updateBatchExpiry(
      int batchExpiryId, Map<String, dynamic> data) async =>
      (await db).update('batch_expiry', data,
          where: 'batch_expiry_id = ?', whereArgs: [batchExpiryId]);

  Future<int> deleteBatchExpiry(int batchExpiryId) async =>
      (await db).delete('batch_expiry',
          where: 'batch_expiry_id = ?', whereArgs: [batchExpiryId]);

  // ========== UTILITY ==========

  Future<int> getRowCount(String tableName) async {
    final database = await db;
    final result =
    await database.rawQuery('SELECT COUNT(*) AS count FROM $tableName');
    return result.first['count'] is int
        ? result.first['count'] as int
        : int.tryParse(result.first['count'].toString()) ?? 0;
  }

  void dispose() {
    _db?.close();
    _transactionStreamController.close();
  }
}
