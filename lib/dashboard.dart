import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Simple data model for chart data.
class ChartData {
  final num x;
  final num y;
  ChartData({required this.x, required this.y});
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Simulated data for different filters.
  final List<ChartData> daysData = [
    ChartData(x: 0, y: 5),
    ChartData(x: 1, y: 10),
    ChartData(x: 2, y: 15),
    ChartData(x: 3, y: 7),
    ChartData(x: 4, y: 12),
    ChartData(x: 5, y: 9),
    ChartData(x: 6, y: 14),
  ];

  final List<ChartData> weeksData = [
    ChartData(x: 0, y: 40),
    ChartData(x: 1, y: 55),
    ChartData(x: 2, y: 60),
    ChartData(x: 3, y: 50),
  ];

  final List<ChartData> monthsData = [
    ChartData(x: 0, y: 200),
    ChartData(x: 1, y: 240),
    ChartData(x: 2, y: 220),
    ChartData(x: 3, y: 260),
    ChartData(x: 4, y: 280),
    ChartData(x: 5, y: 300),
  ];

  // Reset function (if you need to update data dynamically).
  void _resetDashboard() {
    setState(() {
      // For this example, the default data remains constant.
    });
  }

  // Navigate to the MedicineMenu screen using a named route.
  void _navigateToMedicineMenu() {
    Navigator.pushReplacementNamed(context, '/medicine_menu');
  }

  // Build the chart view for a given data set.
  Widget _buildChartView(List<ChartData> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Line Chart Card with a fixed height and width.
          Center(
            child: SizedBox(
              height: 400,
              width: 650, // Adjust width as needed.
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Transaction Line Chart'),
                    primaryXAxis: NumericAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries<ChartData, num>>[
                      LineSeries<ChartData, num>(
                        color: const Color(0xFFA52A2A), // #A52A2A
                        dataSource: data,
                        xValueMapper: (ChartData d, _) => d.x,
                        yValueMapper: (ChartData d, _) => d.y,
                        markerSettings: const MarkerSettings(isVisible: true),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bar Chart Card with a fixed height and width.
          Center(
            child: SizedBox(
              height: 400,
              width: 650, // Adjust width as needed.
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Transaction Bar Chart'),
                    primaryXAxis: NumericAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries<ChartData, num>>[
                      ColumnSeries<ChartData, num>(
                        color: const Color(0xFFA52A2A), // #A52A2A
                        dataSource: data,
                        xValueMapper: (ChartData d, _) => d.x,
                        yValueMapper: (ChartData d, _) => d.y,
                        dataLabelSettings:
                        const DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Buttons row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _navigateToMedicineMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A5E),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "Medicine Menu",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _resetDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "Reset",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Days, Weeks, Months.
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D2A5E),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Days"),
              Tab(text: "Weeks"),
              Tab(text: "Months"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChartView(daysData),
            _buildChartView(weeksData),
            _buildChartView(monthsData),
          ],
        ),
      ),
    );
  }
}
