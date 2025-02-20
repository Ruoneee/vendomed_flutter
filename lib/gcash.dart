// gcash.dart

import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import the SplashScreen widget

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
      // Intercept back navigation.
      onWillPop: () async {
        // Navigate back to SplashScreen and clear the navigation stack.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
              (Route<dynamic> route) => false,
        );
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
                  "Please Scan GCash QR Code to complete payment.",
                  style: TextStyle(fontSize: 29, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 80),
                // Display the QR code image.
                Image.asset(
                  'assets/images/qrcode.png',
                  height: 400,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 90),
                ElevatedButton(
                  onPressed: () {
                    // When payment is completed, navigate to SplashScreen and clear all routes.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SplashScreen()),
                          (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
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
