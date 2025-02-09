// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'user_selection_screen.dart'; // This screen will ask if the user has RFID or is a guest

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  int dotCount = 0; // For loading dots animation

  @override
  void initState() {
    super.initState();
    // Start a timer for a simple loading effect.
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire Scaffold in a GestureDetector.
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button.
      child: GestureDetector(
        onTap: () {
          // Navigate to the User Selection Screen when tapped.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSelectionScreen(),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF), // White background
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF), // White background
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Splash logo image.
                Image.asset(
                  'assets/images/splash_logo.png', // Ensure the asset path is correct.
                  height: 600,
                ),
                const SizedBox(height: 30),
                // Catchy phrase to enhance user experience.
                const Text(
                  "Tap to Proceed!",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                // Optionally, you can still show loading dots:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E5D6F)
                            .withOpacity(dotCount == index ? 1.0 : 0.3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
