import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'dart:typed_data'; // Import for Uint8List

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  int _dotCount = 0; // Track the number of dots for the loading effect
  Timer? _timer; // Reference to the Timer
  final TextEditingController _cardNumberController = TextEditingController(); // Controller for card number input

  @override
  void initState() {
    super.initState();

    // Change the number of dots every 500 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // Cycle through 0-3 dots
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer
    _cardNumberController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF4E5),
        body: Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Stack(
            children: [
              Align(
                alignment: const AlignmentDirectional(0.0, -0.6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/image/splash-logo.png', // Replace with your image asset path
                    width: 200.0,
                    height: 192.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Align(
                alignment: AlignmentDirectional(0.0, -0.15),
                child: Text(
                  'Hello!',
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: Color(0xFF1E5D6F),
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Align(
                alignment: AlignmentDirectional(0.01, -0.04),
                child: Text(
                  'Feeling sick? Tap it!',
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: Color(0xFF1E5D6F),
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: const AlignmentDirectional(0.01, 0.20),
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: Colors.white,
                  elevation: 0.0, // Remove shadow by setting elevation to 0
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Container(
                    width: 250.0, // Set the width of the Card
                    padding: const EdgeInsets.symmetric(horizontal: 1.0), // Adjust padding
                    child: TextField(
                      controller: _cardNumberController,
                      textAlign: TextAlign.center, // Center the text
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter Card Number',
                        filled: true,
                        fillColor: Colors.transparent, // Set background color to transparent
                        alignLabelWithHint: true, // Align label with hint
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ),
              const Align(
                alignment: AlignmentDirectional(0.05, 0.45),
                child: Text(
                  'Tap your card to access \nVendoMed services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Align(
                alignment: AlignmentDirectional(0.05, 0.70),
                child: Text(
                  '© 2023 VendoMed Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}