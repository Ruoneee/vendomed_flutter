import 'package:flutter/material.dart';
import 'payment.dart'; // <-- Make sure this import points to your PaymentPage
import 'medicine_menu.dart';
import 'database_helper.dart';

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
      // Standard AppBar, if desired
      appBar: AppBar(
        title: const Text('Choose Payment Method'),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      backgroundColor: const Color(0xFFF7EAF0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            const Text(
              'Select a Payment Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Two options: Cash, Redeem Points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cash Payment
                InkWell(
                  onTap: () {
                    // Navigate to PaymentPage with Cash
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          orders: orders,
                          rfidData: rfidData,
                          medicinesToBeDisabled: const [],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/cash.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cash',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                // Redeem Points (replacing GCash)
                InkWell(
                  onTap: () {
                    // TODO: Implement redeem-points logic here
                    // For example, you might navigate to PaymentPage with a parameter
                    // indicating “Points” as the chosen payment method, or a dedicated
                    // points redemption screen, etc.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          orders: orders,
                          rfidData: rfidData,
                          medicinesToBeDisabled: const [],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Replace with your own "Redeem Points" image
                      Image.asset(
                        'assets/images/points.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Redeem Points',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
