// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'user_selection_screen.dart';
import 'usb_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  int dotCount = 0; // For loading dots animation
  String _statusMessage = 'Initializing USB connection...';

  @override
  void initState() {
    super.initState();
    // Start a timer for a simple loading dots animation.
    Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });
    // Initialize USB connection in the background.
    _initUsbConnection();
  }

  Future<void> _initUsbConnection() async {
    // List available USB devices.
    List<UsbDevice> devices = await UsbSerial.listDevices();

    if (devices.isEmpty) {
      setState(() {
        _statusMessage = 'No USB devices found. Please connect your ESP32.';
      });
      return;
    }

    // Since we expect only one device, pick the first.
    UsbDevice device = devices.first;
    setState(() {
      _statusMessage = 'Found device: ${device.productName}. Connecting...';
    });

    try {
      // Use the global USBService to connect.
      await USBService().connectToDevice(device);
      // Clear the status message on success.
      setState(() {
        _statusMessage = '';
      });
      // Automatically send 1 to the ESP32 to turn on the LED.
      await _sendData(1);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting: $e';
      });
    }
  }

  /// Sends the given integer [value] as a single byte via USB serial.
  Future<void> _sendData(int value) async {
    try {
      await USBService().writeData(value);
    } catch (e) {
      // Optionally log or display an error.
      debugPrint("Error sending data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFFFFFF),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Splash logo image.
            Image.asset(
              'assets/images/splash_logo.png', // Ensure the asset path is correct.
              height: 600,
            ),
            const SizedBox(height: 30),
            // Proceed button area.
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
                );
              },
              child: const Text(
                "Tap to Proceed!",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D2A5E)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 20),
            // Status message (only shows error messages).
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1E5D6F)),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            // USB control buttons appear only if the connection is established.
            if (USBService().isConnected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _sendData(1); // Send 1 to turn LED on.
                    },
                    child: const Text('Send 1'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _sendData(0); // Send 0 to turn LED off.
                    },
                    child: const Text('Send 0'),
                  ),
                ],
              ),
            const SizedBox(height: 50),
            // Loading dots animation.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E5D6F)
                        .withOpacity(dotCount == index ? 1.0 : 0.3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
