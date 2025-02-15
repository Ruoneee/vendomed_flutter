// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'medicine_menu.dart'; // Screen to show medicine menu
import 'splash_screen.dart'; // Import your splash screen

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  _RfidScreenState createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> {
  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocusNode = FocusNode();
  bool navigated = false; // To prevent multiple navigations

  @override
  void initState() {
    super.initState();
    // Request focus for the hidden TextField after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rfidFocusNode.requestFocus();
    });

    // Listen for changes in the TextField.
    _rfidController.addListener(() {
      final trimmed = _rfidController.text.trim();
      // Automatically process once 10 characters are entered.
      if (trimmed.length == 10 && !navigated) {
        _processRfid(trimmed);
      }
    });
  }

  void _processRfid(String rfid) {
    if (_isValidRfid(rfid)) {
      setState(() {
        navigated = true;
      });
      // Delay a moment before navigating.
      Timer(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineMenu(rfidData: rfid),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid RFID. Please try again.")),
      );
    }
  }

  bool _isValidRfid(String rfid) {
    // List of valid RFIDs.
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

  @override
  void dispose() {
    _rfidController.dispose();
    _rfidFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Allow back navigation; we'll handle it manually via the back arrow.
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Manually navigate back to the SplashScreen.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          title: const Text(
            "RFID Scan",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Wrap entire screen in GestureDetector to re-request focus.
        body: GestureDetector(
          onTap: () {
            _rfidFocusNode.requestFocus();
          },
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display the RFID tap image with the correct asset path.
                    Image.asset(
                      'assets/images/tap_rfid.png', // Ensure this path is correct
                      width: 700, // Adjust size as needed
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Please present your RFID to the reader.",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2A5E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // The invisible TextField that still receives input.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _rfidController,
                    focusNode: _rfidFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    obscureText: true,
                    obscuringCharacter: '*',
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Enter RFID",
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24),
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
