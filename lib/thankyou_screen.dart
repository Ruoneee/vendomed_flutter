import 'dart:async';  // For the Timer
import 'package:flutter/material.dart';
import 'splash_screen.dart';

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  ThankYouScreenState createState() => ThankYouScreenState();
}

class ThankYouScreenState extends State<ThankYouScreen> {
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    // Start a 5-second timer that automatically goes to SplashScreen
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToSplash();
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer if this screen is disposed earlier
    _autoNavigateTimer?.cancel();
    super.dispose();
  }

  void _navigateToSplash() {
    // Pop this screen, then push splash_screen.dart
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Same AppBar design:
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2A5E),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Order Complete!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFFFFF),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: Column(
            children: [
              // Adjust the height to whatever feels right for your design
              Image.asset(
                'assets/images/splash_logo.png',
                height: 600,  // smaller or bigger as needed
                fit: BoxFit.contain,
              ),

              // Spacing between logo and text
              const SizedBox(height: 20),

              // Adjust the text content & spacing
              const Text(
                'ORDER COMPLETE!\n\nTHANK YOU FOR PURCHASED!',
                style: TextStyle(
                  fontSize: 30, // slightly reduced from 26
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              // Spacing at the bottom
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
