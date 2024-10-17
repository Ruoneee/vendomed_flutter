import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  int _dotCount = 0; // Track the number of dots for the loading effect

  @override
  void initState() {
    super.initState();

    // Change the number of dots every 500 milliseconds
    Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // Cycle through 0-3 dots
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 1080, // Width for resolution
          height: 2400, // Height for resolution
          decoration: BoxDecoration(
            color: Colors.white, // Background color
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dots for loading effect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(_dotCount == index ? 1.0 : 0.3), // Change opacity based on active dot
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20), // Space between dots and text
                Text(
                  'VendoMed',
                  style: TextStyle(
                    fontSize: 48, // Adjust font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.blue, // Text color
                  ),
                ),
                SizedBox(height: 10), // Space between title and message
                Text(
                  'Please scan your RFID to proceed.',
                  style: TextStyle(
                    fontSize: 20, // Adjust font size as needed
                    color: Colors.black, // Message text color
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
