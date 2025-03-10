import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'transaction.dart';
import 'splash_screen.dart';
import 'database_helper.dart';
import 'user.dart';


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
  bool _isDarkMode = false; // Dark mode state
  int totalTransactions = 0; // Total transaction count from DB
  double _activeBalance = 0.0; // Active balance (sum of total_amount)
  // Chart data lists.
  List<ChartData> _salesData = [];
  List<ChartData> _frequencyData = [];
  // All transactions fetched from DB.
  List<Map<String, dynamic>> _transactions = [];
  Timer? _timer;

  // Hierarchical filter state.
  // _selectedYear is required. The others are optional (null means "All").
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth; // null means all months in the year
  int? _selectedWeek;  // null means all weeks in the month
  int? _selectedDay;   // null means all days in the week

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = null;
    _selectedWeek = null;
    _selectedDay = null;
    _fetchDashboardData();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fetch transactions and compute active balance.
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
    _updateChartData();
  }

  // Update chart data based on the hierarchical filters.
  // Removed hour-level grouping; if a day is selected, we simply show "day" grouping.
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

    // 2) Decide how to group the filtered data.
    //    We have only three grouping modes now: month, week, or day.
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
        // groupingMode == "day"
        // We'll label the bar by the day number
        key = dt.day.toString();
      }
      salesMap[key] = (salesMap[key] ?? 0) + (tx['total_amount'] as num).toDouble();
    }

    // 4) Sort the keys in a logical order (month names, then week #, then day #).
    final sortedKeys = salesMap.keys.toList();
    if (groupingMode == "month") {
      final monthOrder = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      sortedKeys.sort((a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)));
    } else if (groupingMode == "week") {
      sortedKeys.sort((a, b) {
        final aNum = int.tryParse(a.replaceAll("Week ", "")) ?? 0;
        final bNum = int.tryParse(b.replaceAll("Week ", "")) ?? 0;
        return aNum.compareTo(bNum);
      });
    } else {
      // groupingMode == "day"
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

  // Helpers to get weekday and month names.
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

  // Build the filter row using a horizontal scroll view to keep all dropdowns on one line.
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
    // For example, show a range from currentYear-2 to currentYear+2.
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
              // Reset lower-level filters.
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
    // Dropdown with an "All" option (null) and the 12 months.
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
    // Weeks 1 to 5 with an "All" option.
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
    // Calculate the number of days in the selected month.
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

  // Helper: Returns the number of days in a given month/year.
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

  // Generate a title for the sales chart based on active filters.
  // Removed the "(by hour)" label. Now it just shows "(Day)" if a day is selected.
  String _getSalesChartTitle() {
    if (_selectedMonth == null) {
      // Entire year
      return "Sales for $_selectedYear (by Month)";
    } else if (_selectedWeek == null) {
      // Month-level
      return "Sales for ${_monthName(_selectedMonth!)} $_selectedYear (by Week)";
    } else if (_selectedDay == null) {
      // Week-level
      return "Sales for ${_monthName(_selectedMonth!)} (Week $_selectedWeek) $_selectedYear (by Day)";
    } else {
      // Day-level
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

  // The "View Details" modal.
  void _showViewDetailsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: _isDarkMode ? Colors.black : Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title and close "X" button.
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
                        icon: Icon(Icons.close,
                            color: _isDarkMode ? Colors.white : Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Graphical Insights: a mini chart.
                  SizedBox(
                    height: 200,
                    child: SfCartesianChart(
                      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
                      primaryXAxis: CategoryAxis(
                        labelStyle: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black),
                      ),
                      primaryYAxis: NumericAxis(
                        labelStyle: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<ChartData, String>(
                          dataSource: _salesData,
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
                  // Detailed Transaction List in a horizontal scrollable DataTable.
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
          ),
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
          title: Text("Transaction Details"),
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
                      backgroundColor: const Color(0xFF0D2A5E),
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

  // Bottom navigation tab selection.
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
          builder: (context) => TransactionScreen(isDarkMode: _isDarkMode),
        ),
      );
    }
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserScreen(isDarkMode: _isDarkMode)),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: "Payments"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Inventory"),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildFiltersRow(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      "Total Transactions: ",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    Text(
                      "$totalTransactions",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
                ElevatedButton(
                  onPressed: _showViewDetailsModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text("View Details",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final Color chartBarColor =
    _isDarkMode ? Colors.cyanAccent : const Color(0xFF0D2A5E);
    return GestureDetector(
      onTap: () {
        _showBigChart(
          _getSalesChartTitle(),
          SizedBox(
            height: 500,
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
        );
      },
      child: Card(
        elevation: 4,
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final Color chartLineColor =
    _isDarkMode ? Colors.cyanAccent : const Color(0xFF0D2A5E);
    return GestureDetector(
      onTap: () {
        _showBigChart(
          "Frequency of Medicine Sales",
          SizedBox(
            height: 500,
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
        );
      },
      child: Card(
        elevation: 4,
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
