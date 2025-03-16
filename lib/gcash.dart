import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'splash_screen.dart';
import 'medicine_menu.dart';

class GCashPaymentPage extends StatelessWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;

  const GCashPaymentPage({
    Key? key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  }) : super(key: key);

  /// Inserts transactions into the database with payment_method 'GCash'.
  Future<void> _insertTransactions() async {
    String userType = (rfidData.isNotEmpty) ? "RFID User" : "Guest";

    for (var order in orders) {
      String medicine = order['name'] ?? "Unknown";
      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      double unitPrice = (quantity != 0) ? totalCost / quantity : 0.0;
      String date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      Map<String, dynamic> transaction = {
        'medicine': medicine,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_amount': totalCost,
        'date': date,
        'payment_method': 'GCash',
        'user_type': userType,
      };

      await DatabaseHelper.instance.insertTransaction(transaction);
    }
  }

  /// Updates the stock for each ordered medicine by subtracting the quantity ordered.
  Future<void> _updateStocksForOrders() async {
    for (var order in orders) {
      final String productName = order['name'] ?? "";
      final int quantityOrdered = int.tryParse(order['quantity'] ?? "1") ?? 1;
      final db = await DatabaseHelper.instance.db;
      // Query current stock for the product.
      final results = await db.query(
        'stocks',
        where: 'product_name = ?',
        whereArgs: [productName],
      );
      if (results.isNotEmpty) {
        final String currentCountString = results.first['count']?.toString() ?? "0";
        final int currentCount = int.tryParse(currentCountString) ?? 0;
        final int newCount = currentCount - quantityOrdered;
        final int finalCount = newCount < 0 ? 0 : newCount;
        final Map<String, dynamic> updatedData = {
          'count': finalCount.toString(),
        };
        await DatabaseHelper.instance.updateStock(updatedData, productName);
      }
    }
  }

  /// Called when the "PAYMENT COMPLETED" button is pressed.
  Future<void> _onPaymentCompleted(BuildContext context) async {
    await _insertTransactions();
    await _updateStocksForOrders(); // Deduct ordered quantities from stocks
    // Navigate to the splash screen after payment.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent default back navigation via the device's back button.
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'GCASH Payment',
            style: TextStyle(color: Colors.white),
          ),
          // Override the back arrow to navigate back to MedicineMenu with existing orders.
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineMenu(
                    rfidData: rfidData,
                    existingOrders: orders,
                  ),
                ),
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFF7EAF0),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () async {
                    await _onPaymentCompleted(context);
                  },
                  child: const Text(
                    "PAYMENT COMPLETED",
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
