import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transaction.dart';
import 'user.dart';
import 'database_helper.dart';

class InventoryScreen extends StatefulWidget {
  final bool isDarkMode;
  const InventoryScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isDarkMode = false;
  int _selectedTabIndex = 3; // Inventory tab index

  // "Manage Inventory" form fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  // For searching inventory
  final TextEditingController _searchController = TextEditingController();

  // Inventory data loaded from DB
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _filteredStocks = [];

  // Batch expiry data loaded from DB
  List<Map<String, dynamic>> _batchExpiry = [];
  List<Map<String, dynamic>> _filteredExpiry = [];

  // Stock counters
  int _inStockCount = 0;
  int _warningCount = 0;
  int _outOfStockCount = 0;

  // Track the selected row's Batch ID for updating
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
    _statusController.dispose();
    _countController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 1) Fetch inventory data from 'stocks'
  Future<void> _fetchStocksFromDB() async {
    try {
      final stockList = await DatabaseHelper.instance.getAllStocks();
      // Convert each map to a modifiable map so we can override status
      final modifiableStockList = stockList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      setState(() {
        _stocks = modifiableStockList;
        _filteredStocks = List.from(modifiableStockList);
      });
      debugPrint("Fetched ${modifiableStockList.length} items from 'stocks' table");
      _computeStockIndicators();
    } catch (e) {
      debugPrint("Error fetching stocks from DB: $e");
    }
  }

  // 2) Fetch batch expiry data
  Future<void> _fetchBatchExpiryFromDB() async {
    try {
      final expiryList = await DatabaseHelper.instance.getAllBatchExpiry();
      setState(() {
        _batchExpiry = expiryList.map((row) {
          return {
            "batchId": row["batch_id"]?.toString() ?? "",
            "expiration": row["expiration_date"] ?? "",
            "supplier": row["supplier"] ?? "",
            "dateReceived": row["date_received"] ?? "",
          };
        }).toList();
        _filteredExpiry = List.from(_batchExpiry);
      });
      debugPrint("Fetched ${expiryList.length} items from 'batch_expiry' table");
    } catch (e) {
      debugPrint("Error fetching batch expiry from DB: $e");
    }
  }

  // 3) Insert a new row into 'stocks'
  Future<void> _onSubmit() async {
    final newCountStr = _countController.text.trim();
    final newCountVal = int.tryParse(newCountStr) ?? 0;
    if (newCountVal > 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum allowed is 13 pieces.")),
      );
      return;
    }

    final newItem = {
      "product_name": _productNameController.text,
      "product_id": _productIdController.text,
      "amount": _amountController.text,
      "status": _statusController.text,
      "count": newCountStr,
    };

    try {
      await DatabaseHelper.instance.insertStock(newItem);
      await _fetchStocksFromDB();
      _clearManageInventoryFields();
    } catch (e) {
      debugPrint("Error inserting stock: $e");
    }
  }

  // 4) Update the selected stock record
  Future<void> _onUpdate() async {
    if (_selectedBatchId == null) return;

    final newCountStr = _countController.text.trim();
    final newCountVal = int.tryParse(newCountStr) ?? 0;
    if (newCountVal > 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum allowed is 13 pieces.")),
      );
      return;
    }

    final updatedItem = {
      "product_name": _productNameController.text,
      "product_id": _productIdController.text,
      "amount": _amountController.text,
      "status": _statusController.text,
      "count": newCountStr,
    };

    try {
      await DatabaseHelper.instance.updateStockByBatchId(updatedItem, _selectedBatchId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stock updated successfully")),
      );
      setState(() {
        _selectedBatchId = null;
      });
      await _fetchStocksFromDB();
      _clearManageInventoryFields();
    } catch (e) {
      debugPrint("Error updating stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating stock: $e")),
      );
    }
  }

  // 5) Clear the Manage Inventory form fields
  void _clearManageInventoryFields() {
    _productNameController.clear();
    _productIdController.clear();
    _amountController.clear();
    _statusController.clear();
    _countController.clear();
    setState(() {
      _selectedBatchId = null;
    });
  }

  // 6) Compute stock indicators from 'count'
  void _computeStockIndicators() {
    int inStock = 0;
    int warning = 0;
    int outOfStock = 0;

    for (var item in _stocks) {
      final countStr = (item["count"] ?? "0").toString().trim();
      final countVal = int.tryParse(countStr) ?? 0;
      String computedStatus;
      if (countVal == 0) {
        computedStatus = "Out of stock";
        outOfStock++;
      } else if (countVal <= 7) {
        computedStatus = "Warning";
        warning++;
      } else {
        computedStatus = "In Stock";
        inStock++;
      }
      item["status"] = computedStatus;
    }

    setState(() {
      _inStockCount = inStock;
      _warningCount = warning;
      _outOfStockCount = outOfStock;
    });
  }

  // 7) Return a color based on the computed status
  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == "in stock") return Colors.green;
    if (lower == "warning") return Colors.orange;
    if (lower == "out of stock") return Colors.red;
    return _isDarkMode ? Colors.white : Colors.black;
  }

  // 8) Search in 'stocks' and 'batch_expiry'
  void _searchItem(String query) {
    setState(() {
      _filteredStocks = _stocks.where((item) {
        final productId = (item["product_id"] ?? "").toString().toLowerCase();
        final productName = (item["product_name"] ?? "").toString().toLowerCase();
        final combined = "$productId $productName";
        return combined.contains(query.toLowerCase());
      }).toList();

      _filteredExpiry = _batchExpiry.where((batch) {
        final batchId = batch["batchId"].toString().toLowerCase();
        final supplier = batch["supplier"].toString().toLowerCase();
        final combined = "$batchId $supplier";
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  // 9) Bottom navigation
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TransactionScreen(isDarkMode: _isDarkMode)));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserScreen(isDarkMode: _isDarkMode)));
    }
    // index == 3 => remain on Inventory
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Inventory Dashboard",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2A5E),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MANAGE INVENTORY SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white54 : Colors.grey.shade300,
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
                        color: _isDarkMode ? Colors.white : Colors.black,
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
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    _buildTextField(controller: _productNameController, label: "Enter product name"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _productIdController, label: "Enter product ID"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _amountController, label: "Enter amount"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _statusController, label: "Enter status (In Stock, Warning, Out of stock)"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _countController, label: "Enter count"),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _selectedBatchId == null ? _onSubmit : _onUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2A5E),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_selectedBatchId == null ? "Submit" : "Update"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // STOCK INDICATORS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStockIndicator(count: _inStockCount, label: "In stock", color: Colors.green),
                  _buildStockIndicator(count: _warningCount, label: "Warning", color: Colors.orange),
                  _buildStockIndicator(count: _outOfStockCount, label: "Out of stock", color: Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // SEARCH
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: "Search",
                        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) => _searchItem(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // MAIN INVENTORY TABLE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  dataRowHeight: 56.0,
                  headingRowHeight: 56.0,
                  columns: [
                    // 1. Batch ID
                    DataColumn(
                      label: Text("Batch ID", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    // 2. Product Name
                    DataColumn(
                      label: Text("Product Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    // 3. Product ID
                    DataColumn(
                      label: Text("Product ID", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    // 4. Count
                    DataColumn(
                      label: Text("Count", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    // 5. Status
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text("Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    // 6. Amount (moved to last column)
                    DataColumn(
                      label: Text("Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: _filteredStocks.map((item) {
                    final batchIdStr = item["BATCH_ID"]?.toString() ?? item["batch_id"]?.toString() ?? "";
                    final productNameStr = item["product_name"]?.toString() ?? "";
                    final productIdStr = item["product_id"]?.toString() ?? "";
                    final countStr = item["count"]?.toString() ?? "0";
                    final statusStr = item["status"]?.toString() ?? "Out of stock";
                    final amountStr = item["amount"]?.toString() ?? "0";

                    final batchIdInt = int.tryParse(batchIdStr);

                    return DataRow(
                      selected: _selectedBatchId == batchIdInt,
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          setState(() {
                            _selectedBatchId = batchIdInt;
                            _productNameController.text = productNameStr;
                            _productIdController.text = productIdStr;
                            _countController.text = countStr;
                            _statusController.text = statusStr;
                            _amountController.text = amountStr;
                          });
                        } else {
                          setState(() {
                            _selectedBatchId = null;
                            _clearManageInventoryFields();
                          });
                        }
                      },
                      cells: [
                        // 1. Batch ID
                        DataCell(Text(batchIdStr, style: const TextStyle(fontSize: 16))),
                        // 2. Product Name
                        DataCell(Text(productNameStr, style: const TextStyle(fontSize: 16))),
                        // 3. Product ID
                        DataCell(Text(productIdStr, style: const TextStyle(fontSize: 16))),
                        // 4. Count
                        DataCell(Text(countStr, style: const TextStyle(fontSize: 16))),
                        // 5. Status
                        DataCell(
                          Center(
                            child: Text(
                              statusStr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(statusStr),
                              ),
                            ),
                          ),
                        ),
                        // 6. Amount (last column)
                        DataCell(Text(amountStr, style: const TextStyle(fontSize: 16))),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // BATCH EXPIRY MANAGEMENT TABLE
              Text(
                "Batch Expiry Management",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowHeight: 64.0,
                  headingRowHeight: 64.0,
                  columns: [
                    DataColumn(
                      label: Text("Batch ID", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text("Expiration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text("Supplier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text("Date Received", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: _filteredExpiry.map((batch) {
                    return DataRow(cells: [
                      DataCell(Text(batch["batchId"] ?? "", style: const TextStyle(fontSize: 16))),
                      DataCell(Text(batch["expiration"] ?? "", style: const TextStyle(fontSize: 16))),
                      DataCell(Text(batch["supplier"] ?? "", style: const TextStyle(fontSize: 16))),
                      DataCell(Text(batch["dateReceived"] ?? "", style: const TextStyle(fontSize: 16))),
                    ]);
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
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text("Refresh"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for building text fields
  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Helper for the colored stock indicator boxes
  Widget _buildStockIndicator({required int count, required String label, required Color color}) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
}
