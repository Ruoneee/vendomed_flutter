import 'package:flutter/material.dart';
import 'package:vendomed_flutter/payment.dart' as cash_payment;
import 'package:vendomed_flutter/points.dart' as reward_points;
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
        // Title on the left
        title: const Text(
          'Choose Payment Method',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFFF7EAF0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Use Center to keep content in the middle horizontally
        child: Center(
          // Use a Column so we can place the text above the row of buttons
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Please Choose your Payment Option" in black, placed above the images
              const Text(
                'Please Choose your Payment Option',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Row of Coins/Cash & Reward Points options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1) Coins/Cash Option
                  InkWell(
                    onTap: () {
                      // Navigate to the PaymentPage for Cash using the alias
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => cash_payment.PaymentPage(
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
                          'Coins/Cash',
                          style: TextStyle(fontSize: 30),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // 2) Reward Points Option
                  InkWell(
                    onTap: () {
                      // Navigate to the PointsPage for Reward Points using the alias
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => reward_points.PointsPage(
                            orders: orders,
                            rfidData: rfidData,
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
                          'Reward Points',
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
