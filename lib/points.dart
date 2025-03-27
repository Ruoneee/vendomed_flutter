import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart';   // If you need to send orders to the ESP32

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
  final USBHelper _usbHelper = USBHelper(); // If you need to communicate with ESP32

  double totalAmount = 0.0;
  int pointsUsed = 0;
  int userPoints = 0;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserData();
    _pointsController.text = "0";
  }

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

  void _incrementPointsUsed() {
    setState(() {
      pointsUsed += 20;
      if (pointsUsed > userPoints) {
        pointsUsed = userPoints;
      }
      _pointsController.text = pointsUsed.toString();
    });
  }

  Future<void> _insertTransactions() async {
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

  Future<void> _deductPoints(int pointsToDeduct) async {
    if (_userName == widget.rfidData) {
      return;
    }
    try {
      final newPoints = userPoints - pointsToDeduct;
      await DatabaseHelper.instance.updateUserByRFID(
        {'POINTS': newPoints.toString()},
        widget.rfidData,
      );
    } catch (e) {
      debugPrint("Error deducting points: $e");
    }
  }

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
        final currentCountString = results.first['count']?.toString() ?? "0";
        final int currentCount = int.tryParse(currentCountString) ?? 0;
        final int newCount = currentCount - quantityOrdered;
        final int finalCount = newCount < 0 ? 0 : newCount;
        await DatabaseHelper().updateStock({'count': finalCount.toString()}, productName);
      }
    }
  }

  Future<void> _onProceedButtonPressed() async {
    if (pointsUsed >= totalAmount) {
      if (pointsUsed <= userPoints) {
        await _insertTransactions();
        await _updateStocksForOrders();
        await _deductPoints(totalAmount.toInt());
        // If needed, send orders to the ESP32:
        // await _usbHelper.sendOrdersToESP32(widget.orders);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfirmationScreen()),
        );
      } else {
        _showErrorDialog(
          title: "Not Enough Points",
          message: "You do not have enough points to complete this purchase.",
        );
      }
    } else {
      _showErrorDialog(
        title: "Insufficient Points Redeemed",
        message: "You did not redeem enough points to cover the total amount.",
      );
    }
  }

  /// A helper method to show a simple AlertDialog with bigger text
  void _showErrorDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 22, // Larger title
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 20, // Larger content
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 20), // Make OK text bigger
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // If you want to disable or override the device back button, do so here
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
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
              // Current vendopoints
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

              // YOUR ORDER/S (Larger text)
              const Text(
                'YOUR ORDER/S:',
                style: TextStyle(
                  fontSize: 22,  // Increased from 16
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
                            fontSize: 20, // Increased from 16
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

              // TOTAL AMOUNT (Increased text size, thinner border)
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1),
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
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),

              // POINTS TO REDEEM (Increased text size, thinner border)
              const Text(
                'POINTS TO REDEEM:',
                style: TextStyle(
                  fontSize: 24,
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
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  hintText: 'Points to redeem will appear here',
                  hintStyle: TextStyle(fontSize: 24),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),

              // ADD POINTS BUTTON (Larger text)
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
                  onPressed: _incrementPointsUsed,
                  child: const Text(
                    'ADD 20 Points',
                    style: TextStyle(fontSize: 20), // Larger
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CANCEL / PROCEED Buttons (Larger text)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      style: TextStyle(fontSize: 20), // Larger
                    ),
                  ),
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
                      style: TextStyle(fontSize: 20), // Larger
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
