import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  BluetoothCharacteristic? targetCharacteristic; // Store the characteristic for later use

  final String serviceUUID = "1bf2a612-29c3-4a82-9b3d-b9abc9e81daa"; // Service UUID
  final String characteristicUUID = "45088d05-aa3b-42da-aa75-bf85d5046829"; // Characteristic UUID

  String coinCountMessage = ''; // Store coin count message

  @override
  void initState() {
    super.initState();
    _connectToDevice(); // Start Bluetooth connection process
  }

  Future<void> _connectToDevice() async {
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
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
        isConnected = true;
      });

      // Discover services and find the custom characteristic
      await _discoverServicesAndCharacteristics(device);
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  Future<void> _discoverServicesAndCharacteristics(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == serviceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;
            await targetCharacteristic!.setNotifyValue(true);
            targetCharacteristic!.value.listen((value) {
              String receivedData = String.fromCharCodes(value);
              print("Received data from ESP32: $receivedData");
              _handleReceivedData(receivedData); // Handle received data
            });
            print('Service and characteristic found and notifications enabled.');
          }
        }
      }
    }
  }

  Future<void> sendData(String data) async {
    if (isConnected && targetCharacteristic != null) {
      try {
        await targetCharacteristic!.write(data.codeUnits);
        print("Data sent to ESP32: $data");
      } catch (e) {
        print("Failed to send data: $e");
      }
    } else {
      print("Bluetooth is not connected or characteristic not found.");
    }
  }

  // Handle received coin count data
  void _handleReceivedData(String data) {
    setState(() {
      coinCountMessage = data; // Update the coin count message
    });

    // Extract coin count and check if it matches the total amount
    if (data.startsWith("Coins: ")) {
      int coinCount = int.parse(data.split(": ")[1]);
      // Assuming each coin is worth 1 unit, you can adjust this logic
      if (coinCount >= widget.orders.length) { // Check if enough coins are inserted
        _dispenseMedicine(); // Dispense medicines if coin count is sufficient
      }
    }
  }

  // Dispense the medicine
  void _dispenseMedicine() {
    for (var order in widget.orders) {
      String medicineName = order['name']!;

      String dataToSend = '';
      if (medicineName == 'Ibuprofen') {
        dataToSend = '1'; // Send '1' for Ibuprofen
      } else if (medicineName == 'Cetirizine') {
        dataToSend = '2'; // Send '2' for Cetirizine
      } else if (medicineName == 'Paracetamol') {
        dataToSend = '3'; // Send '3' for Paracetamol
      } else if (medicineName == 'Loperamide') {
        dataToSend = '4'; // Send '4' for Loperamide
      }

      // Send the data to ESP32
      if (dataToSend.isNotEmpty) {
        sendData(dataToSend); // Command the ESP32 to activate the corresponding motor
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0.0;

    // Sum the total amount from the price in the orders list
    for (var order in widget.orders) {
      String priceString = order['price']!.replaceAll('₱', '').trim(); // Remove '₱' and any spaces
      totalAmount += double.parse(priceString); // Convert to double and sum
    }

    return WillPopScope(
      onWillPop: () async {
        // Returning false prevents the back button from working
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E5D6F),
          automaticallyImplyLeading: false,
          title: const Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/userIcons/user_icon.png'),
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(
                "Welcome, User!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xfffffe4e5),
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
                    itemCount: widget.orders.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${widget.orders[index]['name']} - ${widget.orders[index]['price']}',
                        ),
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
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Total amount will appear here',
                ),
                initialValue: '₱${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),



              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Back button
                    },
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E5A5D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      sendData("Coins: ${widget.orders.length}"); // Send the number of orders to ESP32
                    },
                    child: const Text('PROCEED'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Debugging Button

            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (connectedDevice != null) {
      connectedDevice!.disconnect();
    }
    super.dispose();
  }
}