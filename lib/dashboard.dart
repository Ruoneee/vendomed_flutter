import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'splash_screen.dart'; // Import SplashScreen to navigate to Home

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Data model for numeric charts.
class ChartData {
  final num x;
  final num y;
  ChartData({required this.x, required this.y});
}

// Data model for categorical charts.
class CategoryData {
  final String category;
  final num value;
  CategoryData({required this.category, required this.value});
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- Sample Data for Different Time Filters ---

  // 1. Sales of Each Medicine (Line & Bar Chart)
  final List<ChartData> salesDataDays = [
    ChartData(x: 0, y: 10),
    ChartData(x: 1, y: 20),
    ChartData(x: 2, y: 15),
    ChartData(x: 3, y: 25),
    ChartData(x: 4, y: 18),
    ChartData(x: 5, y: 30),
    ChartData(x: 6, y: 22),
  ];
  final List<ChartData> salesDataWeeks = [
    ChartData(x: 0, y: 70),
    ChartData(x: 1, y: 85),
    ChartData(x: 2, y: 90),
    ChartData(x: 3, y: 80),
  ];
  final List<ChartData> salesDataMonths = [
    ChartData(x: 0, y: 300),
    ChartData(x: 1, y: 320),
    ChartData(x: 2, y: 310),
    ChartData(x: 3, y: 330),
    ChartData(x: 4, y: 350),
    ChartData(x: 5, y: 370),
  ];

  // 2. Frequency of Each Medicine (Area Chart)
  final List<ChartData> frequencyDataDays = [
    ChartData(x: 0, y: 5),
    ChartData(x: 1, y: 8),
    ChartData(x: 2, y: 7),
    ChartData(x: 3, y: 10),
    ChartData(x: 4, y: 6),
    ChartData(x: 5, y: 9),
    ChartData(x: 6, y: 4),
  ];
  final List<ChartData> frequencyDataWeeks = [
    ChartData(x: 0, y: 30),
    ChartData(x: 1, y: 40),
    ChartData(x: 2, y: 35),
    ChartData(x: 3, y: 45),
  ];
  final List<ChartData> frequencyDataMonths = [
    ChartData(x: 0, y: 120),
    ChartData(x: 1, y: 130),
    ChartData(x: 2, y: 125),
    ChartData(x: 3, y: 140),
    ChartData(x: 4, y: 150),
    ChartData(x: 5, y: 160),
  ];

  // 3. Total Sales of All Medicines (Bar Chart)
  final List<ChartData> totalSalesDataDays = [
    ChartData(x: 0, y: 50),
    ChartData(x: 1, y: 55),
    ChartData(x: 2, y: 60),
    ChartData(x: 3, y: 65),
    ChartData(x: 4, y: 70),
    ChartData(x: 5, y: 75),
    ChartData(x: 6, y: 80),
  ];
  final List<ChartData> totalSalesDataWeeks = [
    ChartData(x: 0, y: 300),
    ChartData(x: 1, y: 320),
    ChartData(x: 2, y: 310),
    ChartData(x: 3, y: 330),
  ];
  final List<ChartData> totalSalesDataMonths = [
    ChartData(x: 0, y: 1300),
    ChartData(x: 1, y: 1350),
    ChartData(x: 2, y: 1400),
    ChartData(x: 3, y: 1450),
    ChartData(x: 4, y: 1500),
    ChartData(x: 5, y: 1550),
  ];

  // 4. Type of Payments Used by Customers (Pie Chart)
  final List<CategoryData> paymentData = [
    CategoryData(category: 'Gcash', value: 60),
    CategoryData(category: 'Cash/Coins', value: 40),
  ];

  // 5. Type of Users (RFID User & Guests) (Bar Chart)
  final List<CategoryData> userTypeData = [
    CategoryData(category: 'RFID User', value: 60),
    CategoryData(category: 'Guest', value: 40),
  ];

  // --- Helper function to show chart dialog ---
  void _showChartDialog(String title, Widget chartContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
              // Chart content.
              Container(
                height: 400,
                width: 600,
                padding: const EdgeInsets.all(8.0),
                child: chartContent,
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigate to Home (SplashScreen).
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  int _currentTabIndex = 0;

  List<ChartData> get currentSalesData {
    switch (_currentTabIndex) {
      case 0:
        return salesDataDays;
      case 1:
        return salesDataWeeks;
      case 2:
        return salesDataMonths;
      default:
        return salesDataDays;
    }
  }

  List<ChartData> get currentFrequencyData {
    switch (_currentTabIndex) {
      case 0:
        return frequencyDataDays;
      case 1:
        return frequencyDataWeeks;
      case 2:
        return frequencyDataMonths;
      default:
        return frequencyDataDays;
    }
  }

  List<ChartData> get currentTotalSalesData {
    switch (_currentTabIndex) {
      case 0:
        return totalSalesDataDays;
      case 1:
        return totalSalesDataWeeks;
      case 2:
        return totalSalesDataMonths;
      default:
        return totalSalesDataDays;
    }
  }

  // --- Chart Builders with GestureDetector wrapping ---

  Widget _buildSalesChart() {
    return Column(
      children: [
        // Line Chart for Sales.
        GestureDetector(
          onTap: () {
            _showChartDialog(
              'Sales of Each Medicine - Line Chart',
              SfCartesianChart(
                title: ChartTitle(text: 'Sales of Each Medicine - Line Chart'),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                series: <CartesianSeries>[
                  LineSeries<ChartData, num>(
                    dataSource: currentSalesData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: const Color(0xFF3674B5),
                  )
                ],
              ),
            );
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfCartesianChart(
                title: ChartTitle(text: 'Sales of Each Medicine - Line Chart'),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                series: <CartesianSeries>[
                  LineSeries<ChartData, num>(
                    dataSource: currentSalesData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: const Color(0xFF3674B5),
                  )
                ],
              ),
            ),
          ),
        ),
        // Bar Chart for Sales.
        GestureDetector(
          onTap: () {
            _showChartDialog(
              'Sales of Each Medicine - Bar Chart',
              SfCartesianChart(
                title: ChartTitle(text: 'Sales of Each Medicine - Bar Chart'),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<ChartData, num>(
                    dataSource: currentSalesData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: const Color(0xFF3674B5),
                  )
                ],
              ),
            );
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfCartesianChart(
                title: ChartTitle(text: 'Sales of Each Medicine - Bar Chart'),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<ChartData, num>(
                    dataSource: currentSalesData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: const Color(0xFF3674B5),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyChart() {
    return GestureDetector(
      onTap: () {
        _showChartDialog(
          'Frequency of Each Medicine',
          SfCartesianChart(
            primaryXAxis: NumericAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              AreaSeries<ChartData, num>(
                dataSource: currentFrequencyData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFF578FCA),
              )
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SfCartesianChart(
            title: ChartTitle(text: 'Frequency of Each Medicine'),
            primaryXAxis: NumericAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              AreaSeries<ChartData, num>(
                dataSource: currentFrequencyData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFF578FCA),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSalesChart() {
    return GestureDetector(
      onTap: () {
        _showChartDialog(
          'Total Sales of All Medicines',
          SfCartesianChart(
            primaryXAxis: NumericAxis(),
            primaryYAxis: NumericAxis(),
            title: ChartTitle(text: 'Total Sales of All Medicines'),
            series: <CartesianSeries>[
              ColumnSeries<ChartData, num>(
                dataSource: currentTotalSalesData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFFA1E3F9),
              )
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SfCartesianChart(
            title: ChartTitle(text: 'Total Sales of All Medicines'),
            primaryXAxis: NumericAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              ColumnSeries<ChartData, num>(
                dataSource: currentTotalSalesData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFFA1E3F9),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChart() {
    return GestureDetector(
      onTap: () {
        _showChartDialog(
          'Type of Payments Used',
          SfCircularChart(
            title: ChartTitle(text: 'Type of Payments Used'),
            legend: Legend(isVisible: true),
            series: <CircularSeries>[
              PieSeries<CategoryData, String>(
                dataSource: paymentData,
                xValueMapper: (CategoryData data, _) => data.category,
                yValueMapper: (CategoryData data, _) => data.value,
                pointColorMapper: (CategoryData data, _) {
                  if (data.category == 'Gcash') {
                    return const Color(0xFFD1F8EF);
                  } else {
                    return const Color(0xFFA6F1E0);
                  }
                },
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              )
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SfCircularChart(
            title: ChartTitle(text: 'Type of Payments Used'),
            legend: Legend(isVisible: true),
            series: <CircularSeries>[
              PieSeries<CategoryData, String>(
                dataSource: paymentData,
                xValueMapper: (CategoryData data, _) => data.category,
                yValueMapper: (CategoryData data, _) => data.value,
                pointColorMapper: (CategoryData data, _) {
                  if (data.category == 'Gcash') {
                    return const Color(0xFFD1F8EF);
                  } else {
                    return const Color(0xFFA6F1E0);
                  }
                },
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeChart() {
    return GestureDetector(
      onTap: () {
        _showChartDialog(
          'Type of Users',
          SfCartesianChart(
            title: ChartTitle(text: 'Type of Users'),
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              ColumnSeries<CategoryData, String>(
                dataSource: userTypeData,
                xValueMapper: (CategoryData data, _) => data.category,
                yValueMapper: (CategoryData data, _) => data.value,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFF73C7C7),
              )
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SfCartesianChart(
            title: ChartTitle(text: 'Type of Users'),
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries>[
              ColumnSeries<CategoryData, String>(
                dataSource: userTypeData,
                xValueMapper: (CategoryData data, _) => data.category,
                yValueMapper: (CategoryData data, _) => data.value,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                color: const Color(0xFF73C7C7),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSalesChart(),
          _buildFrequencyChart(),
          _buildTotalSalesChart(),
          _buildPaymentChart(),
          _buildUserTypeChart(),
          // Home Button to navigate to SplashScreen.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2A5E),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                "Home",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Days, Weeks, Months.
      initialIndex: _currentTabIndex,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("DASHBOARD ADMIN", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0D2A5E),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Days"),
              Tab(text: "Weeks"),
              Tab(text: "Months"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardContent(),
            _buildDashboardContent(),
            _buildDashboardContent(),
          ],
        ),
      ),
    );
  }
}
