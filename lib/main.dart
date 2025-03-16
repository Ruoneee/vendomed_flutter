import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import the database helper
import 'splash_screen.dart';
import 'user_selection_screen.dart';
import 'rfid_screen.dart';
import 'medicine_menu.dart';
import 'usb_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database (vendomed.db)
  await DatabaseHelper().db;
  USBHelper().initUSB(); // ✅ Initialize USB connection at app startup
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
        '/': (context) => const SplashScreen(),
        '/user_selection': (context) => const UserSelectionScreen(),
        '/rfid_screen': (context) => const RfidScreen(),
        '/medicine_menu': (context) => const MedicineMenu(rfidData: ''),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
