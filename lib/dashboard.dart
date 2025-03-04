// dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'transaction.dart';
import 'splash_screen.dart';
import 'database_helper.dart';

// Model for chart data.
class ChartData {
  final String label;
  final num value;
  ChartData({required this.label, required this.value});
}

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  int _selectedTimeFilter = 2; // Default to "Month"
  bool _isDarkMode = false; // Dark mode state
  int totalTransactions = 0; // Total transaction count from DB
  double _activeBalance = 0.0; // Active balance (sum of total_amount)

  // These lists hold the current data displayed in the charts.
  List<ChartData> _salesData = [];
  List<ChartData> _frequencyData = [];

  // All transactions fetched from DB.
  List<Map<String, dynamic>> _transactions = [];

  // Time filter options.
  final List<String> timeFilters = ["Day", "Week", "Month", "Year"];

  @override
  void initState() {
    super.initState();
    // Fetch all data from the database when the screen loads.
    _fetchDashboardData();
  }

  // Fetch transactions from the database and compute active balance and count.
  Future<void> _fetchDashboardData() async {
    _transactions = await DatabaseHelper().getTransactions();
    double sum = 0.0;
    for (var tx in _transactions) {
      sum += (tx['total_amount'] as num).toDouble();
    }
    setState(() {
      totalTransactions = _transactions.length;
      _activeBalance = sum;
    });
    // After fetching transactions, update chart data.
    _updateChartData();
  }

  // Update chart data based on the selected time filter.
  void _updateChartData() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filtered = [];

    // Filter transactions based on the selected time filter.
    if (_selectedTimeFilter == 0) { // Day: transactions for today.
      filtered = _transactions.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }).toList();
    } else if (_selectedTimeFilter == 1) { // Week: transactions in current week.
      int weekday = now.weekday;
      DateTime startOfWeek = now.subtract(Duration(days: weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
      filtered = _transactions.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        return dt.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            dt.isBefore(endOfWeek.add(Duration(days: 1)));
      }).toList();
    } else if (_selectedTimeFilter == 2) { // Month: transactions in current month.
      filtered = _transactions.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        return dt.year == now.year && dt.month == now.month;
      }).toList();
    } else { // Year: transactions in current year.
      filtered = _transactions.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        return dt.year == now.year;
      }).toList();
    }

    // Aggregate sales data (sum of total_amount) based on time grouping.
    Map<String, double> salesMap = {};
    if (_selectedTimeFilter == 0) { // Group by hour for today.
      for (var tx in filtered) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        String key = dt.hour.toString();
        salesMap[key] = (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    } else if (_selectedTimeFilter == 1) { // Group by weekday for current week.
      for (var tx in filtered) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        String key = _weekdayName(dt.weekday);
        salesMap[key] = (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    } else if (_selectedTimeFilter == 2) { // Group by day (of month) for current month.
      for (var tx in filtered) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        String key = dt.day.toString();
        salesMap[key] = (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    } else { // Group by month for current year.
      for (var tx in filtered) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? now;
        String key = _monthName(dt.month);
        salesMap[key] = (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    }

    // Convert aggregated sales data to ChartData.
    List<ChartData> salesData = [];
    if (_selectedTimeFilter == 0) {
      var keys = salesMap.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      for (var key in keys) {
        salesData.add(ChartData(label: "$key:00", value: salesMap[key]!));
      }
    } else if (_selectedTimeFilter == 1) {
      // Use a fixed weekday order.
      List<String> weekdayOrder = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      for (var day in weekdayOrder) {
        if (salesMap.containsKey(day)) {
          salesData.add(ChartData(label: day, value: salesMap[day]!));
        }
      }
    } else if (_selectedTimeFilter == 2) {
      var keys = salesMap.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      for (var key in keys) {
        salesData.add(ChartData(label: "Day $key", value: salesMap[key]!));
      }
    } else {
      List<String> monthOrder = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      for (var month in monthOrder) {
        if (salesMap.containsKey(month)) {
          salesData.add(ChartData(label: month, value: salesMap[month]!));
        }
      }
    }

    // Frequency Chart: Group by medicine to sum the quantity sold.
    Map<String, int> freqMap = {};
    for (var tx in _transactions) {
      String med = tx['medicine'];
      freqMap[med] = (freqMap[med] ?? 0) + (tx['quantity'] as int);
    }
    List<ChartData> freqData = [];
    freqMap.forEach((med, qty) {
      freqData.add(ChartData(label: med, value: qty));
    });

    setState(() {
      _salesData = salesData;
      _frequencyData = freqData;
    });
  }

  // Helper: Get weekday name from integer.
  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "";
    }
  }

  // Helper: Get month name from integer.
  String _monthName(int month) {
    switch (month) {
      case 1:
        return "January";
      case 2:
        return "February";
      case 3:
        return "March";
      case 4:
        return "April";
      case 5:
        return "May";
      case 6:
        return "June";
      case 7:
        return "July";
      case 8:
        return "August";
      case 9:
        return "September";
      case 10:
        return "October";
      case 11:
        return "November";
      case 12:
        return "December";
      default:
        return "";
    }
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

  // Settings dialog.
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
                  // Dark Mode toggle.
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
                          setStateDialog(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Log Out button.
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
    Navigator.pop(context); // Close settings dialog.
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
      // Navigate to TransactionScreen when Payments tab is selected.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransactionScreen()),
      );
    }
    // Extend for other tabs as needed.
  }

  // Update time filter selection and recalc chart data.
  void _onTimeFilterSelected(int index) {
    setState(() {
      _selectedTimeFilter = index;
    });
    _updateChartData();
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

  // Build the Active Balance card using the computed _activeBalance.
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
                  "₱${_activeBalance.toStringAsFixed(2)}",
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

  // Sales Statistics section, including dynamic total transactions.
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
        const SizedBox(height: 20),
        // Dynamic total transactions display.
        Row(
          children: [
            const Text(
              "Total Transactions: ",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              "$totalTransactions",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
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

  // Sales Chart using dynamic _salesData.
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

  // Frequency Chart using dynamic _frequencyData.
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
