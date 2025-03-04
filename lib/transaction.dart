// transaction.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dashboard.dart';
import 'database_helper.dart';

// Model for payment methods in the pie chart.
class PaymentMethodData {
  final String method;
  final double percentage;
  PaymentMethodData(this.method, this.percentage);
}

// Model for individual transactions.
class TransactionItem {
  final String medicine;
  final String date;
  final double totalAmount;
  final String paymentMethod; // Added paymentMethod field

  TransactionItem({
    required this.medicine,
    required this.date,
    required this.totalAmount,
    required this.paymentMethod,
  });
}

class TransactionScreen extends StatelessWidget {
  TransactionScreen({Key? key}) : super(key: key);

  // Convert database rows into a list of TransactionItem.
  Future<List<TransactionItem>> _fetchTransactions() async {
    final dataList = await DatabaseHelper().getTransactions();
    return dataList.map((row) {
      return TransactionItem(
        medicine: row['medicine'],
        date: row['date'],
        totalAmount: row['total_amount'] is int
            ? (row['total_amount'] as int).toDouble()
            : row['total_amount'],
        paymentMethod: row['payment_method'], // Map payment_method from DB
      );
    }).toList();
  }

  // Navigation: Go back to Dashboard when tapping Sales tab.
  void _onTabSelected(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    }
    // Add further navigation logic for indices 2 and 3 as needed.
  }

  // Build a card widget for each transaction.
  Widget _buildTransactionCard(TransactionItem tx) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.medication, color: Colors.white70, size: 32),
        ),
        title: Text(
          tx.medicine,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          tx.date,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        trailing: Text(
          "₱${tx.totalAmount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar.
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back arrow.
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      // Body: Use FutureBuilder to load transactions from the database.
      body: FutureBuilder<List<TransactionItem>>(
        future: _fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions available'));
          }

          final transactions = snapshot.data!;
          // Compute dynamic values based on database transactions:
          final totalCount = transactions.length;
          int cashCoinsCount = transactions.where((tx) => tx.paymentMethod == 'Cash/Coins').length;
          int gCashCount = transactions.where((tx) => tx.paymentMethod == 'GCash').length;
          double percentCashCoins = totalCount > 0 ? (cashCoinsCount / totalCount * 100) : 0;
          double percentGCash = totalCount > 0 ? (gCashCount / totalCount * 100) : 0;
          // Determine the most used payment method.
          String mostUsedMethod = cashCoinsCount >= gCashCount ? "Cash/Coins" : "GCash";

          // Build the payment methods analytics list dynamically.
          final List<PaymentMethodData> paymentMethods = [
            PaymentMethodData("Cash/Coins", percentCashCoins),
            PaymentMethodData("GCash", percentGCash),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Analytics",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Pie Chart showing payment method percentages.
                SizedBox(
                  height: 350,
                  child: SfCircularChart(
                    legend: Legend(
                      isVisible: true,
                      overflowMode: LegendItemOverflowMode.wrap,
                      position: LegendPosition.bottom,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    series: <CircularSeries>[
                      PieSeries<PaymentMethodData, String>(
                        dataSource: paymentMethods,
                        xValueMapper: (PaymentMethodData data, _) => data.method,
                        yValueMapper: (PaymentMethodData data, _) => data.percentage,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Row showing Total Transactions and Most Used Method.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dynamic "Total Transactions" count.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Transactions",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$totalCount",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Display the most used payment method.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Most Used Method",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              "₱",
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mostUsedMethod,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Header for the Transactions list.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Transactions",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle "See All" action here.
                      },
                      child: const Text(
                        "See All",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                // Build the list of transaction cards.
                Column(
                  children: transactions.map((tx) => _buildTransactionCard(tx)).toList(),
                ),
              ],
            ),
          );
        },
      ),
      // Bottom navigation bar.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Payments tab is selected.
        onTap: (index) => _onTabSelected(context, index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 36,
        selectedFontSize: 18,
        unselectedFontSize: 16,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
    );
  }
}
