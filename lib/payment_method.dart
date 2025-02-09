// payment_method.dart

import 'package:flutter/material.dart';
import 'gcash.dart';
import 'payment.dart'; // Your existing payment page for Bill Acceptor / Coin Slot

/// A custom widget for a square payment option button.
/// This design is similar to the medicine item layout.
class PaymentOptionButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const PaymentOptionButton({
    Key? key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set a fixed image height that fits comfortably inside the container.
    const double imageHeight = 350.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 330, // Increased width for a larger button
        height: 450, // Increased height for a square button
        decoration: BoxDecoration(
          // Changed background color to cream instead of white.
          color: const Color(0xFFF2F2E8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(3, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the payment method image.
            Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
            // Payment method label.
            Text(
              label,
              style: const TextStyle(
                fontSize: 30, // Increased font size for readability
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodPage extends StatelessWidget {
  final List<Map<String, String>> orders;
  final String rfidData;

  const PaymentMethodPage({
    Key? key,
    required this.orders,
    required this.rfidData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
        title: const Text(
          "Select Payment Method",
          style: TextStyle(color: Colors.white), // White title text
        ),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000), // Limit width for tablets
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const SizedBox(height: 90),
                  const Text(
                    "WHICH PAYMENT WOULD YOU LIKE TO PROCEED FOR YOUR ORDER?",
                    style: TextStyle(
                      fontSize: 35, // Larger prompt text for better readability
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 150),
                  // Row containing the two square payment options.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaymentOptionButton(
                        imagePath: 'assets/images/gcashlogo.png', // Your GCash image asset
                        label: 'GCash',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GCashPaymentPage(
                                orders: orders,
                                medicinesToBeDisabled: orders
                                    .map((order) => order['name']!)
                                    .toList(),
                                rfidData: rfidData,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 60), // Increased spacing between the buttons
                      PaymentOptionButton(
                        imagePath: 'assets/images/cashcoins.png', // Your Cash/Coin image asset
                        label: 'Cash/Coins',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                orders: orders,
                                medicinesToBeDisabled: orders
                                    .map((order) => order['name']!)
                                    .toList(),
                                rfidData: rfidData,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                  // Cancel button centered below the payment options.
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
