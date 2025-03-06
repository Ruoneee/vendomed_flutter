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
        debugPrint("GCashPaymentPage: Device back button or app bar back pressed. Going to PaymentMethodPage.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodPage(orders: orders, rfidData: rfidData),
          ),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text("GCash Payment", style: TextStyle(color: Colors.white)),
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
                    String userType = (rfidData.isNotEmpty) ? "RFID User" : "Guest";

                    // Calculate total amount (in centavos) and record transactions.
                    int totalAmount = 0;
                    for (var order in orders) {
                      String medicine = order['name'] ?? "Unknown";
                      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;
                      double totalCost = double.tryParse(order['price'] ?? "0.00") ?? 0.0;
                      totalAmount += (totalCost * 100).toInt(); // Convert PHP to centavos
                      double unitPrice = (quantity != 0) ? totalCost / quantity : 0.0;
                      String date = DateTime.now().toIso8601String();

                      Map<String, dynamic> transaction = {
                        'medicine': medicine,
                        'quantity': quantity,
                        'unit_price': unitPrice,
                        'total_amount': totalCost,
                        'date': date,
                        'payment_method': 'GCash',
                        'user_type': userType,
                      };

                      await DatabaseHelper().insertTransaction(transaction);
                    }

                    // Create a PaymongoClient instance using your secret key.
                    // WARNING: In production, do NOT expose your secret key on the client.
                    final paymongoClient = PaymongoClient('sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS');

                    try {
                      // Use the extension method to create a PaymentIntent.
                      final paymentIntent = await paymongoClient.createPaymentIntent(
                        amount: totalAmount,
                        currency: 'PHP',
                        paymentMethodTypes: ['gcash'],
                      );
                      debugPrint("PaymentIntent response: $paymentIntent");

                      // Extract the redirect URL from the PaymentIntent response.
                      // (Assumes the response structure contains data > attributes > next_action > redirect > url)
                      final data = paymentIntent['data'];
                      final attributes = data['attributes'];
                      final nextAction = attributes['next_action'];
                      final redirectUrl = nextAction != null ? nextAction['redirect']?['url'] : null;

                      if (redirectUrl != null) {
                        // Navigate to a screen that displays the dynamic QR code.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GCashQRCodeScreen(url: redirectUrl),
                          ),
                        );
                      } else {
                        debugPrint("No redirect URL found in PaymentIntent response");
                      }
                    } catch (e) {
                      debugPrint("Error creating PaymentIntent: $e");
                      // Optionally, display an error message to the user.
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
                  ),
                  child: const Text("GENERATE PAYMENT QR", style: TextStyle(fontSize: 25, color: Colors.white)),
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
  /// Creates a PaymentIntent by making an HTTP POST request to Paymongo's API.
  /// Returns the response as a Map<String, dynamic>.
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    required List<String> paymentMethodTypes,
  }) async {
    final payload = {
      "data": {
        "attributes": {
          "amount": amount,
          "currency": currency,
          "payment_method_allowed": paymentMethodTypes,
        }
      }
    };

    final url = Uri.parse('https://api.paymongo.com/v1/payment_intents');
    final secretKey = 'sk_test_KA5UFDB3xNJCF4ev4tZ2b4fS';
    final auth = base64Encode(utf8.encode('$secretKey:'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create PaymentIntent: ${response.body}');
    }
  }
}

/// A screen that displays a dynamic QR code for the provided URL.
class GCashQRCodeScreen extends StatelessWidget {
  final String url;
  const GCashQRCodeScreen({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GCash Payment QR Code"),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      body: Center(
        child: QrImageView(
          data: url,
          version: QrVersions.auto,
          size: 300.0,
        ),
      ),
    );
  }
}
