// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  int dotCount = 0; // Track the number of dots for the loading effect

  @override
  void initState() {
    super.initState();

    // Change the number of dots every 500 milliseconds
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // Cycle through 0-3 dots
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 1080, // Width for resolution
          height: 2400, // Height for resolution
          decoration: const BoxDecoration(
            color: Color(0xfffffe4e5), // Background color
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image at the top of the screen
                Image.asset(
                  'assets/images/splash_logo.png', // Ensure this path matches your assets folder
                  height: 280, // Adjust height as needed
                ),
                const SizedBox(height: 50), // Space between image and dots

                // Dots for loading effect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E5D6F).withOpacity(dotCount == index ? 1.0 : 0.3), // Change opacity based on active dot
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20), // Space between dots and text
                const Text(
                  'VendoMed',
                  style: TextStyle(
                    fontSize: 48, // Adjust font size as needed
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E5D6F), // Text color
                  ),
                ),
                const SizedBox(height: 10), // Space between title and message
                const Text(
                  'Scan RFID to access VendoMed.',
                  style: TextStyle(
                    fontSize: 20, // Adjust font size as needed
                    color: Color(0xFF1E5D6F), // Message text color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
