import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart'; // Import USB Helper
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
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
  final TextEditingController _coinsInsertedController = TextEditingController();
  final USBHelper _usbHelper = USBHelper(); // Global instance

  int coinInserted = 0;
  double totalAmount = 0.0;
  String _userName = "";
  StreamSubscription<int>? _creditSubscription;

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserName();
    _usbHelper.initUSB(); // Ensure connection persists

    // Initialize the amount inserted display
    _coinsInsertedController.text = "₱0.00";

    // Subscribe to the credit stream from the ESP32
    _creditSubscription = _usbHelper.creditStream.listen((int newCredit) {
      setState(() {
        coinInserted = newCredit;
        _coinsInsertedController.text = "₱${coinInserted.toStringAsFixed(2)}";
      });
    });
  }

  /// Load the user's name from the DB. If no match, treat as Guest.
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
        // If no user found, treat as Guest
        setState(() {
          _userName = widget.rfidData;
        });
      }
    } catch (e) {
      debugPrint("Error loading user name: $e");
      setState(() {
        _userName = widget.rfidData;
      });
    }
  }

  /// Increment the coinInserted by 20
  void _incrementAmountInserted() {
    setState(() {
      coinInserted += 20;
      _coinsInsertedController.text = "₱${coinInserted.toStringAsFixed(2)}";
    });
  }

  /// Calculate total amount from the orders
  void _calculateTotalAmount() {
    totalAmount = 0.0;
    for (var order in widget.orders) {
      String rawPrice = order['price'] ?? '0.00';
      rawPrice = rawPrice.replaceAll('₱', '').trim();
      totalAmount += double.parse(rawPrice);
    }
  }

  /// Insert each order as a transaction into DB
  Future<void> _insertTransactions() async {
    // Determine user type based on _userName
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

  /// Update the stock count for each ordered product
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
        final int finalCount = newCount < 0 ? 0 : newCount;
        final Map<String, dynamic> updatedData = {
          'count': finalCount.toString(),
        };
        await DatabaseHelper().updateStock(updatedData, productName);
      }
    }
  }

  /// Returns how many points were actually awarded (0 if none).
  Future<int> _awardPoints(double difference) async {
    // If user is a guest, skip awarding points
    if (_userName == widget.rfidData) {
      // Means we didn't find them in the DB => treat as Guest => no points
      return 0;
    }

    try {
      final db = await DatabaseHelper.instance.db;
      final result = await db.query(
        'users',
        columns: ['POINTS'],
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );
      int oldPoints = 0;
      if (result.isNotEmpty) {
        oldPoints = int.tryParse(result.first['POINTS']?.toString() ?? '0') ?? 0;
      }
      // 1:1 ratio => difference.floor() points
      int additionalPoints = difference.floor();
      int newPoints = oldPoints + additionalPoints;
      await DatabaseHelper.instance.updateUserByRFID(
        {'POINTS': newPoints.toString()},
        widget.rfidData,
      );

      return additionalPoints;
    } catch (e) {
      debugPrint("Error awarding points: $e");
      return 0; // Return 0 if something goes wrong
    }
  }

  /// Called when user taps PROCEED
  Future<void> _onProceedButtonPressed() async {
    _calculateTotalAmount();

    // Check if user inserted enough coins
    if (coinInserted >= totalAmount) {
      // 1) If user overpaid, award points
      int pointsAwarded = 0;
      if (coinInserted > totalAmount) {
        double difference = coinInserted - totalAmount;
        pointsAwarded = await _awardPoints(difference);
      }

      // 2) Process transaction steps
      await _insertTransactions();
      await _updateStocksForOrders();
      await _usbHelper.sendOrdersToESP32(widget.orders);

      // 3) Reset the inserted coin amount
      await _usbHelper.resetCredit();
      setState(() {
        coinInserted = 0;
        _coinsInsertedController.text = "₱0.00";
      });

      // 4) If points awarded, show a 3-second pop-up, then auto-navigate
      if (pointsAwarded > 0) {
        showDialog(
          context: context,
          barrierDismissible: false, // user cannot dismiss by tapping outside
          builder: (context) {
            // After 3 seconds, close the dialog and go to Confirmation
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ConfirmationScreen()),
              );
            });

            // A larger, styled AlertDialog with bigger text
            return AlertDialog(
              // Rounded corners
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                "Points Earned!",
                style: TextStyle(
                  fontSize: 32, // Larger title font
                  color: const Color(0xFF0D2A5E),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 140,
                child: Center(
                  child: Text(
                    "You earned $pointsAwarded extra points!",
                    style: const TextStyle(
                      fontSize: 26, // Larger content font
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        // If no points awarded or user didn't overpay, go directly
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfirmationScreen()),
        );
      }
    } else {
      // Not enough coins
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Coins Inserted')),
      );
    }
  }

  @override
  void dispose() {
    _creditSubscription?.cancel();
    _coinsInsertedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable the device back button
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Text(
            "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFF7EAF0),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // YOUR ORDER/S (Larger label)
              const Text(
                'YOUR ORDER/S:',
                style: TextStyle(
                  fontSize: 22, // Increased
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
                            fontSize: 20, // Increased
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

              // TOTAL AMOUNT (Larger label & text field)
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 24, // Larger
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1), // Thinner border
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  hintText: 'Total amount will appear here',
                  hintStyle: TextStyle(fontSize: 24),
                ),
                initialValue: '₱${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24, // Larger text
                ),
              ),
              const SizedBox(height: 20),

              // AMOUNT INSERTED (Larger label & text field)
              const Text(
                'AMOUNT INSERTED:',
                style: TextStyle(
                  fontSize: 24, // Larger
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _coinsInsertedController,
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1), // Thinner border
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  hintText: 'Amount inserted will appear here',
                  hintStyle: TextStyle(fontSize: 24),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24, // Larger text
                ),
              ),
              const SizedBox(height: 20),

              // ADD COINS BUTTON (Larger text)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _incrementAmountInserted,
                  child: const Text(
                    'ADD ₱20',
                    style: TextStyle(fontSize: 20), // Larger text
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CANCEL / PROCEED Buttons (Larger text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CANCEL button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontSize: 20), // Larger text
                    ),
                  ),
                  // PROCEED button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Color(0xFF0D2A5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onProceedButtonPressed,
                    child: const Text(
                      'PROCEED',
                      style: TextStyle(fontSize: 20), // Larger text
                    ),
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
