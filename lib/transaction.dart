import 'package:flutter/material.dart';
// Import your DashboardScreen so we can navigate back to it when tapping the Sales tab.
import 'dashboard.dart';

class TransactionScreen extends StatelessWidget {
  // Remove const from constructor since DashboardScreen() is not const.
  TransactionScreen({Key? key}) : super(key: key);

  // Handle bottom navigation taps.
  void _onTabSelected(BuildContext context, int index) {
    if (index == 0) {
      // Navigate to Dashboard (Sales tab)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    }
    // For index 1, we're already on TransactionScreen (Payments).
    // For indices 2 and 3, add navigation logic as needed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow.
        title: Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        backgroundColor: Color(0xFF0D2A5E),
      ),
      body: Center(
        child: Text(
          'Transaction Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
      // Bottom navigation bar.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Payments tab is selected.
        onTap: (index) => _onTabSelected(context, index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 28,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
    );
  }
}
