import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'medicine_menu.dart';
import 'confirmation_screen.dart';

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
        final String currentCountString =
            results.first['count']?.toString() ?? "0";
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

  /// Calculates the total amount (in PHP) from the orders.
  double _calculateTotalAmount() {
    double total = 0.0;
    for (var order in orders) {
      double price = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      total += price;
    }
    return total;
  }

  /// Called when the "PROCEED" button is pressed.
  /// Inserts transactions, updates stocks, then navigates to SplashScreen.
  Future<void> _onProceedPayment(BuildContext context) async {
    await _insertTransactions();
    await _updateStocksForOrders();
    // Pass the required parameters to ConfirmationScreen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          orders:           orders,
          totalPrice:       _calculateTotalAmount(),
          isRegisteredUser: true,       // GCash users must be registered
          paymentMethod:    'GCash',    // or however you want to label it
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = _calculateTotalAmount();

    return WillPopScope(
      // Prevent default back navigation.
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7EAF0),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'GCASH Payment',
            style: TextStyle(color: Colors.white),
          ),
          // Override the back arrow to navigate back to MedicineMenu.
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container for YOUR ORDERS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "YOUR ORDER/S:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var order in orders) ...[
                      Text(
                        "${order['name']} (Qty: ${order['quantity']}) - ₱${order['price']}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Container for TOTAL AMOUNT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL AMOUNT:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₱${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
              // Centered instruction text with bigger font
              Center(
                child: Text(
                  "Scan the QR Code with your GCash app to proceed with payment.",
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // Static QR Code (centered, larger size)
              Center(
                child: Image.asset(
                  'assets/images/qrcode.png',
                  width: 500,
                  height: 500,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              // Row of CANCEL and PROCEED buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // CANCEL button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      // If user cancels, go back to MedicineMenu
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
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  // PROCEED button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () async {
                      await _onProceedPayment(context);
                    },
                    child: const Text(
                      "PROCEED",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
