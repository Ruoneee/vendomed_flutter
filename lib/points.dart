import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart';   // If you need to send orders to the ESP32
import 'splash_screen.dart'; // For session timeout redirection

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
  final USBHelper _usbHelper = USBHelper(); // For ESP32 communication if needed

  double totalAmount = 0.0;
  int pointsUsed = 0;
  int userPoints = 0;
  String _userName = "";

  // Session timeout variables
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 60;

  // Multi-language support variables
  String _currentLanguage = "en";
  final Map<String, Map<String, String>> _localizedStrings = {
    "en": {
      "redeem_points": "Please redeem your points here.",
      "inactivity_note": "After 60 seconds of inactivity,\nthis session will return to Home.",
      "session_timeout": "Session Timeout",
      "your_orders": "YOUR ORDER/S:",
      "total_amount": "TOTAL AMOUNT:",
      "points_to_redeem": "POINTS TO REDEEM:",
      "add_points": "ADD 20 Points",
      "cancel": "CANCEL",
      "proceed": "PROCEED",
      "not_enough_points": "Not Enough Points",
      "insufficient_points": "You did not redeem enough points to cover the total amount.",
      "points_error": "You do not have enough points to complete this purchase."
    },
    "fil": {
      "redeem_points": "Mangyaring gamitin ang iyong puntos dito.",
      "inactivity_note": "Pagkatapos ng 60 segundong walang aktibidad,\nibabalik ang sesyon sa Home.",
      "session_timeout": "Timeout ng Sesyon",
      "your_orders": "MGA INYONG ORDER:",
      "total_amount": "KABUUANG HALAGA:",
      "points_to_redeem": "PUNTOS NA GAGAMITIN:",
      "add_points": "IDAGDAG NG 20 Puntos",
      "cancel": "KANSELAHIN",
      "proceed": "MAG‑PROCEED",
      "not_enough_points": "Hindi Sapat na Puntos",
      "insufficient_points": "Hindi sapat ang puntos na iyong ginamit para sa kabuuang halaga.",
      "points_error": "Wala kang sapat na puntos upang makumpleto ang pagbili."
    },
  };

  /// Returns the localized string for the given key.
  String tr(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? key;
  }

  /// Toggle language between English and Filipino.
  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == "en" ? "fil" : "en";
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserData();
    // Initially set points to 0; this value will be updated once user data is loaded.
    _pointsController.text = "0";
    _startTimeout();
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
          // Auto-update redeemed points based on the total amount.
          if (userPoints >= totalAmount) {
            pointsUsed = totalAmount.toInt();
          } else {
            pointsUsed = userPoints;
          }
          _pointsController.text = pointsUsed.toString();
        });
      } else {
        setState(() {
          _userName = widget.rfidData;
          userPoints = 0;
          pointsUsed = 0;
          _pointsController.text = "0";
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() {
        _userName = widget.rfidData;
        userPoints = 0;
        pointsUsed = 0;
        _pointsController.text = "0";
      });
    }
  }

  /// Starts or restarts the inactivity timeout (60 seconds) and visible countdown.
  void _startTimeout() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _remainingSeconds = 60;
    });

    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void _incrementPointsUsed() {
    _startTimeout(); // Reset the timeout on user interaction
    // Prevent increasing redeemed points beyond the total amount.
    if (pointsUsed >= totalAmount) return;
    setState(() {
      pointsUsed += 20;
      if (pointsUsed > userPoints) {
        pointsUsed = userPoints;
      }
      // Ensure pointsUsed does not exceed totalAmount if the user has enough.
      if (userPoints >= totalAmount && pointsUsed > totalAmount) {
        pointsUsed = totalAmount.toInt();
      }
      _pointsController.text = pointsUsed.toString();
    });
  }

  /// Insert each order as a transaction into the database.
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
        // Payment is done via points so set amount_inserted to 0.
        'amount_inserted': 0,
        'date': date,
        'payment_method': 'Points',
        'user_type': userType,
      };

      await DatabaseHelper().insertTransaction(transaction);
    }
  }

  Future<void> _deductPoints(int pointsToDeduct) async {
    // Deduct points only if the user is not a guest.
    if (_userName == widget.rfidData) return;
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
    _startTimeout();
    // Check if redeemed points cover the total amount.
    if (pointsUsed >= totalAmount) {
      if (pointsUsed <= userPoints) {
        await _insertTransactions();
        await _updateStocksForOrders();
        await _deductPoints(totalAmount.toInt());
        // —— ESP32 COMMANDS ——
        await _usbHelper.sendOrdersToESP32(widget.orders);
        await _usbHelper.resetCredit();
        // ————————————————
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              orders: widget.orders,
              totalPrice: totalAmount,
            ),
          ),
        );
      } else {
        _showErrorDialog(
          title: tr("not_enough_points"),
          message: tr("points_error"),
        );
      }
    } else {
      _showErrorDialog(
        title: tr("not_enough_points"),
        message: tr("insufficient_points"),
      );
    }
  }

  /// Show an AlertDialog with larger text for errors.
  void _showErrorDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate circular countdown progress.
    double countdownProgress = 1 - (_remainingSeconds / 60.0);

    return WillPopScope(
      // Disable the device back button.
      onWillPop: () async => false,
      child: Scaffold(
        // Only the background color & AppBar changed:
        appBar: AppBar(
          // Make the AppBar show the same gradient
          backgroundColor: Colors.transparent,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white),
              onPressed: _toggleLanguage,
              tooltip: "Toggle Language",
            )
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D2A5E),
                  Color(0xFF0D2A5E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D2A5E),
                Color(0xFF1E5D6F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card for session timeout info and countdown.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions and inactivity note.
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr("redeem_points"),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tr("inactivity_note"),
                                style: const TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Session Timeout heading and Circular Countdown.
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr("session_timeout"),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: countdownProgress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                                Text(
                                  '$_remainingSeconds s',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // VendoPoints display.
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
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Order List Card.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr("your_orders"),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                                    style: const TextStyle(fontSize: 20, color: Colors.black),
                                    softWrap: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TOTAL AMOUNT label changed to white.
                Text(
                  tr("total_amount"),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // The text in the field remains black.
                TextFormField(
                  enabled: false,
                  decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    hintText: 'Total amount will appear here',
                    hintStyle: TextStyle(fontSize: 24),
                  ),
                  initialValue: '₱${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 16),
                // POINTS TO REDEEM label changed to white.
                Text(
                  tr("points_to_redeem"),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // The text in the field remains black.
                TextFormField(
                  controller: _pointsController,
                  enabled: false,
                  decoration: const InputDecoration(
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    hintText: 'Points to redeem will appear here',
                    hintStyle: TextStyle(fontSize: 24),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 16),
                // Button to add 20 points.
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _incrementPointsUsed,
                    child: Text(
                      tr("add_points"),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Navigation buttons: CANCEL and PROCEED.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        child: Text(
                          tr("cancel"),
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 100),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF0D2A5E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _onProceedButtonPressed,
                        child: Text(
                          tr("proceed"),
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
