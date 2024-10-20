import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class PaymentPage extends StatefulWidget {
  final List<Map<String, String>> orders; // Accept the orders list with name and price

  const PaymentPage({super.key, required this.orders}); // Constructor to receive orders

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  bool isConnected = false;
  double totalAmount = 0.0;
  int dotCount = 0; // Track the number of dots for the loading effect

  @override
  void initState() {
    super.initState();
    // Calculate total amount from the orders
    _calculateTotalAmount();

    // Start Bluetooth connection process
    _connectToDevice();
  }

  void _calculateTotalAmount() {
    // Sum the total amount from the price in the orders list
    for (var order in widget.orders) {
      String priceString = order['price']!.replaceAll('₱', '').trim(); // Remove '₱' and any spaces
      totalAmount += double.parse(priceString); // Convert to double and sum
    }
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
      _sendDataToESP32(); // Send data once connected
    } catch (e) {
      print('Failed to connect: $e');
      // Handle connection failure
    }
  }

  void _sendDataToESP32() {
    if (isConnected && connectedDevice != null) {
      // Here, implement the logic to send data to the ESP32 device
      // For example: connectedDevice!.write(...);
      // Make sure to format the data you want to send based on your ESP32's requirements
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E5D6F),
          automaticallyImplyLeading: false, // Set app bar color
          title: const Row(
            children: [
              CircleAvatar(
                backgroundImage:
                AssetImage('assets/userIcons/user_icon.png'), // User icon image
                radius: 20, // Radius of the circle
              ),
              SizedBox(width: 10), // Space between icon and text
              Text(
                "Welcome, User!", // Welcome message
                style: TextStyle(
                  fontSize: 18, // Font size of the welcome message
                  color: Colors.white, // Text color
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xfffffe4e5), // Light beige background
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ORDER/S:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: widget.orders.length, // Display the passed orders
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${widget.orders[index]['name']} - ${widget.orders[index]['price']}'),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Total Amount
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: false, // Read-only field
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Set border color to black
                  ),
                  hintText: 'Total amount will appear here',
                ),
                initialValue: '₱${totalAmount.toStringAsFixed(2)}', // Display total amount
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E5A5D), // Back button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white, // Set text color for the Back button
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('BACK'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5D6F), // Proceed button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white, // Set text color for the Proceed button
                    ),
                    onPressed: () {
                      if (isConnected) {
                        Navigator.popAndPushNamed(context, '/rfid_screen'); // Proceed button action
                      } else {
                        // Optionally show a message or handle disconnection case
                      }
                    },
                    child: const Text('PROCEED'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
