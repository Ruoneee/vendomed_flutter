// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import your splash screen
import 'medicine_menu.dart'; // Import your medicine menu
import 'payment.dart'; // Import your payment screen

void main() {
  runApp(MyApp());
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
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => SplashScreen(), // Splash screen as the home widget
        '/medicine_menu': (context) => MedicineMenu(), // Route for MedicineMenu
        '/payment': (context) => Payment(), // Route for Payment screen
      },
    );
  }
}
