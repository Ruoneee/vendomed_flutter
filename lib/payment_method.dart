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
      // AppBar with white text and white arrow
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2A5E),
        iconTheme: const IconThemeData(color: Colors.white), // White arrow
        // No centerTitle to keep the title on the left
        title: const Text(
          'Choose Payment Method',
          style: TextStyle(color: Colors.white), // White AppBar text
        ),
      ),
      backgroundColor: const Color(0xFFF7EAF0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Use Center to keep content in the middle horizontally
        child: Center(
          // Use a Column so we can place the text above the row
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Select a Payment Method" in black, placed above the images
              const Text(
                'Please Choose your Payment Option',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Keep it black
                ),
              ),
              const SizedBox(height: 20),

              // Row of Cash & Redeem Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1) Cash Option
                  InkWell(
                    onTap: () {
                      // Navigate to PaymentPage for Cash
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/cashcoins.png',
                          width: 300,
                          height: 300,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cash',
                          style: TextStyle(fontSize: 30),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // 2) Redeem Points
                  InkWell(
                    onTap: () {
                      // Navigate to PaymentPage for Redeem Points
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/points.png',
                          width: 300,
                          height: 300,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Redeem Points',
                          style: TextStyle(fontSize: 30),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
