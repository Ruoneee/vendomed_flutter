import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'database_helper.dart';
import 'splash_screen.dart';
import 'medicine_menu.dart';

class GCashPaymentPage extends StatelessWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;

  const GCashPaymentPage({
    Key? key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  }) : super(key: key);

  Future<void> _insertTransactions() async {
    String userType = (rfidData.isNotEmpty) ? "RFID User" : "Guest";

    for (var order in orders) {
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
        'payment_method': 'GCash',
        'user_type': userType,
      };

      await DatabaseHelper.instance.insertTransaction(transaction);
    }
  }

  Future<void> _updateStocksForOrders() async {
    for (var order in orders) {
      final String productName = order['name'] ?? "";
      final int quantityOrdered = int.tryParse(order['quantity'] ?? "1") ?? 1;
      final db = await DatabaseHelper.instance.db;
      final results = await db.query(
        'stocks',
        where: 'product_name = ?',
        whereArgs: [productName],
      );
      if (results.isNotEmpty) {
        final String currentCountString =
            results.first['count']?.toString() ?? "0";
        final int currentCount = int.tryParse(currentCountString) ?? 0;
        final int newCount = currentCount - quantityOrdered;
        final int finalCount = newCount < 0 ? 0 : newCount;
        final Map<String, dynamic> updatedData = {
          'count': finalCount.toString(),
        };
        await DatabaseHelper.instance.updateStock(updatedData, productName);
      }
    }
  }

  Future<void> _onPaymentCompleted(BuildContext context) async {
    await _insertTransactions();
    await _updateStocksForOrders();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
  }

  int _calculateTotalAmount() {
    int totalAmount = 0;
    for (var order in orders) {
      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      totalAmount += (totalCost * 100).toInt();
    }
    return totalAmount;
  }

  Future<void> _processPayment(BuildContext context) async {
    int totalAmount = _calculateTotalAmount();
    final String secretKey = "sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS";
    final String auth = base64Encode(utf8.encode("$secretKey:"));

    final Map<String, dynamic> payload = {
      "data": {
        "attributes": {
          "amount": totalAmount,
          "currency": "PHP",
          "payment_method_allowed": ["gcash"],
        },
      },
    };

    final Uri url = Uri.parse("https://api.paymongo.com/v1/payment_intents");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Basic $auth",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final paymentIntent = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint("PaymentIntent response: $paymentIntent");

        final data = paymentIntent["data"];
        final attributes = data["attributes"];

        String qrData = "";
        if (attributes["next_action"] != null &&
            attributes["next_action"]["redirect"] != null &&
            attributes["next_action"]["redirect"]["url"] != null) {
          qrData = attributes["next_action"]["redirect"]["url"];
        } else {
          qrData = attributes["client_key"] ?? "";
        }

        final paymentIntentId = data["id"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PollingPaymentScreen(
              paymentIntentId: paymentIntentId,
              qrData: qrData,
              orders: orders,
              rfidData: rfidData,
            ),
          ),
        );
      } else {
        throw Exception("Failed to create PaymentIntent: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error processing payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing payment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'GCASH Payment',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineMenu(
                    rfidData: rfidData,
                    existingOrders: orders,
                  ),
                ),
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFF7EAF0),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () async {
                    await _processPayment(context);
                  },
                  child: const Text(
                    "PROCEED WITH PAYMENT",
                    style: TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () async {
                    await _onPaymentCompleted(context);
                  },
                  child: const Text(
                    "PAYMENT COMPLETED",
                    style: TextStyle(fontSize: 25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PollingPaymentScreen extends StatefulWidget {
  final String paymentIntentId;
  final String qrData;
  final List<Map<String, String>> orders;
  final String rfidData;

  const PollingPaymentScreen({
    Key? key,
    required this.paymentIntentId,
    required this.qrData,
    required this.orders,
    required this.rfidData,
  }) : super(key: key);

  @override
  _PollingPaymentScreenState createState() => _PollingPaymentScreenState();
}

class _PollingPaymentScreenState extends State<PollingPaymentScreen> {
  Timer? _timer;
  String _status = "awaiting_payment";

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _pollPaymentStatus() async {
    final String secretKey = "sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS";
    final String auth = base64Encode(utf8.encode("$secretKey:"));
    final Uri url = Uri.parse("https://api.paymongo.com/v1/payment_intents/${widget.paymentIntentId}");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Basic $auth",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final status = result["data"]["attributes"]["status"];
        setState(() {
          _status = status;
        });
        if (status == "paid") {
          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          );
        }
      } else {
        debugPrint("Error polling PaymentIntent: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error polling PaymentIntent: $e");
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollPaymentStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2A5E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Confirming Payment",
          style: TextStyle(color: Colors.white),
        ),
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
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Scan the QR Code with your GCash app to proceed with payment.",
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: 300.0,
              ),
              const SizedBox(height: 20),
              Text("Current status: $_status", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
