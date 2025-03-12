import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_method.dart';
import 'thankyou_screen.dart';
import 'database_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ...
        return false;
      },
      child: Scaffold(
        // ...
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              // ...
              children: [
                // ...
                ElevatedButton(
                  onPressed: () async {
                    // Determine user type based on RFID data.
                    String userType = (rfidData.isNotEmpty) ? "RFID User" : "Guest";

                    // Insert a transaction row for each order.
                    for (var order in orders) {
                      String medicine = order['name'] ?? "Unknown";
                      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
                      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
                      double unitPrice = (quantity != 0) ? totalCost / quantity : 0.0;

                      // 2) Format the date to match older transactions
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

                    debugPrint("GCashPaymentPage: 'PAYMENT COMPLETED' button pressed. Navigating to ThankYouScreen.");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThankYouScreen(),
                      ),
                    );
                  },
                  // ...
                  child: const Text(
                    "PAYMENT COMPLETED",
                    style: TextStyle(fontSize: 25, color: Colors.white),
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
