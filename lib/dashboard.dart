import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'transaction.dart';
import 'splash_screen.dart';  // Import for splash_screen.dart

// Model for chart data
class ChartData {
  final String label;
  final num value;
  ChartData({required this.label, required this.value});
}

class DashboardScreen extends StatefulWidget {
  // Removed 'const' from the constructor.
  DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  int _selectedTimeFilter = 2; // Default to "Month"
  bool _isDarkMode = false; // Dark mode state

  // Time filter options
  final List<String> timeFilters = ["Day", "Week", "Month", "Year"];

  // Sales data sets
  final List<ChartData> _daySalesData = [
    ChartData(label: "Day 1", value: 45),
    ChartData(label: "Day 2", value: 32),
    ChartData(label: "Day 3", value: 60),
  ];
  final List<ChartData> _weekSalesData = [
    ChartData(label: "Week 1", value: 120),
    ChartData(label: "Week 2", value: 200),
    ChartData(label: "Week 3", value: 48),
    ChartData(label: "Week 4", value: 209),
  ];
  final List<ChartData> _monthSalesData = [
    ChartData(label: "Week 1", value: 120),
    ChartData(label: "Week 2", value: 200),
    ChartData(label: "Week 3", value: 48),
    ChartData(label: "Week 4", value: 209),
  ];
  final List<ChartData> _yearSalesData = [
    ChartData(label: "Q1", value: 400),
    ChartData(label: "Q2", value: 350),
    ChartData(label: "Q3", value: 600),
    ChartData(label: "Q4", value: 450),
  ];

  // Frequency data sets
  final List<ChartData> _dayFrequencyData = [
    ChartData(label: "Paracetamol", value: 10),
    ChartData(label: "Ibuprofen", value: 15),
    ChartData(label: "Cefixime", value: 8),
  ];
  final List<ChartData> _weekFrequencyData = [
    ChartData(label: "Loperamide", value: 20),
    ChartData(label: "Paracetamol", value: 35),
    ChartData(label: "Cefixime", value: 30),
    ChartData(label: "Ibuprofen", value: 50),
    ChartData(label: "Amoxicil", value: 70),
    ChartData(label: "Buscopan", value: 80),
  ];
  final List<ChartData> _monthFrequencyData = [
    ChartData(label: "Loperamide", value: 20),
    ChartData(label: "Paracetamol", value: 35),
    ChartData(label: "Cefixime", value: 30),
    ChartData(label: "Ibuprofen", value: 50),
    ChartData(label: "Amoxicil", value: 70),
    ChartData(label: "Buscopan", value: 80),
  ];
  final List<ChartData> _yearFrequencyData = [
    ChartData(label: "Paracetamol", value: 300),
    ChartData(label: "Ibuprofen", value: 220),
    ChartData(label: "Cefixime", value: 180),
  ];

  // These lists hold the current data displayed in the charts.
  List<ChartData> _salesData = [];
  List<ChartData> _frequencyData = [];

  @override
  void initState() {
    super.initState();
    // Default to "Month" data (since _selectedTimeFilter = 2)
    _salesData = _monthSalesData;
    _frequencyData = _monthFrequencyData;
  }

  /// Helper function to show a pop-up dialog with an enlarged chart.
  void _showBigChart(String title, Widget chartWidget) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: _isDarkMode ? Colors.black : Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close icon.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: _isDarkMode ? Colors.white : Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                chartWidget,
              ],
            ),
          ),
        );
      },
    );
  }

  // Settings dialog using AlertDialog with a StatefulBuilder for immediate update.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Settings"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dark Mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Dark Mode"),
                      Switch(
                        value: _isDarkMode,
                        onChanged: (bool value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                          // Update the dialog's state to reflect the new theme immediately.
                          setStateDialog(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Log Out button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                    ),
                    onPressed: _logOut,
                    child: const Text(
                      "Log Out",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Log-out function that navigates to SplashScreen.
  void _logOut() {
    Navigator.pop(context); // Close settings dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    if (index == 1) {
      // Navigate to TransactionScreen when the Payments tab is selected.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransactionScreen()),
      );
    }
  }

  void _onTimeFilterSelected(int index) {
    setState(() {
      _selectedTimeFilter = index;
      if (index == 0) {
        _salesData = _daySalesData;
        _frequencyData = _dayFrequencyData;
      } else if (index == 1) {
        _salesData = _weekSalesData;
        _frequencyData = _weekFrequencyData;
      } else if (index == 2) {
        _salesData = _monthSalesData;
        _frequencyData = _monthFrequencyData;
      } else {
        _salesData = _yearSalesData;
        _frequencyData = _yearFrequencyData;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Welcome, Admin!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2A5E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 28,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildSalesStatistics(),
                const SizedBox(height: 20),
                _buildSalesChart(),
                const SizedBox(height: 20),
                _buildFrequencyChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Active Balance",
              style: TextStyle(
                fontSize: 18,
                color: _isDarkMode ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₱6,890.00",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Withdraw", style: TextStyle(color: Colors.white, fontSize: 16)),
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
        Text(
          "Sales Statistics",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: timeFilters.asMap().entries.map((entry) {
            return _buildTimeFilterButton(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeFilterButton(int index, String label) {
    final bool isSelected = _selectedTimeFilter == index;
    return GestureDetector(
      onTap: () => _onTimeFilterSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D2A5E) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // SALES CHART with dynamic color for dark mode vs. light mode.
  Widget _buildSalesChart() {
    final Color chartBarColor = _isDarkMode ? Colors.cyanAccent : const Color(0xFF0D2A5E);

    return GestureDetector(
      onTap: () {
        _showBigChart(
          _selectedTimeFilter == 0
              ? "Sales for Today"
              : _selectedTimeFilter == 1
              ? "Sales for This Week"
              : _selectedTimeFilter == 2
              ? "Sales for This Month"
              : "Sales for This Year",
          SizedBox(
            height: 500,
            child: SfCartesianChart(
              backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              series: <CartesianSeries<ChartData, String>>[
                ColumnSeries<ChartData, String>(
                  dataSource: _salesData,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: chartBarColor,
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                _selectedTimeFilter == 0
                    ? "Sales for Today"
                    : _selectedTimeFilter == 1
                    ? "Sales for This Week"
                    : _selectedTimeFilter == 2
                    ? "Sales for This Month"
                    : "Sales for This Year",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  series: <CartesianSeries<ChartData, String>>[
                    ColumnSeries<ChartData, String>(
                      dataSource: _salesData,
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      color: chartBarColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FREQUENCY CHART with dynamic color for dark mode vs. light mode.
  Widget _buildFrequencyChart() {
    final Color chartLineColor = _isDarkMode ? Colors.cyanAccent : const Color(0xFF0D2A5E);

    return GestureDetector(
      onTap: () {
        _showBigChart(
          _selectedTimeFilter == 0
              ? "Frequency of Medicine Sales (Day)"
              : _selectedTimeFilter == 1
              ? "Frequency of Medicine Sales (Week)"
              : _selectedTimeFilter == 2
              ? "Frequency of Medicine Sales (Month)"
              : "Frequency of Medicine Sales (Year)",
          SizedBox(
            height: 500,
            child: SfCartesianChart(
              backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              series: <CartesianSeries<ChartData, String>>[
                LineSeries<ChartData, String>(
                  dataSource: _frequencyData,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.value,
                  markerSettings: const MarkerSettings(isVisible: true),
                  color: chartLineColor,
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                _selectedTimeFilter == 0
                    ? "Frequency of Medicine Sales (Day)"
                    : _selectedTimeFilter == 1
                    ? "Frequency of Medicine Sales (Week)"
                    : _selectedTimeFilter == 2
                    ? "Frequency of Medicine Sales (Month)"
                    : "Frequency of Medicine Sales (Year)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  series: <CartesianSeries<ChartData, String>>[
                    LineSeries<ChartData, String>(
                      dataSource: _frequencyData,
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      markerSettings: const MarkerSettings(isVisible: true),
                      color: chartLineColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
