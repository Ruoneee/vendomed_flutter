import 'package:flutter/material.dart';
import 'medicine_menu.dart';  // Import for Guest flow
import 'rfid_screen.dart';    // Import for RFID scanning flow

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for responsive sizing.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = screenWidth * 0.8; // 80% of screen width
    const double buttonHeight = 90.0; // Increased height for enhanced readability

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D2A5E), // Start color
              Color(0xFF1E5D6F), // End color
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    "Are you an RFID user?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    "Scan your RFID card to access your account and earn points.\nOr continue as guest to skip login.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // RFID Button
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to the RFID scanning screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RfidScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(
                        Icons.credit_card, // or a custom RFID icon
                        color: Color(0xFF0D2A5E),
                        size: 36, // Increased icon size
                      ),
                      label: const Text(
                        "I Have RFID",
                        style: TextStyle(
                          fontSize: 26, // Increased font size for button text
                          color: Color(0xFF0D2A5E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Guest Button
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to MedicineMenu as Guest.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const MedicineMenu(rfidData: "Guest"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 36, // Increased icon size
                      ),
                      label: const Text(
                        "Continue as Guest",
                        style: TextStyle(
                          fontSize: 26, // Increased font size
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
