import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dashboard.dart';
import 'database_helper.dart';
import 'user.dart';
import 'inventory.dart';

/// Model for payment methods in the pie chart.
class PaymentMethodData {
  final String method;
  final double percentage;
  PaymentMethodData(this.method, this.percentage);
}

/// Model for individual transactions.
class TransactionItem {
  final String medicine;
  final String date;
  final double totalAmount;
  final String paymentMethod;

  TransactionItem({
    required this.medicine,
    required this.date,
    required this.totalAmount,
    required this.paymentMethod,
  });
}

/// TransactionScreen now accepts the dark mode setting.
class TransactionScreen extends StatefulWidget {
  final bool isDarkMode;
  const TransactionScreen({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late bool _isDarkMode;
  Timer? _timer;
  late Future<List<TransactionItem>> _futureTransactions;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _futureTransactions = _fetchTransactions();

    // Periodically refresh the transactions every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _futureTransactions = _fetchTransactions();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<TransactionItem>> _fetchTransactions() async {
    final dataList = await DatabaseHelper().getTransactions();
    return dataList.map((row) {
      return TransactionItem(
        medicine: row['medicine'],
        date: row['date'],
        totalAmount: row['total_amount'] is int
            ? (row['total_amount'] as int).toDouble()
            : row['total_amount'],
        paymentMethod: row['payment_method'],
      );
    }).toList();
  }

  // Build a card for a single transaction.
  Widget _buildTransactionCard(TransactionItem tx) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.medication, color: Colors.white70, size: 32),
        ),
        title: Text(
          tx.medicine,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          tx.date,
          style: TextStyle(
            fontSize: 18,
            color: _isDarkMode ? Colors.white70 : Colors.grey,
          ),
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

  /// Builds the pie chart widget for payment methods.
  Widget _buildPieChart(
      BuildContext context,
      List<PaymentMethodData> paymentMethods,
      bool isDarkMode,
      ) {
    return SizedBox(
      height: 400,
      child: SfCircularChart(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        legend: Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
          position: LegendPosition.bottom,
          textStyle: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        series: <CircularSeries>[
          PieSeries<PaymentMethodData, String>(
            dataSource: paymentMethods,
            xValueMapper: (PaymentMethodData data, _) => data.method,
            yValueMapper: (PaymentMethodData data, _) => data.percentage,
            pointColorMapper: (PaymentMethodData data, _) {
              switch (data.method) {
                case 'Cash/Coins':
                // Example brand color
                  return const Color(0xFF0D2A5E);
                case 'Points':
                // Another shade in the brand palette
                  return const Color(0xFF546E94);
                default:
                  return Colors.grey;
              }
            },
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the stats section (Total Transactions, Most Used Method, etc.).
  Widget _buildStats(
      BuildContext context,
      int totalCount,
      String mostUsedMethod,
      bool isDarkMode,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: Total Transactions & Most Used Method
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Transactions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Transactions:",
                  style: TextStyle(
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "$totalCount",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            // Most Used Method
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Most Used Method",
                  style: TextStyle(
                    fontSize: 20,
                    color: isDarkMode ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // The ₱ icon is optional; remove if desired
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// Builds the entire analytics section with a responsive layout:
  /// - Wide screens: chart & stats side by side
  /// - Narrow screens: chart & stats stacked vertically
  Widget _buildAnalyticsSection({
    required BuildContext context,
    required int totalCount,
    required double percentCashCoins,
    required double percentPoints,
    required String mostUsedMethod,
    required bool isDarkMode,
    required List<PaymentMethodData> paymentMethods,
  }) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // If screen width > 600, show chart & stats side by side
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildPieChart(ctx, paymentMethods, isDarkMode),
              ),
              const SizedBox(width: 30),
              Expanded(
                flex: 1,
                child: _buildStats(ctx, totalCount, mostUsedMethod, isDarkMode),
              ),
            ],
          );
        } else {
          // Otherwise, stack them vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPieChart(ctx, paymentMethods, isDarkMode),
              const SizedBox(height: 30),
              _buildStats(ctx, totalCount, mostUsedMethod, isDarkMode),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[900] : const Color(0xFF0D2A5E),
      ),
      body: FutureBuilder<List<TransactionItem>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No transactions available',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          }

          final transactions = snapshot.data!;
          final totalCount = transactions.length;

          // Payment method calculations (Cash/Coins and Points only)
          int cashCoinsCount = transactions
              .where((tx) => tx.paymentMethod == 'Cash/Coins')
              .length;
          int pointsCount =
              transactions.where((tx) => tx.paymentMethod == 'Points').length;

          double percentCashCoins =
          totalCount > 0 ? (cashCoinsCount / totalCount * 100) : 0;
          double percentPoints =
          totalCount > 0 ? (pointsCount / totalCount * 100) : 0;

          // Determine most used method
          String mostUsedMethod = (cashCoinsCount >= pointsCount)
              ? "Cash/Coins"
              : "Points";

          final List<PaymentMethodData> paymentMethods = [
            PaymentMethodData("Cash/Coins", percentCashCoins),
            PaymentMethodData("Points", percentPoints),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Payment Analytics" heading
                Text(
                  "Payment Analytics",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Responsive analytics section
                _buildAnalyticsSection(
                  context: context,
                  totalCount: totalCount,
                  percentCashCoins: percentCashCoins,
                  percentPoints: percentPoints,
                  mostUsedMethod: mostUsedMethod,
                  isDarkMode: _isDarkMode,
                  paymentMethods: paymentMethods,
                ),

                // Transactions header & "See All" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transactions",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: AllTransactionsPopup(isDarkMode: _isDarkMode),
                          ),
                        );
                      },
                      child: Text(
                        "See All",
                        style: TextStyle(
                          fontSize: 18,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Display all transactions (up to however many you want here)
                Column(
                  children: transactions.map(_buildTransactionCard).toList(),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
        currentIndex: 1, // Payments tab is active.
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          } else if (index == 1) {
            // Already on Payments.
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserScreen(isDarkMode: _isDarkMode),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryScreen(isDarkMode: _isDarkMode),
              ),
            );
          }
        },
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
    );
  }
}

class AllTransactionsPopup extends StatefulWidget {
  final bool isDarkMode;
  const AllTransactionsPopup({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  _AllTransactionsPopupState createState() => _AllTransactionsPopupState();
}

class _AllTransactionsPopupState extends State<AllTransactionsPopup> {
  late bool _isDarkMode;
  late Future<List<Map<String, dynamic>>> _futureTransactions;
  String _sortOption = 'Date Ascending';
  String _filterPaymentMethod = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _futureTransactions = DatabaseHelper().getTransactions();
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getProcessedTransactions() async {
    List<Map<String, dynamic>> txList =
    await DatabaseHelper().getTransactions();

    // Date range filter
    if (_selectedDateRange != null) {
      txList = txList.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? DateTime.now();
        return dt.isAfter(
            _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            dt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Payment method filter (Cash/Coins, Points)
    if (_filterPaymentMethod != 'All') {
      txList = txList
          .where((tx) => tx['payment_method'] == _filterPaymentMethod)
          .toList();
    }

    // Search query filter (medicine or transaction_id)
    if (_searchQuery.isNotEmpty) {
      txList = txList.where((tx) {
        final medicine = tx['medicine']?.toString().toLowerCase() ?? '';
        final txId = tx['transaction_id']?.toString().toLowerCase() ?? '';
        return medicine.contains(_searchQuery.toLowerCase()) ||
            txId.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Transaction amount filters
    double? minAmount = double.tryParse(_minAmountController.text);
    double? maxAmount = double.tryParse(_maxAmountController.text);
    if (minAmount != null) {
      txList = txList
          .where((tx) => (tx['total_amount'] as num).toDouble() >= minAmount)
          .toList();
    }
    if (maxAmount != null) {
      txList = txList
          .where((tx) => (tx['total_amount'] as num).toDouble() <= maxAmount)
          .toList();
    }

    // Sorting
    if (_sortOption == 'Date Ascending') {
      txList.sort((a, b) {
        DateTime da = DateTime.tryParse(a['date']) ?? DateTime.now();
        DateTime db = DateTime.tryParse(b['date']) ?? DateTime.now();
        return da.compareTo(db);
      });
    } else if (_sortOption == 'Date Descending') {
      txList.sort((a, b) {
        DateTime da = DateTime.tryParse(a['date']) ?? DateTime.now();
        DateTime db = DateTime.tryParse(b['date']) ?? DateTime.now();
        return db.compareTo(da);
      });
    } else if (_sortOption == 'Amount Ascending') {
      txList.sort((a, b) =>
          (a['total_amount'] as num).compareTo(b['total_amount'] as num));
    } else if (_sortOption == 'Amount Descending') {
      txList.sort((a, b) =>
          (b['total_amount'] as num).compareTo(a['total_amount'] as num));
    }

    return txList;
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    return ListTile(
      title: Text(
        tx['medicine'],
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        tx['date'],
        style: TextStyle(
          color: _isDarkMode ? Colors.white70 : Colors.grey,
        ),
      ),
      trailing: Text("₱${(tx['total_amount'] as num).toStringAsFixed(2)}"),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
            title: const Text("Transaction Details"),
            content: Text(
              "Medicine: ${tx['medicine']}\n"
                  "Quantity: ${tx['quantity']}\n"
                  "Unit Price: ${tx['unit_price']}\n"
                  "Total Amount: ${tx['total_amount']}\n"
                  "Date: ${tx['date']}\n"
                  "Payment Method: ${tx['payment_method']}\n"
                  "User Type: ${tx['user_type']}",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            style:
            TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Search by Medicine or ID',
              labelStyle: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 10),

          // Date range picker
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode ? Colors.grey[800] : null,
                ),
                onPressed: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _selectedDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: _isDarkMode
                            ? ThemeData.dark()
                            : ThemeData.light(),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDateRange = picked;
                    });
                  }
                },
                child: const Text("Select Date Range"),
              ),
              if (_selectedDateRange != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "${_selectedDateRange!.start.toLocal().toShortDateString()} - "
                        "${_selectedDateRange!.end.toLocal().toShortDateString()}",
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment method and sorting dropdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _filterPaymentMethod,
                dropdownColor:
                _isDarkMode ? Colors.grey[800] : Colors.white,
                items: <String>['All', 'Cash/Coins', 'Points']
                    .map(
                      (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filterPaymentMethod = value;
                    });
                  }
                },
              ),
              DropdownButton<String>(
                value: _sortOption,
                dropdownColor:
                _isDarkMode ? Colors.grey[800] : Colors.white,
                items: <String>[
                  'Date Ascending',
                  'Date Descending',
                  'Amount Ascending',
                  'Amount Descending'
                ]
                    .map(
                      (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color:
                        _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortOption = value;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Amount filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Min Amount',
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Max Amount',
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Apply filters button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? Colors.grey[800] : null,
            ),
            onPressed: () {
              setState(() {
                _futureTransactions = _getProcessedTransactions();
              });
            },
            child: const Text("Apply Filters"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("All Transactions"),
        backgroundColor:
        _isDarkMode ? Colors.grey[900] : const Color(0xFF0D2A5E),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Export/Print stub
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Export/Print feature not implemented"),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getProcessedTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No transactions available",
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }
                final txList = snapshot.data!;
                return ListView.builder(
                  itemCount: txList.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionTile(txList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension on DateTime for short date formatting.
extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return "${year.toString().padLeft(4, '0')}-"
        "${month.toString().padLeft(2, '0')}-"
        "${day.toString().padLeft(2, '0')}";
  }
}
