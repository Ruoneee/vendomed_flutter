import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package
import 'medicine_menu.dart';
import 'database_helper.dart';
import 'dashboard.dart';
import 'user_selection_screen.dart';

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  _RfidScreenState createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen> {
  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocusNode = FocusNode();
  bool navigated = false;

  @override
  void initState() {
    super.initState();
    // Automatically focus the hidden TextField on screen load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rfidFocusNode.requestFocus();
    });

    // Listen for input changes in the RFID TextField.
    _rfidController.addListener(() {
      final trimmed = _rfidController.text.trim();
      // If we get 10 characters and haven't navigated yet, process the RFID.
      if (trimmed.length == 10 && !navigated) {
        _processRfid(trimmed);
      }
    });
  }

  // Process the scanned RFID.
  Future<void> _processRfid(String rfid) async {
    final bool isAdmin = await _isAdmin(rfid);
    if (isAdmin) {
      // RFID belongs to an admin -> Navigate to Dashboard.
      setState(() => navigated = true);
      Timer(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      });
    } else if (await _isValidRfid(rfid)) {
      // RFID is valid (regular user) -> Navigate to MedicineMenu.
      setState(() => navigated = true);
      Timer(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MedicineMenu(rfidData: rfid)),
        );
      });
    } else {
      // RFID is invalid -> Show error message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid RFID. Please try again.")),
      );
    }
  }

  // Check if RFID belongs to an admin by reading the ROLE column.
  Future<bool> _isAdmin(String rfid) async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['ROLE'],
        where: 'rfid = ?',
        whereArgs: [rfid],
      );

      if (result.isNotEmpty) {
        final roleValue = result.first['ROLE']?.toString();
        return (roleValue == 'Admin');
      }
      return false;
    } catch (e) {
      debugPrint("Error checking Admin: $e");
      return false;
    }
  }

  // Check if RFID exists in the 'users' table (valid user).
  Future<bool> _isValidRfid(String rfid) async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['rfid'],
        where: 'rfid = ?',
        whereArgs: [rfid],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint("Error querying RFID: $e");
      return false;
    }
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
      // Override the back button to navigate to UserSelectionScreen.
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
        );
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          title: const Text(
            'RFID Screen',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
              );
            },
          ),
        ),
        // Use a container with a gradient background instead of a solid color.
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D2A5E), // Start color
                Color(0xFF1E5D6F), // End color
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: GestureDetector(
            onTap: () => _rfidFocusNode.requestFocus(),
            child: Stack(
              children: [
                // Main content: Lottie animation and prompt text.
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Replace static image with Lottie animation.
                      Lottie.asset(
                        'assets/animations/rfida.json',
                        width: 500,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Tap your RFID Reward Card.",
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Hidden TextField for reading the RFID input.
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
      ),
    );
  }
}
