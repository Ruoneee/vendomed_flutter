import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'payment_method.dart';
import 'splash_screen.dart';
import 'database_helper.dart';

/// Extension on PaymongoClient for creating PaymentIntents.
extension PaymentIntentExtension on PaymongoClient {
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    required List<String> paymentMethodTypes,
  }) async {
    final Map<String, dynamic> payload = {
      "data": {
        "attributes": {
          "amount": amount,
          "currency": currency,
          "payment_method_allowed": paymentMethodTypes,
        },
      },
    };

    final Uri url = Uri.parse("https://api.paymongo.com/v1/payment_intents");
    final String secretKey = "sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS";
    final String auth = base64Encode(utf8.encode("$secretKey:"));

    final http.Response response = await http.post(
      url,
      headers: {
        "Authorization": "Basic $auth",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to create PaymentIntent: ${response.body}");
    }
  }
}

/// Extension on PaymongoClient to create a static QR code.
/// NOTE: Verify the endpoint and payload with Paymongo's latest documentation.
extension StaticQrCodeExtension on PaymongoClient {
  Future<Map<String, dynamic>> createStaticQrCode({
    required int amount,
    required String currency,
    required List<String> paymentMethodTypes,
  }) async {
    final Map<String, dynamic> payload = {
      "data": {
        "attributes": {
          "amount": amount,
          "currency": currency,
          "payment_method_allowed": paymentMethodTypes,
        },
      },
    };

    // Check that this is the correct endpoint per the latest Paymongo docs.
    final Uri url = Uri.parse("https://api.paymongo.com/v1/qr_codes");
    final String secretKey = "sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS";
    final String auth = base64Encode(utf8.encode("$secretKey:"));

    final http.Response response = await http.post(
      url,
      headers: {
        "Authorization": "Basic $auth",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    // Logging response details for debugging.
    debugPrint("Static QR Code response status: ${response.statusCode}");
    debugPrint("Static QR Code response body: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to create Static QR Code: ${response.body}");
    }
  }
}

/// Main GCash Payment Page that navigates to the static QR code screen.
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Intercept back navigation.
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PaymentMethodPage(orders: orders, rfidData: rfidData),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title:
          const Text("GCash Payment", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0D2A5E),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Tap the button to generate a static QR Code for GCash payment.",
                  style: TextStyle(fontSize: 29, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaticQRPaymentScreen(
                          orders: orders,
                          medicinesToBeDisabled: medicinesToBeDisabled,
                          rfidData: rfidData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 20),
                  ),
                  child: const Text(
                    "GENERATE PAYMENT QR",
                    style: TextStyle(fontSize: 25, color: Colors.white),
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

/// Screen to display the static QR code and poll for payment status.
class StaticQRPaymentScreen extends StatefulWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;

  const StaticQRPaymentScreen({
    Key? key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  }) : super(key: key);

  @override
  _StaticQRPaymentScreenState createState() => _StaticQRPaymentScreenState();
}

class _StaticQRPaymentScreenState extends State<StaticQRPaymentScreen> {
  String? _qrImageUrl;
  String? _paymentIntentId;
  String _status = "awaiting_payment";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    // Determine user type based on RFID data.
    String userType =
    widget.rfidData.isNotEmpty ? "RFID User" : "Guest";

    // Calculate total amount (in centavos) and record transactions.
    int totalAmount = 0;
    for (var order in widget.orders) {
      String medicine = order['name'] ?? "Unknown";
      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
      totalAmount += (totalCost * 100).toInt();
      double unitPrice =
      (quantity != 0) ? totalCost / quantity : 0.0;
      String date = DateTime.now().toIso8601String();

      Map<String, dynamic> transaction = {
        "medicine": medicine,
        "quantity": quantity,
        "unit_price": unitPrice,
        "total_amount": totalCost,
        "date": date,
        "payment_method": "GCash",
        "user_type": userType,
      };

      await DatabaseHelper().insertTransaction(transaction);
      debugPrint("Inserted transaction for $medicine");
    }

    // Create a static QR Code via Paymongo.
    final paymongoClient =
    PaymongoClient("sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS");

    try {
      final staticQrResponse =
      await paymongoClient.createStaticQrCode(
        amount: totalAmount,
        currency: "PHP",
        paymentMethodTypes: ["gcash"],
      );
      // Expected response structure:
      // {
      //   "data": {
      //     "id": "pi_XXXXXXXXXXXX",
      //     "attributes": {
      //       "qr_image_url": "https://link.to/static/qr.png",
      //       ...
      //     }
      //   }
      // }
      final data = staticQrResponse["data"];
      final attributes = data["attributes"];
      setState(() {
        _qrImageUrl = attributes["qr_image_url"];
        _paymentIntentId = data["id"];
      });
      _startPolling();
    } catch (e) {
      debugPrint("Error creating Static QR Code: $e");
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    if (_paymentIntentId == null) return;
    final Uri url = Uri.parse(
        "https://api.paymongo.com/v1/payment_intents/$_paymentIntentId");
    final String secretKey = "sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS";
    final String auth = base64Encode(utf8.encode("$secretKey:"));
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
          MaterialPageRoute(
              builder: (context) => const SplashScreen()),
        );
      }
    } else {
      debugPrint("Error polling PaymentIntent: ${response.body}");
    }
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
        title: const Text("Confirming Payment"),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      body: Center(
        child: _qrImageUrl == null
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Scan the QR Code below with your GCash app to complete payment.",
                style: TextStyle(fontSize: 29, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Display the cached static QR image.
              Image.network(
                _qrImageUrl!,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text("Current status: $_status",
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
