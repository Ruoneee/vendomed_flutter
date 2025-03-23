import 'dart:async';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({Key? key}) : super(key: key);

  @override
  ConfirmationScreenState createState() => ConfirmationScreenState();
}

class ConfirmationScreenState extends State<ConfirmationScreen> {
  final String _dispensingMessage = "Order Confirmed!";
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    _startAutoNavigateTimer();
  }

  void _startAutoNavigateTimer() {
    // Cancel any existing timer and start a new one
    _autoNavigateTimer?.cancel();
    // Auto-navigate after 3 seconds
    _autoNavigateTimer = Timer(const Duration(seconds: 2), () {
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
    // Get the screen height
    final screenHeight = MediaQuery.of(context).size.height;
    // Decide how large the image and text should be
    final logoHeight = screenHeight * 0.60; // 40% of screen height
    final textSize = screenHeight * 0.07;   // 7% of screen height

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The logo at 40% of screen height
            Image.asset(
              'assets/images/splash_logo.png',
              height: logoHeight,
            ),
            SizedBox(height: screenHeight * 0.05), // 5% spacing
            Text(
              _dispensingMessage,
              style: TextStyle(
                fontSize: textSize,  // 7% of screen height
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
