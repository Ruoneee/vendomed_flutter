// gcash.dart

import 'package:flutter/material.dart';
import 'payment_method.dart'; // Ensure this import is correct

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
      // Intercept back navigation.
      onWillPop: () async {
        // Navigate back to PaymentMethodPage without clearing the orders.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodPage(
              orders: orders,
              rfidData: rfidData,
            ),
          ),
        );
        // Returning false prevents the default pop.
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          // Set the arrow (back icon) color to white.
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "GCash Payment",
            style: TextStyle(color: Colors.white), // Force title text to white
          ),
          backgroundColor: const Color(0xFF0D2A5E),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Please scan the GCash QR Code to complete payment.",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Display the QR code image.
                Image.asset(
                  'assets/images/qrcode.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // When payment is completed, navigate back to PaymentMethodPage without clearing orders.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentMethodPage(
                          orders: orders,
                          rfidData: rfidData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: const Text(
                    "Payment Completed",
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
