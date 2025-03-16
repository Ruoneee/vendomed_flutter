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

  // "Manage Inventory" form fields (for 5 columns; BATCH_ID is auto)
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  // For searching inventory
  final TextEditingController _searchController = TextEditingController();

  // Inventory data loaded from DB
  List<Map<String, dynamic>> _stocks = [];
  // Filtered list for the Main Inventory table
  List<Map<String, dynamic>> _filteredStocks = [];

  // Placeholder Batch Expiry data (replace with real DB if needed)
  final List<Map<String, dynamic>> _batchExpiryItems = [
    {
      "batchId": "B-001",
      "expiration": "2025-07-20",
      "supplier": "Supplier A",
      "dateReceived": "2024-06-25",
    },
    {
      "batchId": "B-002",
      "expiration": "2025-10-30",
      "supplier": "Supplier B",
      "dateReceived": "2024-07-10",
    },
  ];
  // Filtered list for the Batch Expiry table
  List<Map<String, dynamic>> _filteredExpiry = [];

  // Stock counters
  int _inStockCount = 0;
  int _warningCount = 0;
  int _outOfStockCount = 0;

  // Track the selected row's Batch ID for updating.
  // This value will be shown in the Manage Inventory section.
  int? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchStocksFromDB();
    _filteredExpiry = List.from(_batchExpiryItems);
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

  // Fetch inventory data from the 'stocks' table and update counters
  Future<void> _fetchStocksFromDB() async {
    try {
      final stockList = await DatabaseHelper.instance.getAllStocks();
      setState(() {
        _stocks = stockList;
        _filteredStocks = List.from(stockList);
      });
      debugPrint("Fetched ${stockList.length} items from 'stocks' table");
      _computeStockIndicators();
    } catch (e) {
      debugPrint("Error fetching stocks from DB: $e");
    }
  }

  // Insert a new row into 'stocks'
  Future<void> _onSubmit() async {
    final newItem = {
      "product_name": _productNameController.text,
      "product_id": _productIdController.text,
      "amount": _amountController.text,
      "status": _statusController.text,
      "count": _countController.text,
    };

    try {
      await DatabaseHelper.instance.insertStock(newItem);
      await _fetchStocksFromDB();
      _clearManageInventoryFields();
    } catch (e) {
      debugPrint("Error inserting stock: $e");
    }
  }

  // Update the selected stock record using its Batch ID.
  Future<void> _onUpdate() async {
    if (_selectedBatchId == null) return;
    final updatedItem = {
      "product_name": _productNameController.text,
      "product_id": _productIdController.text,
      "amount": _amountController.text,
      "status": _statusController.text,
      "count": _countController.text,
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

  // Clear the Manage Inventory form fields and deselect the record.
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

  // Compute stock indicators based on the "status" column.
  void _computeStockIndicators() {
    int inStock = 0;
    int warning = 0;
    int outOfStock = 0;

    for (var item in _stocks) {
      final statusStr = (item["status"] ?? "").toString().toLowerCase();
      if (statusStr == "in stock") {
        inStock++;
      } else if (statusStr == "warning") {
        warning++;
      } else if (statusStr == "out of stock") {
        outOfStock++;
      }
    }
    setState(() {
      _inStockCount = inStock;
      _warningCount = warning;
      _outOfStockCount = outOfStock;
    });
  }

  // Return a color based on the status.
  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == "in stock") return Colors.green;
    if (lower == "warning") return Colors.orange;
    if (lower == "out of stock") return Colors.red;
    return _isDarkMode ? Colors.white : Colors.black;
  }

  // Search in 'stocks' by product_id or product_name, also filter placeholder expiry by batchId.
  void _searchItem(String query) {
    setState(() {
      _filteredStocks = _stocks.where((item) {
        final productId = (item["product_id"] ?? "").toString().toLowerCase();
        final productName = (item["product_name"] ?? "").toString().toLowerCase();
        final combined = "$productId $productName";
        return combined.contains(query.toLowerCase());
      }).toList();

      _filteredExpiry = _batchExpiryItems.where((batch) {
        final combined = "${batch['batchId']}".toLowerCase();
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Bottom navigation logic.
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
    } else if (index == 3) {
      // Remain on Inventory
    }
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
                    // Display the selected Batch ID if one is selected.
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
              // STOCK INDICATORS (Larger boxes)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStockIndicator(count: _inStockCount, label: "In stock", color: Colors.green),
                  _buildStockIndicator(count: _warningCount, label: "Warning", color: Colors.orange),
                  _buildStockIndicator(count: _outOfStockCount, label: "Out of stock", color: Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              // SEARCH + ADD NEW PRODUCT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Add new product clicked")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Add new product"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // MAIN INVENTORY TABLE (Larger)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  dataRowHeight: 56.0,
                  headingRowHeight: 56.0,
                  columns: [
                    DataColumn(
                      label: Text(
                        "Batch ID",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Product Name",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Product ID",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Amount",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text(
                            "Status",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Count",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _filteredStocks.map((item) {
                    // Try to get Batch ID with either uppercase or lowercase key.
                    final batchIdStr = item["BATCH_ID"]?.toString() ?? item["batch_id"]?.toString() ?? "";
                    final productNameStr = item["product_name"]?.toString() ?? "";
                    final productIdStr = item["product_id"]?.toString() ?? "";
                    final amountStr = item["amount"]?.toString() ?? "0";
                    final statusStr = item["status"]?.toString() ?? "Out of stock";
                    final countStr = item["count"]?.toString() ?? "0";
                    final batchIdInt = int.tryParse(batchIdStr);
                    return DataRow(
                      selected: _selectedBatchId == batchIdInt,
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          setState(() {
                            _selectedBatchId = batchIdInt;
                            _productNameController.text = productNameStr;
                            _productIdController.text = productIdStr;
                            _amountController.text = amountStr;
                            _statusController.text = statusStr;
                            _countController.text = countStr;
                          });
                        } else {
                          setState(() {
                            _selectedBatchId = null;
                            _clearManageInventoryFields();
                          });
                        }
                      },
                      cells: [
                        DataCell(Text(batchIdStr, style: const TextStyle(fontSize: 16))),
                        DataCell(Text(productNameStr, style: const TextStyle(fontSize: 16))),
                        DataCell(Text(productIdStr, style: const TextStyle(fontSize: 16))),
                        DataCell(Text(amountStr, style: const TextStyle(fontSize: 16))),
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
                        DataCell(Text(countStr, style: const TextStyle(fontSize: 16))),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // BATCH EXPIRY MANAGEMENT TABLE (Even Larger)
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
                      label: Text(
                        "Batch ID",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Expiration",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Supplier",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Date Received",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
              // REFRESH BUTTON (Larger style)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    _searchController.clear();
                    await _fetchStocksFromDB();
                    setState(() {
                      _filteredExpiry = List.from(_batchExpiryItems);
                    });
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

  // Helper for building text fields.
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

  // Helper for the colored stock indicator boxes (Larger version)
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
