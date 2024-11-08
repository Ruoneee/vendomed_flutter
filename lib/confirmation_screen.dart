import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConfirmationScreen extends StatefulWidget {
  final BluetoothDevice device;  // The Bluetooth device passed from the previous screen


  const ConfirmationScreen({super.key, required this.device});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _dispensingMessage = "Order Confirmed!"; // Initial message
  BluetoothCharacteristic? targetCharacteristic;

  // Replace these with your actual service and characteristic UUIDs
  final String serviceUUID = "1bf2a612-29c3-4a82-9b3d-b9abc9e81daa";  // Example UUID
  final String characteristicUUID = "45088d05-aa3b-42da-aa75-bf85d5046829"; // Example UUID


  @override
  void initState() {
    super.initState();
    startListening();
  }

  Future<void> startListening() async {
    // Discover services from the already connected device
    List<BluetoothService> services = await widget.device.discoverServices();

    // Look for the target service and characteristic
    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;

            // Enable notifications for the target characteristic
            await targetCharacteristic!.setNotifyValue(true);

            // Listen for incoming data
            targetCharacteristic!.value.listen((value) {
              String receivedData = String.fromCharCodes(value);
              if(receivedData.isEmpty ||(RegExp(r'^\d+$').hasMatch(receivedData))){
                return;
              }
              setState(() {
                _dispensingMessage = receivedData; // Update message with received data
              });
              print('Confirmed Data: $_dispensingMessage');
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        backgroundColor: const Color(0xFF1E5D6F),
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
              onPressed: () {
                Navigator.pop(context); // Pop ConfirmationScreen
                Navigator.pop(context); // Pop PaymentScree
              },
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
