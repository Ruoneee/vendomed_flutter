import 'package:flutter/material.dart';
import 'confirmation_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled; // New parameter
  final String rfidData;


  const PaymentPage({
    Key? key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  }) : super(key: key);

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
  final TextEditingController _coinsInsertedController = TextEditingController();

  int coinInserted = 0; // Counter for inserted coins
  String dataToSend = '';
  String lastReceivedData = '';
  bool coinEqualToAmount = false;
  double totalAmount = 0.0; // Class-level variable for total amount


  @override
  void initState() {
    super.initState();
    _calculateTotalAmount(); // Calculate total amount on initialization
    _connectToDevice(); // Start Bluetooth connection process
  }

  // Method to calculate the total amount
  void _calculateTotalAmount() {
    totalAmount = 0.0; // Reset total amount
    for (var order in widget.orders) {
      String priceString = order['price']!.replaceAll('₱', '').trim();
      totalAmount += double.parse(priceString);
    }
    print('Total Amount: $totalAmount');
  }

  Future<void> _connectToDevice() async {
    // Start scanning for BLE devices
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((scanResult) {
      for (ScanResult result in scanResult) {
        if (result.advertisementData.advName == 'VendoMed') {
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
        _calculateTotalAmount();
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;
            await targetCharacteristic!.setNotifyValue(true);
            targetCharacteristic!.value.listen((value) {
              String receivedData = String.fromCharCodes(value);
              if(receivedData.isEmpty ||!(RegExp(r'^\d+$').hasMatch(receivedData))){
                return;
              }
              print("Received data from ESP32: $receivedData");

              _handleReceivedData(receivedData); // Handle received data
            });
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

  // Handle received coin detection data
  void _handleReceivedData(String data) {
    if (mounted && data != lastReceivedData) {
      lastReceivedData = data; // Check if the widget is still in the widget tree

      if (data.isNotEmpty) {
        setState(() {
          coinInserted++; // Increment coin count
          if(data == dataToSend || data == '0'){
            dataToSend = '';
            coinInserted = 0;
          }
          _coinsInsertedController.text = '₱${coinInserted.toString()}';

          // Check if the inserted coins match the required total
          if (coinInserted >= totalAmount) {
            coinEqualToAmount = true;
          }
          print("Coin equal to amount: $coinEqualToAmount");
        });
      }
    }
  }

  // Dispense the medicine
  void _dispenseMedicine() {
    for (var order in widget.orders) {
      String medicineName = order['name']!;

      if (medicineName == 'Ibuprofen') {
        dataToSend += '1'; // Send '1' for Ibuprofen
      } else if (medicineName == 'Cetirizine') {
        dataToSend += '2'; // Send '2' for Cetirizine
      } else if (medicineName == 'Paracetamol') {
        dataToSend += '3'; // Send '3' for Paracetamol
      } else if (medicineName == 'Loperamide') {
        dataToSend += '4'; // Send '4' for Loperamide
      }
    }
  }
  void _onProceedButtonPressed() {
    if (coinEqualToAmount) {
      _dispenseMedicine();
      sendData(dataToSend);

      setState(() {
        coinEqualToAmount = false;
        coinInserted = 0;
      });

      print("Data Successfully Sent");

      if (connectedDevice != null) {
        // Send medicinesToBeDisabled back to the previous screen first
        Navigator.pop(context, widget.medicinesToBeDisabled);

        // Then navigate to the confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(device: connectedDevice!),
          ),
        );


      } else {
        print("No device connected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Bluetooth device connected')),
        );
      }
    } else {
      print("Coins inserted do not equal total amount.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Coins Inserted')),
      );
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
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/userIcons/user_icon.png'),
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(
                "Welcome,  ${widget.rfidData}!!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        backgroundColor: const Color(0xFFFFFFFF),
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

              // Coins Inserted
              const Text(
                'COINS INSERTED:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: false,
                controller: _coinsInsertedController, // Set the controller
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Number of coins inserted',
                ),
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
                      if (connectedDevice != null) {
                        connectedDevice!.disconnect();
                        print('Disconnected from Bluetooth device.');
                      }
                      Navigator.pop(context); // Back button

                    },
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onProceedButtonPressed, // Call the new function
                    child: const Text('PROCEED'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}