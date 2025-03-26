import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart'; // If you need to send orders to the ESP32
import 'dart:convert';
import 'package:http/http.dart' as http;

class PointsPage extends StatefulWidget {
  final List<Map<String, String>> orders;
  final String rfidData;

  const PointsPage({
    Key? key,
    required this.orders,
    required this.rfidData,
  }) : super(key: key);

  @override
  PointsPageState createState() => PointsPageState();
}

class PointsPageState extends State<PointsPage> {
  final TextEditingController _pointsController = TextEditingController();
  final USBHelper _usbHelper = USBHelper(); // If you need to send data to ESP32

  double totalAmount = 0.0;
  int pointsUsed = 0;   // How many points the user wants to redeem
  int userPoints = 0;   // User's current VendoPoints
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserData();
    // Initialize the points redeemed display
    _pointsController.text = "0";
  }

  /// Calculate total amount from the orders
  void _calculateTotalAmount() {
    double tempTotal = 0.0;
    for (var order in widget.orders) {
      String rawPrice = order['price'] ?? '0.00';
      rawPrice = rawPrice.replaceAll('₱', '').trim();
      tempTotal += double.parse(rawPrice);
    }
    setState(() {
      totalAmount = tempTotal;
    });
  }

  /// Load user name and current points from DB
  Future<void> _loadUserData() async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['NAME', 'POINTS'],
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );

      if (result.isNotEmpty) {
        setState(() {
          _userName = result.first['NAME']?.toString() ?? widget.rfidData;
          userPoints = int.tryParse(result.first['POINTS']?.toString() ?? '0') ?? 0;
        });
      } else {
        // If no user found, treat as Guest
        setState(() {
          _userName = widget.rfidData;
          userPoints = 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() {
        _userName = widget.rfidData;
        userPoints = 0;
      });
    }
  }

  /// Increment the pointsUsed by 20 (up to userPoints)
  void _incrementPointsUsed() {
    setState(() {
      pointsUsed += 20;
      // Make sure we don't exceed userPoints
      if (pointsUsed > userPoints) {
        pointsUsed = userPoints;
      }
      _pointsController.text = pointsUsed.toString();
    });
  }

  /// Insert each order as a transaction into DB
  Future<void> _insertTransactions() async {
    // "RFID User" or "Guest"
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
        'payment_method': 'Points',
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

  /// Deduct used points from user's total
  Future<void> _deductPoints(int pointsToDeduct) async {
    // If user is a guest, do nothing
    if (_userName == widget.rfidData) {
      return;
    }
    try {
      final db = await DatabaseHelper().db;
      // Subtract points from DB
      final newPoints = userPoints - pointsToDeduct;
      await DatabaseHelper.instance.updateUserByRFID(
        {'POINTS': newPoints.toString()},
        widget.rfidData,
      );
    } catch (e) {
      debugPrint("Error deducting points: $e");
    }
  }

  /// Called when user taps PROCEED
  Future<void> _onProceedButtonPressed() async {
    // Check if user is redeeming enough points to cover total
    if (pointsUsed >= totalAmount) {
      // Also check if user actually has that many points
      if (pointsUsed <= userPoints) {
        // 1) Insert transactions, update stocks, etc.
        await _insertTransactions();
        await _updateStocksForOrders();
        // If you need to send orders to ESP32, uncomment:
        // await _usbHelper.sendOrdersToESP32(widget.orders);

        // 2) Deduct points from user's account
        await _deductPoints(totalAmount.toInt()); // totalAmount is double; cast to int

        // 3) Navigate to ConfirmationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfirmationScreen()),
        );
      } else {
        // Not enough total points
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have enough points!')),
        );
      }
    } else {
      // Not enough points used to cover total
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Points Redeemed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // If you want to disable the back button or customize it, do so here
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          // Custom back arrow that returns to MedicineMenu with existing orders
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
          ),
          title: Row(
            children: [
              const SizedBox(width: 10),
              Text(
                "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF7EAF0),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Show VendoPoints above "YOUR ORDER/S"
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0D2A5E),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "VendoPoints: $userPoints",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2) "YOUR ORDER/S" section
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
                height: 250,
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

              // 3) TOTAL AMOUNT
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

              // 4) POINTS TO REDEEM
              const Text(
                'POINTS TO REDEEM:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pointsController,
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Points to redeem will appear here',
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // 5) ADD POINTS BUTTON
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _incrementPointsUsed,
                  child: const Text('ADD 20 Points'),
                ),
              ),
              const SizedBox(height: 20),

              // 6) CANCEL / PROCEED Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CANCEL button
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
                  // PROCEED button
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
