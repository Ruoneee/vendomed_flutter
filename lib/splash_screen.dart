// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'user_selection_screen.dart';


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
    // Start a timer for a simple loading dots animation.
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });
    // Initialize USB connection in the background.

  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent the back button during splash.
      onWillPop: () async => false,
      child: GestureDetector(
        // Tapping anywhere on the screen navigates to the next screen.
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Splash logo image.
                Image.asset(
                  'assets/images/splash_logo.png', // Ensure this path is correct.
                  height: 600,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Tap to Proceed!",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Display status message only if not empty.

                const SizedBox(height: 50),
                // Loading dots animation.
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
