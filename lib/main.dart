// main.dart
import 'package:flutter/material.dart';
import 'rfid_screen.dart';
import 'splash_screen.dart';
import 'medicine_menu.dart';
import 'payment.dart';
// import 'confirmation_screen.dart';

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
      initialRoute: '/medicine_menu',
      routes: {
        '/': (context) => RfidScreen(),
        '/splash_screen': (context) => SplashScreen(),
        '/medicine_menu': (context) => MedicineMenu(),
        '/payment': (context) => PaymentPage(orders: const []),
        '/rfid_screen': (context) => RfidScreen(),
      },
    );
  }
}
