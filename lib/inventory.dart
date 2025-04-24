// inventory.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transaction.dart';
import 'user.dart';
import 'database_helper.dart';

// Branding gradient reused here
const LinearGradient _brandGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF0D2A5E),
    Color(0xFF1E5D6F),
  ],
);

class InventoryScreen extends StatefulWidget {
  final bool isDarkMode;
  const InventoryScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isDarkMode = false;
  int _selectedTabIndex = 3; // Inventory tab index

  // form controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdController   = TextEditingController();
  final TextEditingController _amountController      = TextEditingController();
  final TextEditingController _countController       = TextEditingController();
  final TextEditingController _searchController      = TextEditingController();

  List<Map<String, dynamic>> _stocks         = [];
  List<Map<String, dynamic>> _filteredStocks = [];
  List<Map<String, dynamic>> _batchExpiry    = [];
  List<Map<String, dynamic>> _filteredExpiry = [];

  int _inStockCount    = 0;
  int _warningCount    = 0;
  int _outOfStockCount = 0;
  int? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchStocksFromDB();
    _fetchBatchExpiryFromDB();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productIdController.dispose();
    _amountController.dispose();
    _countController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStocksFromDB() async {
    try {
      final stockList = await DatabaseHelper.instance.getAllStocks();
      final modifiable = stockList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      setState(() {
        _stocks = modifiable;
        _filteredStocks = List.from(modifiable);
      });
      _computeStockIndicators();
    } catch (e) {
      debugPrint("Error fetching stocks: $e");
    }
  }

  Future<void> _fetchBatchExpiryFromDB() async {
    try {
      final expiryList = await DatabaseHelper.instance.getAllBatchExpiry();
      setState(() {
        _batchExpiry = expiryList
            .map((row) => {
          "batchId": row["batch_id"]?.toString() ?? "",
          "expiration": row["expiration_date"] ?? "",
          "supplier": row["supplier"] ?? "",
          "dateReceived": row["date_received"] ?? "",
        })
            .toList();
        _filteredExpiry = List.from(_batchExpiry);
      });
    } catch (e) {
      debugPrint("Error fetching batch expiry: $e");
    }
  }

  String _computeStatusFromCount(int c) {
    if (c == 0) return "Out of stock";
    if (c <= 7) return "Warning";
    return "In Stock";
  }

  Future<void> _onSubmit() async {
    final totalRows = await DatabaseHelper.instance.getRowCount('stocks');
    if (totalRows >= 6) {
      _showCenterDialog(
        title: "Limit Reached",
        message: "You already have 6 medicines. Update existing ones instead.",
      );
      return;
    }
    final newCount = int.tryParse(_countController.text.trim()) ?? 0;
    if (newCount > 13) {
      _showCenterDialog(
        title: "Error",
        message: "Maximum allowed is 13 pieces.",
      );
      return;
    }
    final status = _computeStatusFromCount(newCount);
    await DatabaseHelper.instance.insertStock({
      "product_name": _productNameController.text,
      "product_id":   _productIdController.text,
      "amount":       _amountController.text,
      "status":       status,
      "count":        newCount.toString(),
    });
    await _fetchStocksFromDB();
    _clearManageInventoryFields();
  }

  Future<void> _onUpdate() async {
    if (_selectedBatchId == null) return;
    final newCount = int.tryParse(_countController.text.trim()) ?? 0;
    if (newCount > 13) {
      _showCenterDialog(
        title: "Error",
        message: "Maximum allowed is 13 pieces.",
      );
      return;
    }
    final status = _computeStatusFromCount(newCount);
    await DatabaseHelper.instance.updateStockByBatchId({
      "product_name": _productNameController.text,
      "product_id":   _productIdController.text,
      "amount":       _amountController.text,
      "status":       status,
      "count":        newCount.toString(),
    }, _selectedBatchId!);
    _showCenterDialog(
      title: "Success",
      message: "Stock updated successfully",
    );
    setState(() => _selectedBatchId = null);
    await _fetchStocksFromDB();
    _clearManageInventoryFields();
  }

  void _clearManageInventoryFields() {
    _productNameController.clear();
    _productIdController.clear();
    _amountController.clear();
    _countController.clear();
    setState(() => _selectedBatchId = null);
  }

  void _computeStockIndicators() {
    int inStock = 0, warn = 0, out = 0;
    for (var item in _stocks) {
      final cnt = int.tryParse((item["count"] ?? "0").toString()) ?? 0;
      final st = _computeStatusFromCount(cnt);
      item["status"] = st;
      if (st == "In Stock") inStock++;
      else if (st == "Warning") warn++;
      else out++;
    }
    setState(() {
      _inStockCount    = inStock;
      _warningCount    = warn;
      _outOfStockCount = out;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "in stock":
        return Colors.green;
      case "warning":
        return Colors.orange;
      case "out of stock":
        return Colors.red;
      default:
        return _isDarkMode ? Colors.white : Colors.black;
    }
  }

  void _searchItem(String q) {
    setState(() {
      _filteredStocks = _stocks.where((item) {
        final combined =
        "${item["product_id"]} ${item["product_name"]}".toLowerCase();
        return combined.contains(q.toLowerCase());
      }).toList();
      _filteredExpiry = _batchExpiry.where((batch) {
        final combined =
        "${batch["batchId"]} ${batch["supplier"]}".toLowerCase();
        return combined.contains(q.toLowerCase());
      }).toList();
    });
  }

  void _onTabSelected(int idx) {
    setState(() => _selectedTabIndex = idx);
    if (idx == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => DashboardScreen()));
    } else if (idx == 1) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TransactionScreen(isDarkMode: _isDarkMode)));
    } else if (idx == 2) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => UserScreen(isDarkMode: _isDarkMode)));
    }
    // idx == 3 -> stay here
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = widget.isDarkMode;
    return Container(
        decoration: const BoxDecoration(gradient: _brandGradient),
    child: Scaffold(
    extendBodyBehindAppBar: true,
    extendBody: true,           // ← lets the gradient show *behind* the nav bar
    backgroundColor: Colors.transparent,
    appBar: AppBar(
    automaticallyImplyLeading: false,
    title: const Text(
    "Inventory Dashboard",
    style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    backgroundColor: const Color(0xFF0D2A5E),
    ),
    bottomNavigationBar: BottomNavigationBar(
    backgroundColor: Colors.transparent,  // ← now truly transparent
    elevation: 0,
    currentIndex: _selectedTabIndex,
    onTap: _onTabSelected,
    selectedItemColor: Colors.blueAccent,
    unselectedItemColor: Colors.grey,
    iconSize: 28,
    selectedFontSize: 14,
    unselectedFontSize: 12,
    items: const [
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
    BottomNavigationBarItem(icon: Icon(Icons.payment),  label: "Payments"),
    BottomNavigationBarItem(icon: Icon(Icons.people),   label: "Users"),
    BottomNavigationBarItem(icon: Icon(Icons.inventory),label: "Inventory"),
    ],
    ),
      body: Container(
        decoration: const BoxDecoration(gradient: _brandGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MANAGE INVENTORY SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color:
                    _isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white54
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manage Inventory",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedBatchId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Batch ID: $_selectedBatchId",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      _buildTextField(
                          controller: _productNameController,
                          label: "Enter product name"),
                      const SizedBox(height: 10),
                      _buildTextField(
                          controller: _productIdController,
                          label: "Enter product ID"),
                      const SizedBox(height: 10),
                      _buildTextField(
                          controller: _amountController,
                          label: "Enter amount"),
                      const SizedBox(height: 10),
                      _buildTextField(
                          controller: _countController,
                          label: "Enter count"),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _selectedBatchId == null
                              ? _onSubmit
                              : _onUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2A5E),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_selectedBatchId == null
                              ? "Submit"
                              : "Update"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // STOCK INDICATORS
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStockIndicator(
                        count: _inStockCount,
                        label: "In stock",
                        color: Colors.green),
                    _buildStockIndicator(
                        count: _warningCount,
                        label: "Warning",
                        color: Colors.orange),
                    _buildStockIndicator(
                        count: _outOfStockCount,
                        label: "Out of stock",
                        color: Colors.red),
                  ],
                ),
                const SizedBox(height: 20),
                // SEARCH
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                            color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Search",
                          labelStyle: TextStyle(
                              color: Colors.white70),
                          border:
                          const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            _searchItem(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // MAIN INVENTORY TABLE
                SingleChildScrollView(
                  scrollDirection:
                  Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 56.0,
                    dataRowHeight: 56.0,
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle:
                    const TextStyle(color: Colors.white),
                    columns: [
                      DataColumn(
                          label: Text("Batch ID",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold))),
                      DataColumn(
                          label: Text("Product Name",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold))),
                      DataColumn(
                          label: Text("Product ID",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold))),
                      DataColumn(
                          label: Text("Count",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold))),
                      DataColumn(
                          label: Center(
                              child: Text("Status",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))),
                      DataColumn(
                          label: Text("Amount",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold))),
                    ],
                    rows: _filteredStocks.map((item) {
                      final batchIdStr = item["BATCH_ID"]?.toString() ??
                          item["batch_id"]?.toString() ??
                          "";
                      final productNameStr = item["product_name"]
                          ?.toString() ??
                          "";
                      final productIdStr =
                          item["product_id"]?.toString() ?? "";
                      final countStr =
                          item["count"]?.toString() ?? "0";
                      final statusStr =
                          item["status"]?.toString() ??
                              "Out of stock";
                      final amountStr =
                          item["amount"]?.toString() ?? "0";
                      final batchIdInt =
                      int.tryParse(batchIdStr);

                      return DataRow(
                        selected:
                        _selectedBatchId ==
                            batchIdInt,
                        onSelectChanged:
                            (selected) {
                          if (selected ==
                              true) {
                            setState(() {
                              _selectedBatchId =
                                  batchIdInt;
                              _productNameController
                                  .text =
                                  productNameStr;
                              _productIdController
                                  .text =
                                  productIdStr;
                              _countController
                                  .text =
                                  countStr;
                              _amountController
                                  .text =
                                  amountStr;
                            });
                          } else {
                            setState(() {
                              _selectedBatchId =
                              null;
                              _clearManageInventoryFields();
                            });
                          }
                        },
                        cells: [
                          DataCell(Text(batchIdStr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color:
                                  Colors.white))),
                          DataCell(Text(
                              productNameStr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color:
                                  Colors.white))),
                          DataCell(Text(
                              productIdStr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color:
                                  Colors.white))),
                          DataCell(Text(countStr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color:
                                  Colors.white))),
                          DataCell(
                            Center(
                              child: Text(statusStr,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold,
                                      color:
                                      _getStatusColor(statusStr))),
                            ),
                          ),
                          DataCell(Text(amountStr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color:
                                  Colors.white))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // REFRESH BUTTON
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      _searchController.clear();
                      await _fetchStocksFromDB();
                      await _fetchBatchExpiryFromDB();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Refresh"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // Helper for building text fields
  Widget _buildTextField(
      {required TextEditingController controller,
        required String label}) {
    return TextField(
      controller: controller,
      style:
      TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color:
            _isDarkMode ? Colors.white70 : Colors.black54),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Helper for the colored stock indicator boxes
  Widget _buildStockIndicator({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        // gradient from a stronger tint to a weaker one
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to show a centered dialog with a title and message.
  /// Text styles have been enlarged for readability.
  void _showCenterDialog(
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
