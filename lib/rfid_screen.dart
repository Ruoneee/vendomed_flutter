// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'medicine_menu.dart'; // Screen to show medicine menu

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  _RfidScreenState createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> {
  final TextEditingController _rfidController = TextEditingController();
  String? rfidData;
  String? maskedRfid;
  bool navigated = false; // To prevent multiple navigations

  @override
  void initState() {
    super.initState();
    // Listen for changes in the TextField.
    _rfidController.addListener(() {
      setState(() {
        rfidData = _rfidController.text.trim();
      });
      // Automatically process once 10 characters are entered.
      if (rfidData?.length == 10 && !navigated) {
        if (_isValidRfid(rfidData!)) {
          // Mask the RFID (showing only the last 4 digits).
          setState(() {
            maskedRfid = "******" + rfidData!.substring(6);
            navigated = true;
          });
          // Delay a moment so the user can see the masked RFID.
          Timer(const Duration(milliseconds: 1000), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MedicineMenu(rfidData: rfidData!),
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid RFID. Please try again.")),
          );
        }
      }
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent the back button if needed.
      onWillPop: () async => false,
      child: Scaffold(
        // Set the scaffold background to white.
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          title: const Text(
            "RFID Scan",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Please scan your RFID or enter it manually to proceed.",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: TextField(
                    controller: _rfidController,
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
                const SizedBox(height: 30),
                // Display masked RFID if available.
                if (maskedRfid != null)
                  Text(
                    "Scanned RFID: $maskedRfid",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2A5E),
                    ),
                  ),
                // The Submit button is removed.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
