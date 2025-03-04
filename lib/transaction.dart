import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dashboard.dart';

// A simple model for payment methods in the pie chart
class PaymentMethodData {
  final String method;
  final double percentage;
  PaymentMethodData(this.method, this.percentage);
}

// A simple model for individual transactions
class TransactionItem {
  final String name;
  final String date;
  final double amount;

  TransactionItem({required this.name, required this.date, required this.amount});
}

class TransactionScreen extends StatelessWidget {
  TransactionScreen({Key? key}) : super(key: key);

  // Some sample data for the pie chart
  final List<PaymentMethodData> paymentMethods = [
    PaymentMethodData("Coins/Cash", 38.5),
    PaymentMethodData("G-Cash", 21.5),
  ];

  // Some sample transactions
  final List<TransactionItem> recentTransactions = [
    TransactionItem(name: "Unknown", date: "March 03, 2025", amount: 16.00),
    TransactionItem(name: "Unknown", date: "March 01, 2025", amount: 7.00),
    TransactionItem(name: "User0110", date: "February 28, 2025", amount: 23.65),
  ];

  // Handle bottom navigation taps
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
      // AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        backgroundColor: const Color(0xFF0D2A5E),
      ),

      // Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAYMENT ANALYTICS (Pie Chart)
            const Text(
              "Payment Analytics",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pie Chart
            SizedBox(
              height: 350, // Increase chart height
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                  textStyle: const TextStyle(fontSize: 18), // Larger legend text
                ),
                series: <CircularSeries>[
                  PieSeries<PaymentMethodData, String>(
                    dataSource: paymentMethods,
                    xValueMapper: (PaymentMethodData data, _) => data.method,
                    yValueMapper: (PaymentMethodData data, _) => data.percentage,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(fontSize: 18), // Larger data labels
                    ),
                  ),
                ],
              ),
            ),

            // ROW: Total Transactions & Most Used Method
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Example "Total Transactions"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Total Transactions",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "500",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Example "Most Used Method"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Most Used Method",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        // Instead of monetization_on icon, use a peso sign
                        Text(
                          "₱",
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Coins",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // TRANSACTIONS LIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transactions",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Handle "See All" action here
                  },
                  child: const Text(
                    "See All",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Sample transaction cards
            Column(
              children: recentTransactions.map((tx) {
                return _buildTransactionCard(tx);
              }).toList(),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Payments tab is selected
        onTap: (index) => _onTabSelected(context, index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 36, // Larger icon size
        selectedFontSize: 18, // Larger selected font size
        unselectedFontSize: 16, // Larger unselected font size
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
    );
  }

  // A helper widget to build each transaction card
  Widget _buildTransactionCard(TransactionItem tx) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28, // Larger avatar
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.white70, size: 32),
        ),
        title: Text(
          tx.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          tx.date,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        trailing: Text(
          "₱${tx.amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
