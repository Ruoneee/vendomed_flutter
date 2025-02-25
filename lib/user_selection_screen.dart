import 'package:flutter/material.dart';
import 'rfid_screen.dart';
import 'medicine_menu.dart';
import 'user_med_menu.dart'; // ✅ Corrected import

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 350.0;
    const double buttonHeight = 65.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Are you an RFID user?",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5D6F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RfidScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A5E),
                  fixedSize: const Size(buttonWidth, buttonHeight),
                ),
                child: const Text(
                  "Yes, I have RFID",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserMedMenu(rfidData: "Guest"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  fixedSize: const Size(buttonWidth, buttonHeight),
                ),
                child: const Text(
                  "No, Enter as Guest",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
