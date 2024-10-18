// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

import 'rfid_screen.dart'; // Import for handling timeouts and delays

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  bool isConnected = false;
  int dotCount = 0; // Track the number of dots for the loading effect

  @override
  void initState() {
    super.initState();
    // Start Bluetooth connection process
    _connectToDevice();

    // Change the number of dots every 500 milliseconds
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4; // Cycle through 0-3 dots
      });
    });
  }

  Future<void> _connectToDevice() async {
    // Avoid reconnecting if already connected
    if (isConnected) return;

    // Start scanning for BLE devices
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((scanResult) {
      for (ScanResult result in scanResult) {
        if (result.advertisementData.advName == 'VendoMed' || result.device.remoteId.toString() == "8:A6:F7:22:D3:AE") {
          FlutterBluePlus.stopScan();
          _connect(result.device);
          break;
        }
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (isConnected) return; // Avoid re-connecting if already connected

    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        isConnected = true;
      });
      await device.discoverServices();
      _navigateToNextScreen();
    } catch (e) {
      print('Failed to connect: $e');
      // Handle connection failure
    }
  }

  void _navigateToNextScreen() {
    if (isConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RfidScreen()),
      );
    }
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
                  'Connecting!',
                  style: TextStyle(
                    fontSize: 30, // Adjust font size as needed
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E5D6F), // Text color
                  ),
                ),

                const SizedBox(height: 10), // Space between messages
                if (isConnected) // Show message if connected
                  const Text(
                    'Connected to ESP32! Redirecting...',
                    style: TextStyle(
                      fontSize: 20, // Adjust font size as needed
                      color: Color(0xFF1E5D6F), // Message text color
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
     )
    );
  }
}