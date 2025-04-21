import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  static Database? _db;

  final StreamController<List<Map<String, dynamic>>> _transactionStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  DatabaseHelper._internal();

  /// Opens the DB at version 4, running any needed migrations.
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

    // Ensure folder exists
    await Directory(dirname(path)).create(recursive: true);

    // Copy from assets on first run
    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
      print("Database copied from assets to: $path");
    }

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load("assets/vendomed.db");
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  /// Creates all tables fresh (including user_rfid on transactions).
  Future _onCreate(Database db, int version) async {
    // TRANSACTIONS table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_rfid      TEXT    NOT NULL,
        medicine       TEXT    NOT NULL,
        quantity       INTEGER NOT NULL,
        unit_price     NUMERIC NOT NULL,
        total_amount   NUMERIC NOT NULL,
        date           TEXT    NOT NULL,
        payment_method TEXT    NOT NULL CHECK (payment_method IN ('GCash', 'Cash/Coins')),
        user_type      TEXT    NOT NULL CHECK (user_type IN ('RFID User', 'Guest'))
      )
    ''');

    // USERS table
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

    // STOCKS table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        BATCH_ID     INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT,
        product_id   TEXT,
        amount       TEXT,
        status       TEXT,
        count        TEXT
      )
    ''');

    // BATCH_EXPIRY table
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

  /// Migrates v1–v3 → v4 by adding `user_rfid` if it’s missing.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: ensure batch_expiry exists
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
      // v3: original code added an `rfid` column—not used anymore
      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN rfid TEXT DEFAULT ''
      ''');
      print("Upgraded to v3: legacy rfid column added");
    }

    if (oldVersion < 4) {
      // v4: add our `user_rfid` column
      await db.execute('''
        ALTER TABLE transactions
        ADD COLUMN user_rfid TEXT DEFAULT ''
      ''');
      print("Upgraded to v4: user_rfid column added");
    }
  }

  Future<void> _updateTransactionStream() async {
    final transactions = await getTransactions();
    _transactionStreamController.add(transactions);
  }

  // ========== TRANSACTIONS ==========

  /// Inserts into the `transactions` table.
  /// Make sure your map uses the key `user_rfid`, not `rfid`.
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final database = await db;
    final id = await database.insert("transactions", transaction);
    await _updateTransactionStream();
    return id;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    return (await db).query("transactions");
  }

  /// Returns per‑medicine totals for a given RFID & date (YYYY‑MM‑DD).
  Future<Map<String, int>> getDailyPurchaseCounts({
    required String rfid,
    required String date,
  }) async {
    final database = await db;
    final rows = await database.rawQuery('''
    SELECT
      medicine,
      SUM(quantity) AS totalQty
    FROM transactions
    WHERE user_rfid = ?            -- changed to user_rfid
      AND date(date) = ?
    GROUP BY medicine
  ''', [rfid, date]);

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


  // ========== USERS ==========

  Future<List<Map<String, dynamic>>> getAllUsers() async =>
      (await db).query('users');
  Future<int> insertUser(Map<String, dynamic> u) async =>
      (await db).insert('users', u);
  Future<int> updateUser(Map<String, dynamic> u, int id) async =>
      (await db).update('users', u, where: 'user_id = ?', whereArgs: [id]);
  Future<int> deleteUser(int id) async =>
      (await db).delete('users', where: 'user_id = ?', whereArgs: [id]);
  Future<int> updateUserByRFID(Map<String, dynamic> u, String r) async =>
      (await db).update('users', u, where: 'rfid = ?', whereArgs: [r]);
  Future<int> deleteUserByRFID(String r) async =>
      (await db).delete('users', where: 'rfid = ?', whereArgs: [r]);

  // ========== STOCKS & BATCH_EXPIRY ==========

  Future<List<Map<String, dynamic>>> getAllStocks() async =>
      (await db).query('stocks');
  Future<int> insertStock(Map<String, dynamic> s) async =>
      (await db).insert('stocks', s);
  Future<int> updateStockByBatchId(Map<String, dynamic> s, int id) async =>
      (await db)
          .update('stocks', s, where: 'BATCH_ID = ?', whereArgs: [id]);
  Future<int> updateStock(Map<String, dynamic> s, String name) async =>
      (await db)
          .update('stocks', s, where: 'product_name = ?', whereArgs: [name]);
  Future<int> deleteStock(String name) async =>
      (await db)
          .delete('stocks', where: 'product_name = ?', whereArgs: [name]);

  Future<int> insertBatchExpiry(Map<String, dynamic> d) async =>
      (await db).insert('batch_expiry', d);
  Future<List<Map<String, dynamic>>> getAllBatchExpiry() async =>
      (await db).query('batch_expiry');
  Future<List<Map<String, dynamic>>> getBatchExpiryByBatchId(int id) async =>
      (await db)
          .query('batch_expiry', where: 'batch_id = ?', whereArgs: [id]);
  Future<int> updateBatchExpiry(int id, Map<String, dynamic> d) async =>
      (await db).update('batch_expiry', d,
          where: 'batch_expiry_id = ?', whereArgs: [id]);
  Future<int> deleteBatchExpiry(int id) async =>
      (await db).delete('batch_expiry',
          where: 'batch_expiry_id = ?', whereArgs: [id]);

  // ========== UTILITY ==========

  Future<int> getRowCount(String tableName) async {
    final result =
    await (await db).rawQuery('SELECT COUNT(*) AS count FROM $tableName');
    return result.first['count'] is int
        ? result.first['count'] as int
        : int.tryParse(result.first['count'].toString()) ?? 0;
  }

  void dispose() {
    _db?.close();
    _transactionStreamController.close();
  }
}
