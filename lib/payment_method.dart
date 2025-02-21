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
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double imageHeight = 270.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white, // Updated background color to white
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(3, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 30,
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
                  const SizedBox(height: 200),
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

                  const SizedBox(height: 100),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaymentOptionButton(
                        imagePath: 'assets/images/gcashlogo.png',
                        label: 'GCash',
                        onTap: () async {
                          // Navigate to GCashPaymentPage and wait for its result.
                          bool? result = await Navigator.push(
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
                          // Propagate the result back to MedicineMenu.
                          Navigator.pop(context, result);
                        },
                      ),
                      const SizedBox(width: 60),
                      PaymentOptionButton(
                        imagePath: 'assets/images/cashcoins.png',
                        label: 'Cash/Coins',
                        onTap: () async {
                          bool? result = await Navigator.push(
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
                          Navigator.pop(context, result);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // Cancel returns false.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D2A5E),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
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
