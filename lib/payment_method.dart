import 'package:flutter/material.dart';
import 'gcash.dart';
import 'payment.dart'; // Your existing payment page for Bill Acceptor / Coin Slot

/// A custom widget for a square payment option button.
class PaymentOptionButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const PaymentOptionButton({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 240;
    const double buttonHeight = 340;
    const double imageHeight = 200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(3, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 26,
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
    super.key,
    required this.orders,
    required this.rfidData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const SizedBox(height: 150),

                  const Text(
                    "Please Select Your",
                    style: TextStyle(
                      fontSize: 50,
                      color: Color(0xFF0D2A5E),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    "Payment Method",
                    style: TextStyle(
                      fontSize: 50,
                      color: Color(0xFF0D2A5E),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 80),

                  // Payment Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // GCash Payment Option
                      PaymentOptionButton(
                        imagePath: 'assets/images/gcashlogo.png',
                        label: 'GCash',
                        onTap: () async {
                          // Navigate to GCashPaymentPage
                          final result = await Navigator.push<bool>(
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

                          // If user actually came back from GCash (i.e. no success?), pop
                          if (result == false) {
                            // They probably canceled or something else
                            Navigator.pop(context, false);
                          }

                          // If result is true or null, do nothing so user doesn't get forced back
                        },
                      ),
                      const SizedBox(width: 20),
                      // Cash/Coins Payment Option
                      PaymentOptionButton(
                        imagePath: 'assets/images/cashcoins.png',
                        label: 'Cash/Coins',
                        onTap: () async {
                          final result = await Navigator.push<bool>(
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
                          // If they canceled or something, pop
                          if (result == false) {
                            Navigator.pop(context, false);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                  ElevatedButton(
                    onPressed: () {
                      // Cancel button => user doesn't want to continue
                      Navigator.pop(context, false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Back",
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
