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
  double _totalSales = 0.0;
  double _clearedSales = 0.0;
  double _activeBalance = 0.0;

  List<ChartData> _salesData = [];
  List<ChartData> _frequencyData = [];
  List<Map<String, dynamic>> _transactions = [];

  Timer? _timer;

  int _selectedYear = DateTime
      .now()
      .year;
  int? _selectedMonth;
  int? _selectedWeek;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadClearedSales().then((_) {
      _fetchDashboardData();
    });
    _selectedYear = DateTime
        .now()
        .year;
    _selectedMonth = null;
    _selectedWeek = null;
    _selectedDay = null;
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

  Future<void> _fetchDashboardData() async {
    _transactions = await DatabaseHelper().getTransactions();
    double totalSalesSum = 0.0;
    double totalInsertedSum = 0.0;
    for (var tx in _transactions) {
      totalSalesSum += (tx['total_amount'] as num).toDouble();
      if (tx.containsKey('amount_inserted')) {
        totalInsertedSum += (tx['amount_inserted'] as num).toDouble();
      }
    }
    setState(() {
      totalTransactions = _transactions.length;
      _totalSales = totalSalesSum;
      _activeBalance = totalInsertedSum - _clearedSales;
      if (_activeBalance < 0) {
        _activeBalance = 0.0;
      }
    });
    _updateChartData();
  }

  void _clearActiveBalance() {
    setState(() {
      _clearedSales += _activeBalance;
      _activeBalance = 0.0;
    });
    _saveClearedSales(_clearedSales);
  }

  void _updateChartData() {
    if (_transactions.isEmpty) {
      setState(() {
        _salesData = [];
        _frequencyData = [];
      });
      return;
    }
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

    String groupingMode;
    if (_selectedMonth == null) {
      groupingMode = "month";
    } else if (_selectedWeek == null) {
      groupingMode = "week";
    } else {
      groupingMode = "day";
    }
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
      sortedKeys.sort((a, b) =>
          monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));
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

  double naiveForecast(List<double> historicalSales) {
    if (historicalSales.length < 2) {
      return historicalSales.isNotEmpty ? historicalSales.last : 0.0;
    }
    double totalGrowthRate = 0.0;
    int count = 0;
    for (int i = 1; i < historicalSales.length; i++) {
      if (historicalSales[i - 1] != 0) {
        double growthRate =
            (historicalSales[i] - historicalSales[i - 1]) /
                historicalSales[i - 1];
        totalGrowthRate += growthRate;
        count++;
      }
    }
    double avgGrowthRate = count > 0 ? (totalGrowthRate / count) : 0.0;
    return historicalSales.last * (1 + avgGrowthRate);
  }

  double _forecastNextMonthSales() {
    int year = DateTime
        .now()
        .year;
    Map<int, double> monthlySales = {};
    for (var tx in _transactions) {
      DateTime dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year == year) {
        monthlySales[dt.month] =
            (monthlySales[dt.month] ?? 0) +
                (tx['total_amount'] as num).toDouble();
      }
    }
    List<double> salesList = [];
    for (int m = 1; m <= DateTime
        .now()
        .month; m++) {
      salesList.add(monthlySales[m] ?? 0.0);
    }
    if (salesList.isEmpty) return 0.0;
    return naiveForecast(salesList);
  }

  Widget _buildForecastChart() {
    double forecastVal = _forecastNextMonthSales();
    int currentYear = DateTime
        .now()
        .year;
    int currentMonth = DateTime
        .now()
        .month;
    Map<int, double> monthlySales = {};
    for (var tx in _transactions) {
      DateTime dt = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      if (dt.year == currentYear) {
        monthlySales[dt.month] =
            (monthlySales[dt.month] ?? 0) +
                (tx['total_amount'] as num).toDouble();
      }
    }
    List<ChartData> chartData = [];
    for (int m = 1; m <= currentMonth; m++) {
      double val = monthlySales[m] ?? 0;
      String shortLabel = _monthName(m).substring(0, 3);
      chartData.add(ChartData(label: shortLabel, value: val));
    }
    chartData.add(ChartData(label: "Fcast", value: forecastVal));
    return Card(
      elevation: 4,
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Next Month Forecast: ₱${forecastVal.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
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

  Widget _buildQuickStats() {
    double avgTransaction = totalTransactions > 0 ? _totalSales /
        totalTransactions : 0;
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
              const Text(
                "Top-Selling Items",
                style: TextStyle(
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
                children: sortedItems
                    .asMap()
                    .entries
                    .map((entry) {
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

// ---------------------- FILTER ROW ----------------------
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

// ---------------------- YEAR ----------------------
  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Year: ",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: brandColor,
          iconEnabledColor: Colors.white,
          underline: Container(height: 2, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString(), style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedYear = val;
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

// ---------------------- MONTH ----------------------
  Widget _buildMonthDropdown() {
    final months = [null, for (var m = 1; m <= 12; m++) m];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Month: ",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        DropdownButton<int?>(
          value: _selectedMonth,
          dropdownColor: brandColor,
          iconEnabledColor: Colors.white,
          underline: Container(height: 2, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: months.map((m) {
            return DropdownMenuItem<int?>(
              value: m,
              child: Text(
                m == null ? "All" : _monthName(m),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedMonth = val;
              _selectedWeek = null;
              _selectedDay = null;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

// ---------------------- WEEK ----------------------
  Widget _buildWeekDropdown() {
    final weeks = [null, 1, 2, 3, 4, 5];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Week: ",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        DropdownButton<int?>(
          value: _selectedWeek,
          dropdownColor: brandColor,
          iconEnabledColor: Colors.white,
          underline: Container(height: 2, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: weeks.map((w) {
            return DropdownMenuItem<int?>(
              value: w,
              child: Text(
                w == null ? "All" : "Week $w",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedWeek = val;
              _selectedDay = null;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

// ---------------------- DAY ----------------------
  Widget _buildDayDropdown() {
    final daysInMonth = _daysInMonth(_selectedYear, _selectedMonth!);
    final days = <int?>[null, for (var i = 1; i <= daysInMonth; i++) i];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Day: ",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        DropdownButton<int?>(
          value: _selectedDay,
          dropdownColor: brandColor,
          iconEnabledColor: Colors.white,
          underline: Container(height: 2, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: days.map((d) {
            return DropdownMenuItem<int?>(
              value: d,
              child: Text(
                d == null ? "All" : d.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedDay = val;
            });
            _updateChartData();
          },
        ),
      ],
    );
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
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
      return "Sales for ${_monthName(
          _selectedMonth!)} $_selectedYear (by Week)";
    } else if (_selectedDay == null) {
      return "Sales for ${_monthName(
          _selectedMonth!)} (Week $_selectedWeek) $_selectedYear (by Day)";
    } else {
      return "Sales for ${_monthName(
          _selectedMonth!)} $_selectedDay, $_selectedYear (Day)";
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
      double saleValue = (tx['total_amount'] as num).toDouble();
      if (dt.year == currentYear && dt.month == currentMonth) {
        currentMonthSales += saleValue;
      } else if (dt.year == previousYear && dt.month == previousMonth) {
        previousMonthSales += saleValue;
      }
    }
    final double difference = currentMonthSales - previousMonthSales;
    double percentChange = 0.0;
    if (previousMonthSales != 0) {
      percentChange = (difference / previousMonthSales) * 100;
    }
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
                            ? "Your Current Month is ${percentChange
                            .toStringAsFixed(
                            2)}% higher than the Previous Month."
                            : "Your Current Month is ${percentChange
                            .abs()
                            .toStringAsFixed(
                            2)}% lower than the Previous Month.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D2A5E),
                        ),
                      ),
                    const SizedBox(height: 16),
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
                        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors
                            .white,
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('RFID')),
                          DataColumn(label: Text('Medicine')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Unit Price')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Inserted')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('User')),
                        ],
                        rows: _transactions.map((tx) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(tx['user_rfid'] ?? '–'),
                                onTap: () => _showDrillDownDetails(tx),
                              ),
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
                                Text(tx['amount_inserted']?.toString() ?? '0'),
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
                "Amount Inserted: ${transaction['amount_inserted']}\n"
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

  // ----------------------------------------------------------------------
  // ENLARGED SETTINGS DIALOG WITH ENLARGED BUTTONS
  // ----------------------------------------------------------------------
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 100, vertical: 100),
          title: const Text(
            "SETTINGS",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Container(
                width: 500,
                height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dark Mode Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Dark Mode", style: TextStyle(fontSize: 25)),
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
                    const SizedBox(height: 20),
                    // Export PDF Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _exportDataAsPDF,
                        child: const Text(
                          "Export Data as PDF",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // About Us Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AboutUsDialog(),
                          );
                        },
                        child: const Text(
                          "About Us",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 20),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _logOut,
                        child: const Text(
                          "Log Out",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------

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
      // make the Scaffold itself transparent
      backgroundColor: Colors.transparent,
      // allow the AppBar to float over the gradient (optional)
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Welcome, Admin!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // make AppBar transparent so the gradient shows through
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),

      // wrap the body in your branded gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D2A5E), // Start color
              Color(0xFF1E5D6F), // End color
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildQuickStats(),
                const SizedBox(height: 20),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 28,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Inventory"),
        ],
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
                  backgroundColor: _isDarkMode ? Colors.grey[900] : Colors
                      .white,
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
    // Use the same bar color as your sales chart
    final Color chartBarColor = _isDarkMode ? Colors.cyanAccent : brandColor;

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
                ColumnSeries<ChartData, String>(
                  dataSource: _frequencyData,
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
                  backgroundColor: _isDarkMode ? Colors.grey[900] : Colors
                      .white,
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
                      dataSource: _frequencyData,
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
}

// --------------------- ABOUT US DIALOG ---------------------
class AboutUsDialog extends StatefulWidget {
  const AboutUsDialog({Key? key}) : super(key: key);

  @override
  _AboutUsDialogState createState() => _AboutUsDialogState();
}

class _AboutUsDialogState extends State<AboutUsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Team members
  final List<Map<String, String>> teamMembers = [
    {
      "name": "Maritonee Cardenas \n [Project Manager]",
      "image": "assets/images/mai.png",
    },
    {
      "name": "Rustan  Chavez \n [Developer]",
      "image": "assets/images/rustan.png",
    },
    {
      "name": "Russel Jr.\n [Quality Tester]",
      "image": "assets/images/russel.png",
    },
    {
      "name": "John Mark Romulo \n [Developer]",
      "image": "assets/images/jm.png",
    },
    {
      "name": "Angelo Delos Santos \n [Developer]",
      "image": "assets/images/angelo.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds a card for each team member.
  Widget _buildMemberCard(Map<String, String> member) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(member["image"]!),
            ),
            const SizedBox(height: 20),
            Text(
              member["name"]!,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0D2A5E),
                Color(0xFF1E5D6F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "About Us",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "We are Group 2 of Block 3 Computer Engineering, consisting of 5 dedicated members:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildMemberCard(teamMembers[0])),
                        const SizedBox(width: 20),
                        Expanded(child: _buildMemberCard(teamMembers[1])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildMemberCard(teamMembers[2])),
                        const SizedBox(width: 20),
                        Expanded(child: _buildMemberCard(teamMembers[3])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 400,
                          child: _buildMemberCard(teamMembers[4]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  runApp(MaterialApp(
    home: DashboardScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
