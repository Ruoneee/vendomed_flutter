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
  // For displaying how many points the user is redeeming
  final TextEditingController _pointsController = TextEditingController();

  // If you need to communicate with the ESP32 (e.g., vend a product)
  final USBHelper _usbHelper = USBHelper();

  // The total cost of the user’s orders
  double totalAmount = 0.0;

  // How many points the user is choosing to redeem
  int pointsUsed = 0;

  // How many points the user currently has in the DB
  int userPoints = 0;

  // The user’s name (or their RFID if no record)
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserData();
    // Start with "0" in the "Points to Redeem" field
    _pointsController.text = "0";
  }

  /// Sums up the prices in widget.orders to get totalAmount
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

  /// Loads the user’s NAME and POINTS from the 'users' table by RFID
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
        // If no user record is found, treat them as a Guest
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

  /// Increments the redeemed points by 20, not exceeding userPoints
  void _incrementPointsUsed() {
    setState(() {
      pointsUsed += 20;
      if (pointsUsed > userPoints) {
        pointsUsed = userPoints; // Don’t exceed total userPoints
      }
      _pointsController.text = pointsUsed.toString();
    });
  }

  /// Inserts each order as a transaction (with payment_method = 'Points')
  Future<void> _insertTransactions() async {
    String userType = (_userName == widget.rfidData) ? "Guest" : "RFID User";

    for (var order in widget.orders) {
      final String medicine = order['name'] ?? "Unknown";
      final int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
      final double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      final double unitPrice = (quantity != 0) ? totalCost / quantity : 0.0;
      final String date = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final transaction = {
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

  /// Deduct the used points from the user’s DB record
  Future<void> _deductPoints(int pointsToDeduct) async {
    // If user is Guest, do nothing
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

  /// Decrements stock in DB for each ordered item
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
        final int finalCount = (newCount < 0) ? 0 : newCount;
        await DatabaseHelper().updateStock(
          {'count': finalCount.toString()},
          productName,
        );
      }
    }
  }

  /// Called when user taps PROCEED
  Future<void> _onProceedButtonPressed() async {
    // Check if the user is redeeming enough points to cover totalAmount
    if (pointsUsed >= totalAmount) {
      // Also ensure user actually has that many points
      if (pointsUsed <= userPoints) {
        // 1) Insert transactions, update stock, etc.
        await _insertTransactions();
        await _updateStocksForOrders();

        // 2) Deduct from user’s DB points
        // totalAmount is double, so we convert to int
        await _deductPoints(totalAmount.toInt());

        // 3) If you need to vend a product, e.g., using ESP32:
        // await _usbHelper.sendOrdersToESP32(widget.orders);

        // 4) Navigate to a Confirmation page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConfirmationScreen()),
        );
      } else {
        // Not enough total user points
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have enough points!')),
        );
      }
    } else {
      // The user didn't redeem enough points to cover the cost
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Points Redeemed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // If you want to disable or override the back button behavior, do so here
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          // Custom back arrow that returns to MedicineMenu with existing orders
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Navigate back to MedicineMenu, preserving the user’s orders
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
              // 1) Show current VendoPoints
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

              // 2) YOUR ORDER/S
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
                      // Return to MedicineMenu with orders
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
