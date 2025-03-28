import 'dart:async';
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:lottie/lottie.dart';

class ConfirmationScreen extends StatefulWidget {
  final List<Map<String, String>> orders;
  final double totalPrice;

  const ConfirmationScreen({
    Key? key,
    required this.orders,
    required this.totalPrice,
  }) : super(key: key);

  @override
  ConfirmationScreenState createState() => ConfirmationScreenState();
}

class ConfirmationScreenState extends State<ConfirmationScreen> {
  final String _dispensingMessage = "Order confirmed!";
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    _startAutoNavigateTimer();
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // SingleChildScrollView in case the screen is too small
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie success animation (uncommented now)
              Lottie.asset(
                'assets/animations/success.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 20),

              // Your large splash logo
              Image.asset(
                'assets/images/splash_logo.png',
                height: 600,
              ),
              const SizedBox(height: 20),

              // "Order confirmed!" text
              Text(
                _dispensingMessage,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Purchase summary
              if (widget.orders.isNotEmpty) ...[
                const Text(
                  "Purchase Summary:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (var order in widget.orders) ...[
                  Text(
                    "${order['name']} x ${order['quantity']} = ₱${order['price']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  "Total: ₱${widget.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],

              // Retrieval message
              const Text(
                "Please retrieve your items from the dispenser.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
