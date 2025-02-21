import 'dart:async'; // Import this for Timer
import 'package:flutter/material.dart';
import 'package:vendomed_flutter/rfid_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _dispensingMessage = "Order Confirmed!";
  Timer? _autoNavigateTimer; // Timer for auto navigation

  @override
  void initState() {
    super.initState();
    _startAutoNavigateTimer();
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel(); // Cancel existing timer, if any
    _autoNavigateTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pop(context); // Pop ConfirmationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RfidScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel(); // Cancel the timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        backgroundColor: const Color(0xfffffffff),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dispensingMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _autoNavigateTimer?.cancel(); // Cancel timer if manually pressed
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RfidScreen()),
                );
              },
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
