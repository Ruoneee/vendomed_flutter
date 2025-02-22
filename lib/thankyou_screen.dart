// thankyou_screen.dart

import 'package:flutter/material.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match the same AppBar design:
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2A5E),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Order Complete!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),

      // Match the same background color:
      backgroundColor: const Color(0xFFFFFFFF),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Order Complete!\n\nThank you for choosing VendoMed!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
