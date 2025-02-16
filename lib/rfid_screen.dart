import 'dart:async';
import 'package:flutter/material.dart';
import 'medicine_menu.dart';
import 'splash_screen.dart';
import 'database_helper.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rfidFocusNode.requestFocus();
    });

    _rfidController.addListener(() {
      final trimmed = _rfidController.text.trim();
      if (trimmed.length == 10 && !navigated) {
        _processRfid(trimmed);
      }
    });
  }

  Future<void> _processRfid(String rfid) async {
    if (await _isValidRfid(rfid)) {
      setState(() => navigated = true);
      Timer(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MedicineMenu(rfidData: rfid)),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid RFID. Please try again.")),
      );
    }
  }

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
      print("Error querying RFID: $e");
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
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
          title: const Text("RFID Scan", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: GestureDetector(
          onTap: () => _rfidFocusNode.requestFocus(),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/tap_rfid.png',
                      width: 700,
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Please present your RFID to the reader.",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2A5E), //0xFF0D2A5E
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.5,
                  child: TextField(
                    controller: _rfidController,
                    focusNode: _rfidFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    obscureText: true,
                    //obscuringCharacter: '*',
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
