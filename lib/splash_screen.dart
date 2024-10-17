import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'dart:typed_data'; // Import for Uint8List

class SplashScreen extends StatefulWidget {
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
    _timer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
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
        backgroundColor: Color(0xFFFFF4E5),
        body: Align(
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional(0.0, -0.6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    Uint8List.fromList([]), // Replace with your image data
                    width: 200.0,
                    height: 192.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.0, -0.15),
                child: Text(
                  'Hello!',
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: Color(0xFF1E5D6F),
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.01, -0.04),
                child: Text(
                  'Feeling sick? Tap it!',
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    color: Color(0xFF1E5D6F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.03, 0.27),
                child: Card(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: Colors.white,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter Card Number',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(0.05, 0.51),
                child: Text(
                  'Tap your card to access \nVendoMed services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
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