import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dashboard.dart';
import 'database_helper.dart';

// Model for payment methods in the pie chart.
class PaymentMethodData {
  final String method;
  final double percentage;
  PaymentMethodData(this.method, this.percentage);
}

// Model for individual transactions.
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
  TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  Timer? _timer;
  late Future<List<TransactionItem>> _futureTransactions;

  @override
  void initState() {
    super.initState();
    _futureTransactions = _fetchTransactions();
    // Refresh transactions every minute.
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.medication, color: Colors.white70, size: 32),
        ),
        title: Text(
          tx.medicine,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          tx.date,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
        const Text('Transactions', style: TextStyle(color: Colors.white, fontSize: 28)),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      body: FutureBuilder<List<TransactionItem>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions available'));
          }
          final transactions = snapshot.data!;
          final totalCount = transactions.length;
          int cashCoinsCount =
              transactions.where((tx) => tx.paymentMethod == 'Cash/Coins').length;
          int gCashCount = transactions.where((tx) => tx.paymentMethod == 'GCash').length;
          double percentCashCoins =
          totalCount > 0 ? (cashCoinsCount / totalCount * 100) : 0;
          double percentGCash =
          totalCount > 0 ? (gCashCount / totalCount * 100) : 0;
          String mostUsedMethod =
          cashCoinsCount >= gCashCount ? "Cash/Coins" : "GCash";

          final List<PaymentMethodData> paymentMethods = [
            PaymentMethodData("Cash/Coins", percentCashCoins),
            PaymentMethodData("GCash", percentGCash),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Analytics",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 600,
                  child: SfCircularChart(
                    legend: Legend(
                      isVisible: true,
                      overflowMode: LegendItemOverflowMode.wrap,
                      position: LegendPosition.bottom,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    series: <CircularSeries>[
                      PieSeries<PaymentMethodData, String>(
                        dataSource: paymentMethods,
                        xValueMapper: (PaymentMethodData data, _) => data.method,
                        yValueMapper: (PaymentMethodData data, _) => data.percentage,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Transactions",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$totalCount",
                          style:
                          const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Most Used Method",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
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
                              style:
                              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Transactions",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    // "See All" button launches the pop-up screen.
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: AllTransactionsPopup(),
                          ),
                        );
                      },
                      child: const Text(
                        "See All",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children:
                  transactions.map((tx) => _buildTransactionCard(tx)).toList(),
                ),
              ],
            ),
          );
        },
      ),
      // Bottom Navigation Bar for TransactionScreen.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Always show Payments as active.
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          }
          // For index 1 (Payments) do nothing.
          // Extend for additional tabs if needed.
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        iconSize: 36,
        selectedFontSize: 18,
        unselectedFontSize: 16,
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

/// --- AllTransactionsPopup ---
/// This pop-up integrates:
/// • Advanced Filtering & Sorting (date range, payment method, medicine name, transaction amount, sorting options)
/// • Search functionality (by medicine name or transaction ID)
/// • Detailed Transaction View (tapping a transaction shows a detailed breakdown in a dialog)
class AllTransactionsPopup extends StatefulWidget {
  const AllTransactionsPopup({Key? key}) : super(key: key);

  @override
  _AllTransactionsPopupState createState() => _AllTransactionsPopupState();
}

class _AllTransactionsPopupState extends State<AllTransactionsPopup> {
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

    // Apply date range filter.
    if (_selectedDateRange != null) {
      txList = txList.where((tx) {
        DateTime dt = DateTime.tryParse(tx['date']) ?? DateTime.now();
        return dt.isAfter(_selectedDateRange!.start.subtract(Duration(days: 1))) &&
            dt.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Apply payment method filter.
    if (_filterPaymentMethod != 'All') {
      txList = txList.where((tx) => tx['payment_method'] == _filterPaymentMethod).toList();
    }

    // Apply search query (medicine name or transaction ID).
    if (_searchQuery.isNotEmpty) {
      txList = txList.where((tx) {
        final medicine = tx['medicine']?.toString().toLowerCase() ?? '';
        final txId = tx['transaction_id']?.toString().toLowerCase() ?? '';
        return medicine.contains(_searchQuery.toLowerCase()) ||
            txId.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply transaction amount filters.
    double? minAmount = double.tryParse(_minAmountController.text);
    double? maxAmount = double.tryParse(_maxAmountController.text);
    if (minAmount != null) {
      txList = txList.where((tx) => (tx['total_amount'] as num).toDouble() >= minAmount).toList();
    }
    if (maxAmount != null) {
      txList = txList.where((tx) => (tx['total_amount'] as num).toDouble() <= maxAmount).toList();
    }

    // Apply sorting.
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

  // Build a ListTile for each transaction.
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    return ListTile(
      title: Text(tx['medicine']),
      subtitle: Text(tx['date']),
      trailing: Text("₱${(tx['total_amount'] as num).toStringAsFixed(2)}"),
      onTap: () {
        // Show detailed info in a dialog.
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Transaction Details"),
            content: Text(
              "Medicine: ${tx['medicine']}\n"
                  "Quantity: ${tx['quantity']}\n"
                  "Unit Price: ${tx['unit_price']}\n"
                  "Total Amount: ${tx['total_amount']}\n"
                  "Date: ${tx['date']}\n"
                  "Payment Method: ${tx['payment_method']}\n"
                  "User Type: ${tx['user_type']}",
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

  // Build the filter section with search, date range, payment method, amount filters, and sorting.
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search bar.
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by Medicine or ID',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 10),
          // Date range picker.
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _selectedDateRange,
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
                    "${_selectedDateRange!.start.toLocal().toShortDateString()} - ${_selectedDateRange!.end.toLocal().toShortDateString()}",
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Payment method and sorting dropdowns.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _filterPaymentMethod,
                items: <String>['All', 'Cash/Coins', 'GCash']
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
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
                items: <String>[
                  'Date Ascending',
                  'Date Descending',
                  'Amount Ascending',
                  'Amount Descending'
                ]
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
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
          // Amount filter: min and max.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Amount',
                    border: OutlineInputBorder(),
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
                  decoration: InputDecoration(
                    labelText: 'Max Amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Button to apply filters.
          ElevatedButton(
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
      appBar: AppBar(
        title: const Text("All Transactions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Export/Print functionality stub.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export/Print feature not implemented")),
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
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No transactions available"));
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

// Extension for DateTime formatting.
extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return "${this.year}-${this.month.toString().padLeft(2, '0')}-${this.day.toString().padLeft(2, '0')}";
  }
}
