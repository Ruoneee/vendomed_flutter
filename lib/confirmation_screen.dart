import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Updated import

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  ConfirmationScreenState createState() => ConfirmationScreenState();
}

class ConfirmationScreenState extends State<ConfirmationScreen> {
  String _dispensingMessage = "Order Confirmed!";
  Timer? _autoNavigateTimer; // Timer for auto navigation

  @override
  void initState() {
    super.initState();
    _startAutoNavigateTimer();
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        // After 5s, pop this screen then navigate to SplashScreen
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()), // Changed target
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
      // Remove the AppBar entirely
      backgroundColor: const Color(0xFFFFFFFF), // Match your design colors, if needed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dispensingMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // If user presses PROCEED before 5s, skip the timer and go to SplashScreen
                _autoNavigateTimer?.cancel();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()), // Changed target
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2A5E),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
              child: const Text(
                'PROCEED',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
