import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart'; // Import USB Helper



class PaymentPage extends StatefulWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;


  const PaymentPage({
    super.key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  });

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  final TextEditingController _coinsInsertedController = TextEditingController();
  final USBHelper _usbHelper = USBHelper(); // ✅ Uses global instance

  int coinInserted = 0;
  bool coinEqualToAmount = false;
  double totalAmount = 0.0;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserName();
    _usbHelper.initUSB(); // ✅ Ensures connection persists
    _coinsInsertedController.text = "₱0.00"; // ✅ Initialize amount inserted
  }

  Future<void> _loadUserName() async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['NAME'],
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );
      if (result.isNotEmpty) {
        setState(() {
          _userName = result.first['NAME'] as String;
        });
      } else {
        setState(() {
          _userName = widget.rfidData;
        });
      }
    } catch (e) {
      print("Error loading user name: $e");
      setState(() {
        _userName = widget.rfidData;
      });
    }
  }

  void _incrementAmountInserted() {
    setState(() {
      coinInserted += 20; // ✅ Increment by 20
      _coinsInsertedController.text = "₱${coinInserted.toStringAsFixed(2)}"; // ✅ Update UI
    });
  }

  void _calculateTotalAmount() {
    totalAmount = 0.0;
    for (var order in widget.orders) {
      String rawPrice = order['price'] ?? '0.00';
      rawPrice = rawPrice.replaceAll('₱', '').trim();
      totalAmount += double.parse(rawPrice);
    }
  }

  Future<void> _insertTransactions() async {
    // Determine user type based on _userName.
    String userType = (_userName == widget.rfidData) ? "Guest" : "RFID User";

    for (var order in widget.orders) {
      String medicine = order['name'] ?? "Unknown";
      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      double unitPrice = (quantity != 0) ? totalCost / quantity : 0.0;

      String date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      Map<String, dynamic> transaction = {
        'medicine': medicine,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_amount': totalCost,
        'date': date,
        'payment_method': 'Cash/Coins',
        'user_type': userType,
      };

      await DatabaseHelper().insertTransaction(transaction);
    }
  }

  /// New function to update the stocks for each order.
  /// It queries the current "count" for the product, subtracts the ordered quantity,
  /// and then updates the "count" in the stocks table.
  Future<void> _updateStocksForOrders() async {
    for (var order in widget.orders) {
      final String productName = order['name'] ?? "";
      final int quantityOrdered = int.tryParse(order['quantity'] ?? "1") ?? 1;
      final db = await DatabaseHelper().db;
      final results = await db.query(
        'stocks',
        where: 'product_name = ?',
        whereArgs: [productName],
      );
      if (results.isNotEmpty) {
        final String currentCountString = results.first['count']?.toString() ?? "0";
        final int currentCount = int.tryParse(currentCountString) ?? 0;
        final int newCount = currentCount - quantityOrdered;
        // Ensure stock doesn't go negative.
        final int finalCount = newCount < 0 ? 0 : newCount;
        final Map<String, dynamic> updatedData = {
          'count': finalCount.toString(),
        };
        await DatabaseHelper().updateStock(updatedData, productName);
      }
    }
  }

  Future<void> _onProceedButtonPressed() async {
    _calculateTotalAmount(); // ✅ Ensure totalAmount is updated

    if (coinInserted >= totalAmount) { // ✅ Compare inserted amount with total amount
      await _insertTransactions();
      await _updateStocksForOrders();

      // ✅ Send medicine orders to ESP32 for dispensing
      await _usbHelper.sendOrdersToESP32(widget.orders);

      setState(() {
        coinEqualToAmount = false;
        coinInserted = 0;
        _coinsInsertedController.text = "₱0.00"; // ✅ Reset UI
      });


      // ✅ Navigate to ConfirmationScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConfirmationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Coins Inserted')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable the device back button.
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/userIcons/user_icon.png'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
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
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: widget.orders.length,
                    itemBuilder: (context, index) {
                      final orderName = widget.orders[index]['name'] ?? 'Unknown';
                      final orderQuantity = widget.orders[index]['quantity'] ?? '1';
                      final orderPrice = widget.orders[index]['price'] ?? '0.00';
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '$orderName (Qty: $orderQuantity) - ₱$orderPrice',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          softWrap: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

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

              // ✅ AMOUNT INSERTED SECTION
              const Text(
                'AMOUNT INSERTED:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _coinsInsertedController, // ✅ Dynamic controller
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Amount inserted will appear here',
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // ✅ ADD COINS BUTTON
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _incrementAmountInserted, // ✅ Increment coins
                  child: const Text('ADD ₱20'),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CANCEL button navigates back to MedicineMenu while preserving orders.
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicineMenu(
                            rfidData: widget.rfidData,
                            existingOrders: widget.orders,
                          ),
                        ),
                      );
                    },
                    child: const Text('CANCEL'),
                  ),
                  // PROCEED button processes payment, updates stock, and navigates to ConfirmationScreen.
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onProceedButtonPressed,
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
}
