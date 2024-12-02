import 'dart:async'; // Import this for Timer
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:vendomed_flutter/rfid_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final BluetoothDevice device;

  const ConfirmationScreen({super.key, required this.device});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _dispensingMessage = "Order Confirmed!";
  BluetoothCharacteristic? targetCharacteristic;

  final String serviceUUID = "1bf2a612-29c3-4a82-9b3d-b9abc9e81daa";
  final String characteristicUUID = "45088d05-aa3b-42da-aa75-bf85d5046829";

  Timer? _autoNavigateTimer; // Timer for auto navigation

  @override
  void initState() {
    super.initState();
    startListening();
  }

  Future<void> startListening() async {
    List<BluetoothService> services = await widget.device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;

            await targetCharacteristic!.setNotifyValue(true);
            targetCharacteristic!.value.listen((value) {
              String receivedData = String.fromCharCodes(value);
              if (receivedData.isEmpty || (RegExp(r'^\d+$').hasMatch(receivedData))) {
                return;
              }
              setState(() {
                _dispensingMessage = receivedData;

                // Start timer when "Order complete" is received
                if (_dispensingMessage.toLowerCase() == "order complete") {
                  _startAutoNavigateTimer();
                }
              });
              print('Confirmed Data: $_dispensingMessage');
            });
          }
        }
      }
    }
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel(); // Cancel existing timer, if any
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () async {
      await disconnectFromDevice(); // Ensure Bluetooth disconnects
      if (mounted) {
        Navigator.pop(context); // Pop ConfirmationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RfidScreen()),
        );
      }
    });
  }

  Future<void> disconnectFromDevice() async {
    await widget.device.disconnect();
    print('Disconnected from Bluetooth device.');
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel(); // Cancel the timer when widget is disposed
    disconnectFromDevice(); // Call disconnectFromDevice in dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        backgroundColor: const Color(0xfffffffff),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () async {
              await disconnectFromDevice();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dispensingMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                _autoNavigateTimer?.cancel(); // Cancel timer if manually pressed
                await disconnectFromDevice();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RfidScreen()),
                );
              },
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
