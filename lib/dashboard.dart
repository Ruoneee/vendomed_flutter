import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
// Import the transaction screen file
import 'transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  int _selectedTimeFilter = 2; // Default to "Month"

  List<String> timeFilters = ["Day", "Week", "Month", "Year"];

  // Sample data for sales and medicine frequency charts
  final List<ChartData> salesData = [
    ChartData(label: "Week 1", value: 120),
    ChartData(label: "Week 2", value: 200),
    ChartData(label: "Week 3", value: 48),
    ChartData(label: "Week 4", value: 209),
  ];

  final List<ChartData> frequencyData = [
    ChartData(label: "Loperamide", value: 20),
    ChartData(label: "Paracetamol", value: 35),
    ChartData(label: "Cefixime", value: 30),
    ChartData(label: "Ibuprofen", value: 50),
    ChartData(label: "Amoxicil", value: 70),
    ChartData(label: "Buscopan", value: 80),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // If the user taps the Payments item (index = 1),
    // navigate to the transaction screen.
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    }
  }

  void _onTimeFilterSelected(int index) {
    setState(() {
      _selectedTimeFilter = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBalanceCard(),
              _buildSalesStatistics(),
              _buildSalesChart(),
              _buildFrequencyChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Welcome, Admin!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.blue),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Active Balance", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "₱6,890.00",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                ElevatedButton(
                  onPressed: () {
                    // If you also want this button to navigate to transaction.dart:
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const TransactionScreen()),
                    // );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Withdraw", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text("Sales Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: timeFilters
              .asMap()
              .entries
              .map(
                (entry) => _buildTimeFilterButton(entry.key, entry.value),
          )
              .toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimeFilterButton(int index, String label) {
    return GestureDetector(
      onTap: () => _onTimeFilterSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedTimeFilter == index ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedTimeFilter == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Sales for the Month of February",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    dataSource: salesData,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    color: Colors.blueAccent,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Frequency of Medicine Sales",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                series: <CartesianSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    dataSource: frequencyData,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model for chart data
class ChartData {
  final String label;
  final num value;

  ChartData({required this.label, required this.value});
}
