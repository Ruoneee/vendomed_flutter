import 'dart:async';
import 'package:flutter/material.dart';
import 'payment_method.dart'; // Ensure this import is correct

class GCashPaymentPage extends StatefulWidget {
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
  _GCashPaymentPageState createState() => _GCashPaymentPageState();
}

class _GCashPaymentPageState extends State<GCashPaymentPage> {
  double? amountPaid;
  String? transactionId;
  bool paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    _trackPayment();
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var order in widget.orders) {
      // Remove currency symbol (e.g., '₱') and any whitespace.
      String priceString = order['price']!.replaceAll('₱', '').trim();
      total += double.tryParse(priceString) ?? 0.0;
    }
    return total;
  }

  Future<void> _trackPayment() async {
    // Simulate waiting for a payment response.
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      // In a real integration, these values would come from the GCash API response.
      amountPaid = _calculateTotalAmount();
      transactionId = "TX1234567890";
      paymentSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _calculateTotalAmount();

    return WillPopScope(
      onWillPop: () async {
        // Navigate back to PaymentMethodPage without clearing orders.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentMethodPage(
              orders: widget.orders,
              rfidData: widget.rfidData,
            ),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "GCash Payment",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D2A5E),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Purchased Items List
                const Text(
                  "Purchased Items:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Scrollbar(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: widget.orders.length,
                      itemBuilder: (context, index) {
                        return Text(
                          '${widget.orders[index]['name']} - ${widget.orders[index]['price']}',
                          style: const TextStyle(fontSize: 18),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Total Amount field as a disabled TextFormField inside a SizedBox.
                const Text(
                  "Total Amount:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    enabled: false,
                    initialValue: "₱${totalAmount.toStringAsFixed(2)}",
                    decoration: const InputDecoration(
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Cash Sent field as a disabled TextFormField inside a SizedBox.
                const Text(
                  "Cash Sent:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    enabled: false,
                    // If payment is successful, show the actual amountPaid; otherwise, show totalAmount.
                    initialValue: paymentSuccess
                        ? "₱${amountPaid!.toStringAsFixed(2)}"
                        : "₱${totalAmount.toStringAsFixed(2)}",
                    decoration: const InputDecoration(
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Now display the instruction to scan QR code after the Cash Sent field.
                const Text(
                  "Please Scan GCash QR Code to complete payment.",
                  style: TextStyle(fontSize: 25, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // QR Code Image
                Center(
                  child: Image.asset(
                    'assets/images/qrcode.png',
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                // Optionally display transaction details if available.
                if (paymentSuccess && transactionId != null)
                  Center(
                    child: Text(
                      "Transaction ID: $transactionId",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                // Shorter Payment Completed button using a SizedBox.
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // When payment is completed, navigate back to PaymentMethodPage.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentMethodPage(
                              orders: widget.orders,
                              rfidData: widget.rfidData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A5E),
                        padding: EdgeInsets.zero, // Remove internal padding.
                      ),
                      child: const Text(
                        "PAYMENT COMPLETED",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
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
