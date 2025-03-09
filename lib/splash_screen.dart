// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'dart:async';
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
    // Attempt to initialize the USB connection.
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

    // Since you're expecting only one device, use the first found device.
    UsbDevice device = devices.first;
    setState(() {
      _statusMessage = 'Found device: ${device.productName}. Connecting...';
    });

    try {
      // Use the global USBService to connect.
      await USBService().connectToDevice(device);
      // If the connection is successful, clear the status message.
      setState(() {
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent the back button during the splash screen.
      onWillPop: () async => false,
      child: GestureDetector(
        // Tap to proceed regardless of connection state.
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSelectionScreen(),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Splash logo image.
                Image.asset(
                  'assets/images/splash_logo.png', // Ensure the asset path is correct.
                  height: 600,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Tap to Proceed!",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Show the status message only if it's not empty.
                if (_statusMessage.isNotEmpty)
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 18, color: Color(0xFF1E5D6F)),
                    textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
