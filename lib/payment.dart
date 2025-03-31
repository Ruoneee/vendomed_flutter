import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'confirmation_screen.dart';
import 'database_helper.dart';
import 'medicine_menu.dart'; // To navigate back with existing orders
import 'usb_helper.dart'; // Import USB Helper
import 'splash_screen.dart'; // Make sure you have a SplashScreen widget
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
  String errorMessage = "";

  // Timers for countdown and auto-timeout
  Timer? _timeoutTimer;
  Timer? _countdownTimer;

  // We'll give the user 60 seconds
  int _remainingSeconds = 60;

  StreamSubscription<int>? _creditSubscription;

  // Multi-language support: current language code ("en" or "fil")
  String _currentLanguage = "en";

  // Translation map
  final Map<String, Map<String, String>> _localizedStrings = {
    "en": {
      "insert_coins":
      "Please insert cash/coins.\nAccepted denominations: ₱20, ₱50, ₱100",
      "inactivity_note":
      "After 60 seconds of inactivity,\nthis session will return to Home.",
      "session_timeout": "Session Timeout",
      "your_orders": "YOUR ORDER/S:",
      "total": "TOTAL:",
      "inserted": "INSERTED:",
      "remaining": "Remaining:",
      "cancel": "CANCEL",
      "proceed": "PROCEED",
      "add_amount": "ADD ₱20",
      "points_earned": "Points Earned!",
      "you_earned": "You earned {points} extra points!"
    },
    "fil": {
      "insert_coins":
      "Mangyaring ipasok ang salapi/pera.\nTinanggap na halaga: ₱20, ₱50, ₱100",
      "inactivity_note":
      "Pagkatapos ng 60 segundong walang aktibidad,\nibabalik ang sesyon sa Home.",
      "session_timeout": "Timeout ng Sesyon",
      "your_orders": "MGA INYONG ORDER:",
      "total": "KABUUAN:",
      "inserted": "IPINASOK:",
      "remaining": "Natitira:",
      "cancel": "KANSelahin",
      "proceed": "MAG‑PROCEED",
      "add_amount": "IDAGDAG ₱20",
      "points_earned": "Mga Nakuhang Punto!",
      "you_earned": "Nakakuha ka ng {points} karagdagang punto!"
    },
  };

  /// Returns the localized string for the given key.
  String tr(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? key;
  }

  /// Toggles the language between English and Filipino.
  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == "en" ? "fil" : "en";
    });
  }

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
      // Restart the countdown timer whenever new valid input is received
      _startTimeout();
      setState(() {
        coinInserted = newCredit;
        _coinsInsertedController.text = "₱${coinInserted.toStringAsFixed(2)}";
      });
    });

    // Start the initial timeout & countdown
    _startTimeout();
  }

  /// Starts or restarts the inactivity timeout (60 seconds) and the visible countdown.
  void _startTimeout() {
    // Cancel any existing timers
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    // Reset the visible countdown to 60 seconds
    setState(() {
      _remainingSeconds = 60;
    });

    // One-shot timer for the 60-second timeout
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    });

    // Periodic timer to update the visible countdown every second
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

  /// Resets the transaction and optionally shows an error message.
  void _resetTransaction(String message) {
    setState(() {
      coinInserted = 0;
      _coinsInsertedController.text = "₱0.00";
      errorMessage = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        errorMessage = "";
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

  /// Increments the coinInserted by 20 and restarts the timeout.
  void _incrementAmountInserted() {
    _startTimeout(); // Reset timer on valid input
    setState(() {
      coinInserted += 20;
      _coinsInsertedController.text = "₱${coinInserted.toStringAsFixed(2)}";
    });
  }

  /// This function handles an invalid bill event.
  /// (Not triggered by a visible button in the UI but available for hardware input.)
  void _simulateInvalidBill() {
    _startTimeout(); // Reset timer on input
    setState(() {
      errorMessage = "Unrecognized bill/coin inserted. Please use accepted denominations.";
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        errorMessage = "";
      });
    });
  }

  /// Calculate total amount from the orders.
  void _calculateTotalAmount() {
    totalAmount = 0.0;
    for (var order in widget.orders) {
      String rawPrice = order['price'] ?? '0.00';
      rawPrice = rawPrice.replaceAll('₱', '').trim();
      totalAmount += double.parse(rawPrice);
    }
  }

  /// Insert each order as a transaction into the DB.
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
        'payment_method': 'Cash/Coins',
        'user_type': userType,
        'amount_inserted': coinInserted,
      };
      await DatabaseHelper().insertTransaction(transaction);
    }
  }

  /// Update the stock count for each ordered product.
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

  /// Award extra points for any overpayment (only for RFID users).
  Future<int> _awardPoints(double difference) async {
    if (_userName == widget.rfidData) {
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
      int additionalPoints = difference.floor();
      int newPoints = oldPoints + additionalPoints;
      await DatabaseHelper.instance.updateUserByRFID(
        {'POINTS': newPoints.toString()},
        widget.rfidData,
      );
      return additionalPoints;
    } catch (e) {
      debugPrint("Error awarding points: $e");
      return 0;
    }
  }

  /// Called when user taps the PROCEED button.
  Future<void> _onProceedButtonPressed() async {
    _calculateTotalAmount();
    if (coinInserted >= totalAmount) {
      int pointsAwarded = 0;
      if (coinInserted > totalAmount) {
        double difference = coinInserted - totalAmount;
        pointsAwarded = await _awardPoints(difference);
      }
      await _insertTransactions();
      await _updateStocksForOrders();
      await _usbHelper.sendOrdersToESP32(widget.orders);
      await _usbHelper.resetCredit();
      setState(() {
        coinInserted = 0;
        _coinsInsertedController.text = "₱0.00";
      });
      if (pointsAwarded > 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            Future.delayed(const Duration(seconds: 3), () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmationScreen(
                    orders: widget.orders,
                    totalPrice: totalAmount,
                  ),
                ),
              );
            });
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Center(
                child: Text(
                  tr("points_earned"),
                  style: TextStyle(
                    fontSize: 32,
                    color: const Color(0xFF0D2A5E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 140,
                child: Center(
                  child: Text(
                    tr("you_earned").replaceAll("{points}", pointsAwarded.toString()),
                    style: const TextStyle(fontSize: 26, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              orders: widget.orders,
              totalPrice: totalAmount,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("insufficient"))),
      );
    }
  }

  @override
  void dispose() {
    _creditSubscription?.cancel();
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _coinsInsertedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progressValue = 0.0;
    if (totalAmount > 0) {
      progressValue = coinInserted / totalAmount;
      if (progressValue.isNaN || progressValue.isInfinite) {
        progressValue = 0.0;
      }
      progressValue = progressValue.clamp(0.0, 1.0);
    }
    double remainingBalance = (totalAmount - coinInserted) < 0
        ? 0
        : totalAmount - coinInserted;
    double countdownProgress = 1 - (_remainingSeconds / 60.0);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Text(
            "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white),
              onPressed: _toggleLanguage,
              tooltip: "Toggle Language",
            )
          ],
        ),
        // Use a Container with gradient background.
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
                // Merged Card for Session Timeout and Denomination Info in a Row
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Instructions & Note
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr("insert_coins"),
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
                        // Right side: Timeout heading + Circular Countdown
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
                const SizedBox(height: 20),
                // Card for Order List
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: Scrollbar(
                            child: ListView.builder(
                              itemCount: widget.orders.length,
                              itemBuilder: (context, index) {
                                final orderName = widget.orders[index]['name'] ?? 'Unknown';
                                final orderQuantity = widget.orders[index]['quantity'] ?? '1';
                                final orderPrice = widget.orders[index]['price'] ?? '0.00';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '$orderName (Qty: $orderQuantity) - ₱$orderPrice',
                                    style: const TextStyle(fontSize: 20),
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
                const SizedBox(height: 20),
                // Enlarged Card for Payment Information
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Display Total Amount with larger text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₱${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Display Inserted Amount with larger text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'INSERTED:',
                              style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _coinsInsertedController.text,
                              style: const TextStyle(fontSize: 33, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Thicker Progress Bar
                        LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 16,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        // Display Remaining Balance with enlarged text
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${tr("remaining")} ₱${remainingBalance.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Display error message if any
                        if (errorMessage.isNotEmpty)
                          Center(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Button for adding cash/coins.
                Center(
                  child: Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _incrementAmountInserted,
                        child: Text(
                          tr("add_amount"),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Navigation buttons: CANCEL and PROCEED.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    const SizedBox(width: 120),
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF0D2A5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
