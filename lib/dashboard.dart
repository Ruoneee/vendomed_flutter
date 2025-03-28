import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transaction.dart';
import 'splash_screen.dart';
import 'database_helper.dart';
import 'user.dart';
import 'inventory.dart';

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
  final Color brandColor = const Color(0xFF0D2A5E);

  int _selectedTabIndex = 0;
  bool _isDarkMode = false;

  int totalTransactions = 0;

  // _totalSales: the grand total from all transactions (historical).
  double _totalSales = 0.0;

  // _clearedSales: the value of _totalSales at the time of last clearing,
  // persisted in SharedPreferences so we remember across sessions.
  double _clearedSales = 0.0;

  // _activeBalance = _totalSales - _clearedSales
  double _activeBalance = 0.0;

  List<ChartData> _salesData = [];
  List<ChartData> _frequencyData = [];
  List<Map<String, dynamic>> _transactions = [];

  Timer? _timer;

  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  int? _selectedWeek;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();

    // 1) Load the previously saved clearedSales from SharedPreferences
    _loadClearedSales().then((_) {
      // After loading _clearedSales, fetch transactions & do the rest.
      _fetchDashboardData();
    });

    _selectedYear = DateTime.now().year;
    _selectedMonth = null;
    _selectedWeek = null;
    _selectedDay = null;

    // If you want to refresh periodically:
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ----------------- PERSISTENCE METHODS -----------------
  Future<void> _loadClearedSales() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clearedSales = prefs.getDouble('clearedSales') ?? 0.0;
    });
  }

  Future<void> _saveClearedSales(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('clearedSales', value);
  }
  // --------------------------------------------------------

  // Fetch transactions, compute total sales, then compute active balance.
  Future<void> _fetchDashboardData() async {
    _transactions = await DatabaseHelper().getTransactions();
    double sum = 0.0;
    for (var tx in _transactions) {
      sum += (tx['total_amount'] as num).toDouble();
    }

    setState(() {
      totalTransactions = _transactions.length;
      _totalSales = sum;

      // Recompute active balance using the loaded/remembered _clearedSales
      _activeBalance = _totalSales - _clearedSales;
      if (_activeBalance < 0) {
        // Just in case something odd happened:
        _activeBalance = 0.0;
      }
    });

    _updateChartData();
  }

  // When clearing balance, set _clearedSales to the current total,
  // so that going forward, new transactions show up in _activeBalance.
  void _clearActiveBalance() {
    setState(() {
      _clearedSales = _totalSales;
      _activeBalance = 0.0;
    });
    // Save the updated clearedSales so that after log-out/log-in,
    // we still remember that we cleared at this total.
    _saveClearedSales(_clearedSales);
  }

  // Update chart data based on the hierarchical filters.
  void _updateChartData() {
    if (_transactions.isEmpty) {
      setState(() {
        _salesData = [];
        _frequencyData = [];
      });
      return;
    }

    // 1) Filter transactions by year, month, week, and day.
    List<Map<String, dynamic>> filtered = _transactions.where((tx) {
      final dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year != _selectedYear) return false;
      if (_selectedMonth != null && dt.month != _selectedMonth) return false;
      if (_selectedWeek != null) {
        final weekOfMonth = ((dt.day - 1) ~/ 7) + 1;
        if (weekOfMonth != _selectedWeek) return false;
      }
      if (_selectedDay != null && dt.day != _selectedDay) return false;
      return true;
    }).toList();

    // 2) Decide how to group the filtered data: month, week, or day.
    String groupingMode;
    if (_selectedMonth == null) {
      groupingMode = "month";
    } else if (_selectedWeek == null) {
      groupingMode = "week";
    } else {
      groupingMode = "day";
    }

    // 3) Build salesMap for the chosen grouping.
    final Map<String, double> salesMap = {};
    for (var tx in filtered) {
      final dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      String key;
      if (groupingMode == "month") {
        key = _monthName(dt.month);
      } else if (groupingMode == "week") {
        final weekOfMonth = ((dt.day - 1) ~/ 7) + 1;
        key = "Week $weekOfMonth";
      } else {
        key = dt.day.toString();
      }
      salesMap[key] =
          (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
    }

    // 4) Sort the keys in a logical order.
    final sortedKeys = salesMap.keys.toList();
    if (groupingMode == "month") {
      final monthOrder = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ];
      sortedKeys.sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));
    } else if (groupingMode == "week") {
      sortedKeys.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll("Week ", "")) ?? 0;
        final bNum = int.tryParse(b.replaceAll("Week ", "")) ?? 0;
        return aNum.compareTo(bNum);
      });
    } else {
      sortedKeys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }

    final List<ChartData> salesData = sortedKeys
        .map((key) => ChartData(label: key, value: salesMap[key]!))
        .toList();

    // 5) Build frequency data (group by medicine).
    final Map<String, int> freqMap = {};
    for (var tx in filtered) {
      final med = tx['medicine'] ?? 'Unknown';
      freqMap[med] = (freqMap[med] ?? 0) + (tx['quantity'] as int? ?? 0);
    }
    final List<ChartData> freqData = freqMap.entries
        .map((e) => ChartData(label: e.key, value: e.value))
        .toList();

    setState(() {
      _salesData = salesData;
      _frequencyData = freqData;
    });
  }

  // NAIVE FORECAST FUNCTION + NEXT-MONTH FORECAST
  double naiveForecast(List<double> historicalSales) {
    if (historicalSales.length < 2) {
      return historicalSales.isNotEmpty ? historicalSales.last : 0.0;
    }
    double totalGrowthRate = 0.0;
    int count = 0;
    for (int i = 1; i < historicalSales.length; i++) {
      if (historicalSales[i - 1] != 0) {
        double growthRate =
            (historicalSales[i] - historicalSales[i - 1]) / historicalSales[i - 1];
        totalGrowthRate += growthRate;
        count++;
      }
    }
    double avgGrowthRate = count > 0 ? (totalGrowthRate / count) : 0.0;
    return historicalSales.last * (1 + avgGrowthRate);
  }

  double _forecastNextMonthSales() {
    int year = DateTime.now().year;
    Map<int, double> monthlySales = {};

    // Sum sales for each month in the current year
    for (var tx in _transactions) {
      DateTime dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year == year) {
        monthlySales[dt.month] =
            (monthlySales[dt.month] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    }

    // Build a list of monthly sales from January up to current month
    List<double> salesList = [];
    for (int m = 1; m <= DateTime.now().month; m++) {
      salesList.add(monthlySales[m] ?? 0.0);
    }

    if (salesList.isEmpty) return 0.0;
    return naiveForecast(salesList);
  }

  // MERGED FORECAST: Single Chart that displays the numeric forecast
  Widget _buildForecastChart() {
    // 1) Calculate the forecast value
    double forecastVal = _forecastNextMonthSales();

    // 2) Gather monthly sales for the current year
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    Map<int, double> monthlySales = {};
    for (var tx in _transactions) {
      DateTime dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year == currentYear) {
        monthlySales[dt.month] =
            (monthlySales[dt.month] ?? 0) + (tx['total_amount'] as num).toDouble();
      }
    }

    // 3) Build a list of ChartData for each month so far
    List<ChartData> chartData = [];
    for (int m = 1; m <= currentMonth; m++) {
      double val = monthlySales[m] ?? 0;
      String shortLabel = _monthName(m).substring(0, 3); // e.g. "Jan"
      chartData.add(ChartData(label: shortLabel, value: val));
    }

    // 4) Append the forecast as "Fcast"
    chartData.add(ChartData(label: "Fcast", value: forecastVal));

    // 5) Return a single card that displays the numeric forecast + chart
    return Card(
      elevation: 4,
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Forecast Value in the header
            Text(
              "Next Month Forecast: ₱${forecastVal.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // The mini chart
            SizedBox(
              height: 220, // adjust as needed
              child: SfCartesianChart(
                backgroundColor:
                _isDarkMode ? Colors.grey[900] : Colors.white,
                primaryXAxis: CategoryAxis(
                  labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                series: <CartesianSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: _isDarkMode ? Colors.cyanAccent : brandColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
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

  // --- HELPER WIDGET: Single KPI Card with gradient background ---
  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [brandColor, brandColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon in a circular container for contrast
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Stats
  Widget _buildQuickStats() {
    double avgTransaction =
    totalTransactions > 0 ? _totalSales / totalTransactions : 0;
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            icon: Icons.attach_money,
            label: "Total Sales",
            value: "₱${_totalSales.toStringAsFixed(2)}",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            icon: Icons.receipt_long,
            label: "Transactions",
            value: "$totalTransactions",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildKpiCard(
            icon: Icons.show_chart,
            label: "Avg. Value",
            value: "₱${avgTransaction.toStringAsFixed(2)}",
          ),
        ),
      ],
    );
  }

  // Top-Selling Items
  Widget _buildTopSellingItems() {
    List<ChartData> sortedItems = List.from(_frequencyData);
    sortedItems.sort((a, b) => b.value.compareTo(a.value));
    if (sortedItems.length > 3) {
      sortedItems = sortedItems.sublist(0, 3);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              brandColor.withOpacity(0.9),
              brandColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Top-Selling Items",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              sortedItems.isEmpty
                  ? const Text(
                "No data available",
                style: TextStyle(color: Colors.white),
              )
                  : Column(
                children: sortedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        "#${index + 1}",
                        style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      "${item.value}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildYearDropdown(),
          const SizedBox(width: 16),
          _buildMonthDropdown(),
          if (_selectedMonth != null) ...[
            const SizedBox(width: 16),
            _buildWeekDropdown(),
          ],
          if (_selectedMonth != null && _selectedWeek != null) ...[
            const SizedBox(width: 16),
            _buildDayDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Year: "),
        DropdownButton<int>(
          value: _selectedYear,
          items: years
              .map((year) => DropdownMenuItem<int>(
            value: year,
            child: Text("$year"),
          ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedYear = value;
              _selectedMonth = null;
              _selectedWeek = null;
              _selectedDay = null;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

  Widget _buildMonthDropdown() {
    final months = [null, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Month: "),
        DropdownButton<int?>(
          value: _selectedMonth,
          items: months.map((m) {
            if (m == null) {
              return const DropdownMenuItem<int?>(
                value: null,
                child: Text("All"),
              );
            }
            return DropdownMenuItem<int?>(
              value: m,
              child: Text(_monthName(m)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMonth = value;
              _selectedWeek = null;
              _selectedDay = null;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

  Widget _buildWeekDropdown() {
    final weeks = [null, 1, 2, 3, 4, 5];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Week: "),
        DropdownButton<int?>(
          value: _selectedWeek,
          items: weeks.map((w) {
            if (w == null) {
              return const DropdownMenuItem<int?>(
                value: null,
                child: Text("All"),
              );
            }
            return DropdownMenuItem<int?>(
              value: w,
              child: Text("Week $w"),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWeek = value;
              _selectedDay = null;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

  Widget _buildDayDropdown() {
    final daysInMonth = _daysInMonth(_selectedYear, _selectedMonth!);
    final days = <int?>[null];
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Day: "),
        DropdownButton<int?>(
          value: _selectedDay,
          items: days.map((d) {
            if (d == null) {
              return const DropdownMenuItem<int?>(
                value: null,
                child: Text("All"),
              );
            }
            return DropdownMenuItem<int?>(
              value: d,
              child: Text("$d"),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDay = value;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      // Leap year check.
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      }
      return 28;
    }
    if ([4, 6, 9, 11].contains(month)) return 30;
    return 31;
  }

  String _getSalesChartTitle() {
    if (_selectedMonth == null) {
      return "Sales for $_selectedYear (by Month)";
    } else if (_selectedWeek == null) {
      return "Sales for ${_monthName(_selectedMonth!)} $_selectedYear (by Week)";
    } else if (_selectedDay == null) {
      return "Sales for ${_monthName(_selectedMonth!)} (Week $_selectedWeek) $_selectedYear (by Day)";
    } else {
      return "Sales for ${_monthName(_selectedMonth!)} $_selectedDay, $_selectedYear (Day)";
    }
  }

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

  // Helper for summary cards in the "View Details" modal.
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color backgroundColor,
    bool isDarkMode = false,
  }) {
    return Expanded(
      child: Card(
        color: backgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The "View Details" modal.
  void _showViewDetailsModal() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final previousMonth = (currentMonth == 1) ? 12 : currentMonth - 1;
    final previousYear = (currentMonth == 1) ? currentYear - 1 : currentYear;

    double currentMonthSales = 0.0;
    double previousMonthSales = 0.0;

    for (var tx in _transactions) {
      final dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year == currentYear && dt.month == currentMonth) {
        currentMonthSales += (tx['total_amount'] as num).toDouble();
      } else if (dt.year == previousYear && dt.month == previousMonth) {
        previousMonthSales += (tx['total_amount'] as num).toDouble();
      }
    }

    final double difference = currentMonthSales - previousMonthSales;

    // Calculate % difference
    double percentChange = 0.0;
    if (previousMonthSales != 0) {
      percentChange = (difference / previousMonthSales) * 100;
    }

    // Prepare chart data
    List<ChartData> comparisonData = [
      ChartData(label: 'Previous Month', value: previousMonthSales),
      ChartData(label: 'Current Month', value: currentMonthSales),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: _isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transaction Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Summary Cards
                    Row(
                      children: [
                        _buildSummaryCard(
                          title: "Previous Month",
                          value: "₱${previousMonthSales.toStringAsFixed(2)}",
                          backgroundColor: const Color(0xFF1B3B6F),
                          isDarkMode: _isDarkMode,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          title: "Current Month",
                          value: "₱${currentMonthSales.toStringAsFixed(2)}",
                          backgroundColor: const Color(0xFF0D2A5E),
                          isDarkMode: _isDarkMode,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          title: "Difference",
                          value: difference >= 0
                              ? "+₱${difference.toStringAsFixed(2)}"
                              : "-₱${difference.abs().toStringAsFixed(2)}",
                          backgroundColor: const Color(0xFF4682B4),
                          isDarkMode: _isDarkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (previousMonthSales == 0)
                      Text(
                        "No previous month data to compare.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D2A5E),
                        ),
                      )
                    else
                      Text(
                        difference >= 0
                            ? "Your Current Month is ${percentChange.toStringAsFixed(2)}% higher than the Previous Month."
                            : "Your Current Month is ${percentChange.abs().toStringAsFixed(2)}% lower than the Previous Month.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D2A5E),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Comparison Chart
                    Text(
                      "Comparison: Previous vs Current Month",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: SfCartesianChart(
                        backgroundColor:
                        _isDarkMode ? Colors.grey[900] : Colors.white,
                        primaryXAxis: CategoryAxis(
                          labelStyle: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        primaryYAxis: NumericAxis(
                          labelStyle: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        series: <CartesianSeries<ChartData, String>>[
                          ColumnSeries<ChartData, String>(
                            dataSource: comparisonData,
                            xValueMapper: (ChartData data, _) => data.label,
                            yValueMapper: (ChartData data, _) => data.value,
                            color: _isDarkMode
                                ? Colors.cyanAccent
                                : const Color(0xFF0D2A5E),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Transaction DataTable
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Medicine')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Unit Price')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('User')),
                        ],
                        rows: _transactions.map((tx) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(tx['medicine'] ?? 'N/A'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['quantity']?.toString() ?? '0'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['unit_price']?.toString() ?? '0'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['total_amount']?.toString() ?? '0'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['date'] ?? 'N/A'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['payment_method'] ?? 'N/A'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                              DataCell(
                                Text(tx['user_type'] ?? 'N/A'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Drill-down modal for individual transaction details.
  void _showDrillDownDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Transaction Details"),
          content: Text(
            "Medicine: ${transaction['medicine']}\n"
                "Quantity: ${transaction['quantity']}\n"
                "Unit Price: ${transaction['unit_price']}\n"
                "Total Amount: ${transaction['total_amount']}\n"
                "Date: ${transaction['date']}\n"
                "Payment Method: ${transaction['payment_method']}\n"
                "User Type: ${transaction['user_type']}\n"
                "Additional info or notes can be added here.",
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

  Future<pw.Document> _generatePDF() async {
    final transactions = await DatabaseHelper().getTransactions();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("Transactions Backup", style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'ID',
                  'Medicine',
                  'Quantity',
                  'Unit Price',
                  'Total',
                  'Date',
                  'Payment',
                  'User'
                ],
                data: transactions.map((tx) {
                  return [
                    tx['transaction_id'].toString(),
                    tx['medicine'],
                    tx['quantity'].toString(),
                    tx['unit_price'].toString(),
                    tx['total_amount'].toString(),
                    tx['date'],
                    tx['payment_method'],
                    tx['user_type']
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _exportDataAsPDF() async {
    final pdf = await _generatePDF();
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'transactions_backup.pdf');
  }

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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () {
                      _exportDataAsPDF();
                    },
                    child: const Text("Export Data as PDF",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                    ),
                    onPressed: _logOut,
                    child: const Text("Log Out",
                        style: TextStyle(color: Colors.white)),
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

  void _logOut() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => TransactionScreen(isDarkMode: _isDarkMode)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => UserScreen(isDarkMode: _isDarkMode)),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => InventoryScreen(isDarkMode: _isDarkMode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Welcome, Admin!",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: brandColor,
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
                _buildQuickStats(),
                const SizedBox(height: 20),
                // NEW: Single chart card that includes forecast value
                _buildForecastChart(),
                const SizedBox(height: 20),
                _buildTopSellingItems(),
                const SizedBox(height: 20),
                _buildFiltersRow(),
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
                  "₱${_activeBalance.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _showViewDetailsModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text("View Details",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    // The new Clear button
                    ElevatedButton(
                      onPressed: _clearActiveBalance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        "Clear Balance",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final Color chartBarColor = _isDarkMode ? Colors.cyanAccent : brandColor;
    return GestureDetector(
      onTap: () {
        _showBigChart(
          _getSalesChartTitle(),
          SizedBox(
            height: 500,
            child: SfCartesianChart(
              backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(
                    color: _isDarkMode ? Colors.white : Colors.black),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(
                    color: _isDarkMode ? Colors.white : Colors.black),
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
                _getSalesChartTitle(),
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
                  backgroundColor:
                  _isDarkMode ? Colors.grey[900] : Colors.white,
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(
                        color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(
                        color: _isDarkMode ? Colors.white : Colors.black),
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

  Widget _buildFrequencyChart() {
    final Color chartLineColor = _isDarkMode ? Colors.cyanAccent : brandColor;
    return GestureDetector(
      onTap: () {
        _showBigChart(
          "Frequency of Medicine Sales",
          SizedBox(
            height: 500,
            child: SfCartesianChart(
              backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(
                    color: _isDarkMode ? Colors.white : Colors.black),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black),
                axisLine: AxisLine(
                    color: _isDarkMode ? Colors.white : Colors.black),
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
                "Frequency of Medicine Sales",
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
                  backgroundColor:
                  _isDarkMode ? Colors.grey[900] : Colors.white,
                  primaryXAxis: CategoryAxis(
                    labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(
                        color: _isDarkMode ? Colors.white : Colors.black),
                  ),
                  primaryYAxis: NumericAxis(
                    labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black),
                    axisLine: AxisLine(
                        color: _isDarkMode ? Colors.white : Colors.black),
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
