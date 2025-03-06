import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paymongo_sdk/paymongo_sdk.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'payment_method.dart';
import 'splash_screen.dart';
import 'database_helper.dart';

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
                  "Scan the generated QR Code with your GCash app to complete payment.",
                  style: TextStyle(fontSize: 29, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Determine user type based on RFID data.
                    String userType =
                    (rfidData.isNotEmpty) ? "RFID User" : "Guest";

                    // Calculate total amount (in centavos) and record transactions.
                    int totalAmount = 0;
                    for (var order in orders) {
                      String medicine = order['name'] ?? "Unknown";
                      int quantity =
                          int.tryParse(order['quantity'] ?? "1") ?? 1;
                      double totalCost =
                          double.tryParse(order['price'] ?? "0.00") ?? 0.0;
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
                    }

                    // Create a PaymentIntent via Paymongo.
                    // WARNING: In production, do NOT expose your secret key on the client.
                    final paymongoClient =
                    PaymongoClient("sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS");

                    try {
                      final paymentIntent = await paymongoClient.createPaymentIntent(
                        amount: totalAmount,
                        currency: "PHP",
                        paymentMethodTypes: ["gcash"],
                      );
                      debugPrint("PaymentIntent response: $paymentIntent");

                      // Extract the redirect URL and PaymentIntent ID.
                      final data = paymentIntent["data"];
                      final attributes = data["attributes"];
                      final nextAction = attributes["next_action"];
                      final redirectUrl = (nextAction != null &&
                          nextAction["redirect"] != null)
                          ? nextAction["redirect"]["url"]
                          : "";
                      final paymentIntentId = data["id"];

                      if (redirectUrl != "") {
                        // Navigate to the polling screen.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PollingPaymentScreen(
                              paymentIntentId: paymentIntentId,
                              redirectUrl: redirectUrl,
                            ),
                          ),
                        );
                      } else {
                        debugPrint("No redirect URL found in PaymentIntent response");
                      }
                    } catch (e) {
                      debugPrint("Error creating PaymentIntent: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
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

/// Extension on PaymongoClient to add a helper for creating PaymentIntents.
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

/// A screen that polls the PaymentIntent status periodically.
class PollingPaymentScreen extends StatefulWidget {
  final String paymentIntentId;
  final String redirectUrl;

  const PollingPaymentScreen({
    Key? key,
    required this.paymentIntentId,
    required this.redirectUrl,
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

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _pollPaymentStatus();
    });
  }

  Future<void> _pollPaymentStatus() async {
    final Uri url = Uri.parse(
        "https://api.paymongo.com/v1/payment_intents/${widget.paymentIntentId}");
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
          MaterialPageRoute(builder: (context) => const SplashScreen()),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Awaiting Payment Confirmation...", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            // Wrap QrImageView in a Container to set its size.
            Container(
              width: 300,
              height: 300,
              child: QrImageView(data: widget.redirectUrl),
            ),
            const SizedBox(height: 20),
            Text("Current status: $_status", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
