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

/// Model for individual transactions (monogram approach, no images).
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

  // Filtering state
  String _sortOption = 'Date Ascending';
  String _filterPaymentMethod = 'All';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Replace with your actual brand color in light mode.
  // This example uses the same blue as your app bar: 0xFF0D2A5E
  final Color brandColorLight = const Color(0xFF0D2A5E);

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _futureTransactions = _fetchAndFilterTransactions();

    // Periodically refresh the transactions every minute.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _futureTransactions = _fetchAndFilterTransactions();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch transactions from the database, convert to TransactionItem,
  /// then apply all active filters.
  Future<List<TransactionItem>> _fetchAndFilterTransactions() async {
    final rawData = await DatabaseHelper().getTransactions();
    List<TransactionItem> list = rawData.map((row) {
      return TransactionItem(
        medicine: row['medicine'],
        date: row['date'],
        totalAmount: row['total_amount'] is int
            ? (row['total_amount'] as int).toDouble()
            : row['total_amount'],
        paymentMethod: row['payment_method'],
      );
    }).toList();

    // Date range filter
    if (_selectedDateRange != null) {
      list = list.where((tx) {
        DateTime dt = DateTime.tryParse(tx.date) ?? DateTime.now();
        return dt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            dt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Payment method filter
    if (_filterPaymentMethod != 'All') {
      list = list.where((tx) => tx.paymentMethod == _filterPaymentMethod).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((tx) => tx.medicine.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Amount filters
    double? minAmount = double.tryParse(_minAmountController.text);
    double? maxAmount = double.tryParse(_maxAmountController.text);
    if (minAmount != null) {
      list = list.where((tx) => tx.totalAmount >= minAmount).toList();
    }
    if (maxAmount != null) {
      list = list.where((tx) => tx.totalAmount <= maxAmount).toList();
    }

    // Sorting
    if (_sortOption == 'Date Ascending') {
      list.sort((a, b) {
        DateTime da = DateTime.tryParse(a.date) ?? DateTime.now();
        DateTime db = DateTime.tryParse(b.date) ?? DateTime.now();
        return da.compareTo(db);
      });
    } else if (_sortOption == 'Date Descending') {
      list.sort((a, b) {
        DateTime da = DateTime.tryParse(a.date) ?? DateTime.now();
        DateTime db = DateTime.tryParse(b.date) ?? DateTime.now();
        return db.compareTo(da);
      });
    } else if (_sortOption == 'Amount Ascending') {
      list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
    } else if (_sortOption == 'Amount Descending') {
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }

    return list;
  }

  /// Builds a card for a single transaction using a monogram approach.
  Widget _buildTransactionCard(TransactionItem tx) {
    // Get the first letter of the medicine name.
    String initials = tx.medicine.isNotEmpty
        ? tx.medicine[0].toUpperCase()
        : '?';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: _isDarkMode ? Colors.grey[850] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[100],
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          tx.medicine,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Date: ${tx.date}",
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
            Text(
              "Payment: ${tx.paymentMethod}",
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
        trailing: Text(
          "₱${tx.totalAmount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 18,
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
    return Container(
      width: double.infinity,
      height: 350, // Increase as needed for better readability
      child: SfCircularChart(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        legend: Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
          position: LegendPosition.bottom,
          textStyle: TextStyle(
            fontSize: 14,
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
                  return const Color(0xFF0D2A5E);
                case 'Points':
                  return const Color(0xFF546E94);
                default:
                  return Colors.grey;
              }
            },
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats section with brand color card, icons, and chip for the most used method.
  Widget _buildStats(
      BuildContext context,
      int totalCount,
      String mostUsedMethod,
      bool isDarkMode,
      ) {
    // Pick a color for the chip based on the method:
    Color methodColor = mostUsedMethod == "Cash/Coins"
        ? Colors.green[300]!
        : Colors.blue[300]!;

    return Card(
      // Use brand color in light mode, dark gray in dark mode
      color: isDarkMode ? Colors.grey[850] : brandColorLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Transactions Row
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: isDarkMode ? Colors.white70 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  "Total Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // The count in large bold text
            Text(
              "$totalCount",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for contrast
              ),
            ),
            const Divider(height: 20, color: Colors.white70),
            // Most Used Method Row
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: isDarkMode ? Colors.white70 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  "Most Used Method",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Colored chip for the method
            Chip(
              label: Text(
                mostUsedMethod,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: methodColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a bottom sheet containing the advanced filters.
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            // Add bottom padding to account for the keyboard or safe area
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Advanced Filters",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
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
                              data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
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
                    const SizedBox(width: 8),
                    if (_selectedDateRange != null)
                      Expanded(
                        child: Text(
                          "${_selectedDateRange!.start.toLocal().toShortDateString()} - "
                              "${_selectedDateRange!.end.toLocal().toShortDateString()}",
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment method dropdown
                DropdownButtonFormField<String>(
                  value: _filterPaymentMethod,
                  dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 16),
                // Sort option dropdown
                DropdownButtonFormField<String>(
                  value: _sortOption,
                  dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                  decoration: InputDecoration(
                    labelText: "Sort By",
                    labelStyle: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                  ),
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
                          color: _isDarkMode ? Colors.white : Colors.black,
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
                const SizedBox(height: 16),
                // Min/Max amount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Apply Filters
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode ? Colors.grey[700] : null,
                  ),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context); // Close bottom sheet
                      _futureTransactions = _fetchAndFilterTransactions();
                    });
                  },
                  child: const Text("Apply Filters"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the row that contains the search bar and the filter button.
  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        // Search TextField
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search by Medicine',
              hintStyle: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              filled: true,
              fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
              prefixIcon: Icon(
                Icons.search,
                color: _isDarkMode ? Colors.white : Colors.black54,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _futureTransactions = _fetchAndFilterTransactions();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        // Filter Button
        ElevatedButton.icon(
          onPressed: _showFilterBottomSheet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? Colors.grey[800] : brandColorLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Make the text/icon color white:
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.filter_list),
          label: const Text(
            "Filter",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
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
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[900] : brandColorLight,
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildSearchAndFilterRow(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        'No transactions available',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;
          final totalCount = transactions.length;

          // Payment method calculations.
          int cashCoinsCount = transactions
              .where((tx) => tx.paymentMethod == 'Cash/Coins')
              .length;
          int pointsCount =
              transactions.where((tx) => tx.paymentMethod == 'Points').length;

          double percentCashCoins =
          totalCount > 0 ? (cashCoinsCount / totalCount * 100) : 0;
          double percentPoints =
          totalCount > 0 ? (pointsCount / totalCount * 100) : 0;

          String mostUsedMethod =
          (cashCoinsCount >= pointsCount) ? "Cash/Coins" : "Points";

          final List<PaymentMethodData> paymentMethods = [
            PaymentMethodData("Cash/Coins", percentCashCoins),
            PaymentMethodData("Points", percentPoints),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              // Decide if we display chart & stats side by side (wide screen)
              // or stacked (narrow screen).
              bool isWideScreen = constraints.maxWidth > 600;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // Search & Filter Row
                    _buildSearchAndFilterRow(),
                    const SizedBox(height: 16),

                    // Analytics (Pie chart & Stats)
                    if (isWideScreen)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: _isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildPieChart(
                                  context,
                                  paymentMethods,
                                  _isDarkMode,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Stats
                          Expanded(
                            flex: 1,
                            child: _buildStats(
                              context,
                              totalCount,
                              mostUsedMethod,
                              _isDarkMode,
                            ),
                          ),
                        ],
                      )
                    else
                    // Narrow screen: stack them
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: _isDarkMode
                                ? Colors.grey[900]
                                : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildPieChart(
                                context,
                                paymentMethods,
                                _isDarkMode,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStats(
                            context,
                            totalCount,
                            mostUsedMethod,
                            _isDarkMode,
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Transactions Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Transactions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction List
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(transactions[index]);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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

/// Extension on DateTime for short date formatting.
extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return "${year.toString().padLeft(4, '0')}-"
        "${month.toString().padLeft(2, '0')}-"
        "${day.toString().padLeft(2, '0')}";
  }
}
