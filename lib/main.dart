// main.dart
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'user_selection_screen.dart';
import 'rfid_screen.dart';
import 'medicine_menu.dart';
import 'payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendoMed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        // Set the initial route to the splash screen.
        '/': (context) => const SplashScreen(),
        '/user_selection': (context) => const UserSelectionScreen(),
        '/rfid_screen': (context) => const RfidScreen(),
        '/medicine_menu': (context) => MedicineMenu(rfidData: ''),
        // Add any other routes you need here.
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
