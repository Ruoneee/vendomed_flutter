// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'medicine_menu.dart'; // Your medicine menu

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  RfidScreenState createState() => RfidScreenState();
}

class RfidScreenState extends State<RfidScreen> {
  final TextEditingController _rfidController = TextEditingController();
  String? rfidData;
  int dotCount = 0; // Track the number of dots for the loading effect

  @override
  void initState() {
    super.initState();

    // Initialize the loading dots animation
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // Cycle through 0-3 dots
      });
    });

    // Listen for changes in the TextField and process RFID data
    _rfidController.addListener(() {
      setState(() {
        rfidData = _rfidController.text.trim(); // Get the RFID data from the TextField
      });

      // Automatically validate once 10 characters are entered
      if (rfidData?.length == 10) {
        if (_isValidRfid(rfidData)) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MedicineMenu()),
          );
        } else {
          _showErrorMessage("Invalid RFID. Please try again.");
        }
      }
    });
  }

  bool _isValidRfid(String? rfid) {
    // Validate the RFID against a list of valid codes
    const validRfids = [
      '0004315586',
      '0004713969',
      '0004278059',
      '0004300970',
      '0004726985',
      '0004709548',
      '0004674353',
      '0006127120',
      '0004666016',
      '0004709554',
    ];
    return validRfids.contains(rfid);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _rfidController.dispose(); // Dispose the controller when not in use
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      // Returning false prevents the back button from working
      return false;
    },

      child: Scaffold(
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

                // Loading Dots Effect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotCount > index ? Color(0xFF1E5D6F) : Colors.grey,
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

                const SizedBox(height: 20), // Space between the message and the text field

                // RFID Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: SizedBox(
                    height: 60, // Adjust height of the TextField
                    child: TextField(
                      controller: _rfidController,
                      cursorColor: Color(0xfffffe4e5),
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xfffffe4e5), // Color of the border when unfocused (change this color)
                            width: 2.0, // Width of the border when unfocused
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xfffffe4e5), // Color of the border when focused
                            width: 2.0, // Width of the border
                          ),
                        ),
                      ),
                      maxLength: 10, // Expecting 10 characters from RFID
                      autofocus: true, // Automatically focuses on the TextField
                      style: const TextStyle(
                        fontSize: 20, // Font size of the entered text
                        color: Color(0xfffffe4e5), // Text color inside the TextField
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
     )
    );
  }
}
