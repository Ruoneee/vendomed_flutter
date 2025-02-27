import 'package:flutter/material.dart';
import 'payment_method.dart';
import 'thankyou_screen.dart';
import 'database_helper.dart';

class GCashPaymentPage extends StatelessWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;

  const GCashPaymentPage({
    super.key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Intercept back navigation
      onWillPop: () async {
        debugPrint("GCashPaymentPage: Device back button or app bar back pressed. Going to PaymentMethodPage.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodPage(
              orders: orders,
              rfidData: rfidData,
            ),
          ),
        );
        return false; // Prevent default pop
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "GCash Payment",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D2A5E),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Please Scan GCash QR Code to complete payment.",
                  style: TextStyle(fontSize: 29, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 80),
                Image.asset(
                  'assets/images/qrcode.png',
                  height: 400,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 90),
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
                      String date = DateTime.now().toIso8601String();

                      Map<String, dynamic> transaction = {
                        'medicine': medicine,
                        'quantity': quantity,
                        'unit_price': unitPrice,
                        'total_amount': totalCost,
                        'date': date,
                        'payment_method': 'GCash',
                        'user_type': userType,
                      };

                      await DatabaseHelper().insertTransaction(transaction);
                    }
                    debugPrint("GCashPaymentPage: 'PAYMENT COMPLETED' button pressed. Navigating to ThankYouScreen.");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThankYouScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 20,
                    ),
                  ),
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
