import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Simple data model for the chart.
class ChartData {
  final num x;
  final num y;
  ChartData({required this.x, required this.y});
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Simulated transaction data.
  List<ChartData> chartData = [
    ChartData(x: 0, y: 5),
    ChartData(x: 1, y: 10),
    ChartData(x: 2, y: 15),
    ChartData(x: 3, y: 7),
    ChartData(x: 4, y: 12),
    ChartData(x: 5, y: 9),
    ChartData(x: 6, y: 14),
  ];

  // Reset the chart data to default values.
  void _resetDashboard() {
    setState(() {
      chartData = [
        ChartData(x: 0, y: 5),
        ChartData(x: 1, y: 10),
        ChartData(x: 2, y: 15),
        ChartData(x: 3, y: 7),
        ChartData(x: 4, y: 12),
        ChartData(x: 5, y: 9),
        ChartData(x: 6, y: 14),
      ];
    });
  }

  // Navigate to the MedicineMenu screen using a named route.
  void _navigateToMedicineMenu() {
    Navigator.pushReplacementNamed(context, '/medicine_menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chart area.
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SfCartesianChart(
                    primaryXAxis: NumericAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries<ChartData, num>>[
                      LineSeries<ChartData, num>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        markerSettings: const MarkerSettings(isVisible: true),
                      )
                    ],
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
                  child: const Text("Medicine Menu"),
                ),
                ElevatedButton(
                  onPressed: _resetDashboard,
                  child: const Text("Reset"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
