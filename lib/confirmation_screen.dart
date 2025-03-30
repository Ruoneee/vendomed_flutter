import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart'; // Ensure confetti is in pubspec.yaml
import 'splash_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final List<Map<String, String>> orders;
  final double totalPrice;

  const ConfirmationScreen({
    Key? key,
    required this.orders,
    required this.totalPrice,
  }) : super(key: key);

  @override
  ConfirmationScreenState createState() => ConfirmationScreenState();
}

class ConfirmationScreenState extends State<ConfirmationScreen> {
  Timer? _autoNavigateTimer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Start confetti animation for 3 seconds.
    _confettiController = ConfettiController(duration: const Duration(seconds: 8));
    _confettiController.play();

    // Auto-return to home after 5 seconds.
    _startAutoNavigateTimer();
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a Stack to overlay confetti over the main content.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content: success animation, messages, and detailed e‑receipt.
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated success checkmark (Lottie animation).
                  Lottie.asset(
                    'assets/animations/success.json',
                    width: 200,
                    height: 200,
                    repeat: false,
                  ),
                  const SizedBox(height: 30),
                  // Order confirmation text (larger font).
                  const Text(
                    "Order confirmed!",
                    style: TextStyle(
                      fontSize: 40, // Larger
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Instruction for retrieval (larger font).
                  const Text(
                    "Please retrieve your items from the dispenser.",
                    style: TextStyle(
                      fontSize: 28, // Larger
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Detailed e-receipt based on the transaction.
                  _buildReceipt(),
                  const SizedBox(height: 24),
                  // Auto-return message (larger).
                  const Text(
                    "Returning to Home soon...",
                    style: TextStyle(fontSize: 20, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          // Confetti overlay.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the detailed e-receipt using dynamic transaction data.
  Widget _buildReceipt() {
    final now = DateTime.now();
    final formattedDateTime =
        "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)} "
        "${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28), // More padding for a larger feel
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt header.
          Center(
            child: Text(
              "E‑Receipt",
              style: TextStyle(
                fontSize: 32, // Larger
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _receiptLine("Date & Time:", formattedDateTime),
          _receiptLine("Type of Transaction:", "Purchased Order"),
          _receiptLine("Biller:", "Cash/Coins"),
          const Divider(thickness: 1.5),
          // Items purchased (ordered medicine).
          const Text(
            "Items Purchased:",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (widget.orders.isEmpty)
            const Text(
              "No items purchased.",
              style: TextStyle(fontSize: 20),
            )
          else
            ...widget.orders.map((order) {
              final name = order['name'] ?? 'Unknown';
              final qty = order['quantity'] ?? '1';
              final price = order['price'] ?? '0.00';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "$name (Qty: $qty) - ₱$price",
                  style: const TextStyle(fontSize: 20),
                ),
              );
            }).toList(),
          const Divider(thickness: 1.5),
          _receiptLine("Total Paid:", "₱${widget.totalPrice.toStringAsFixed(2)}"),
          const SizedBox(height: 20),
          // Footer note.
          const Center(
            child: Text(
              "** This receipt is for reference only. **",
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a line with a label and value, with bigger font sizes.
  Widget _receiptLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to format numbers as two-digit strings.
  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
