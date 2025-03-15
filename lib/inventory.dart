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
  int _selectedTabIndex = 3; // Inventory tab

  // "Manage Inventory" form fields
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // For searching
  final TextEditingController _searchController = TextEditingController();

  // Data from DB (stocks table)
  List<Map<String, dynamic>> _stocks = [];
  // Filtered list for the "Main Inventory" table
  List<Map<String, dynamic>> _filteredStocks = [];

  // Placeholder "Batch Expiry" table (replace with real DB if available)
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
  // Filtered list for the second table
  List<Map<String, dynamic>> _filteredExpiry = [];

  // Counters for the colored indicators
  int _inStockCount = 0;
  int _warningCount = 0;
  int _outOfStockCount = 0;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchStocksFromDB();
    _filteredExpiry = List.from(_batchExpiryItems);
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch all rows from 'stocks' table, then compute indicators
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
  // Mapping:
  //   "PRODUCT ID" => _productIdController.text
  //   "COUNT"      => _quantityController.text
  //   "AMOUNT"     => _amountController.text
  //   "PRODUCT NAME" is set to "Placeholder" (adjust if needed)
  //   "STATUS" is set to "In Stock" if COUNT>0, else "Out of stock"
  Future<void> _onSubmit() async {
    final countVal = int.tryParse(_quantityController.text) ?? 0;
    final initialStatus = (countVal > 0) ? "In Stock" : "Out of stock";

    final newItem = {
      "PRODUCT ID": _productIdController.text,
      "COUNT": _quantityController.text,
      "AMOUNT": _amountController.text,
      "PRODUCT NAME": "Placeholder", // Adjust if you want a dedicated field
      "STATUS": initialStatus,
    };

    try {
      await DatabaseHelper.instance.insertStock(newItem);
      await _fetchStocksFromDB();
      // Clear fields
      _productIdController.clear();
      _quantityController.clear();
      _amountController.clear();
    } catch (e) {
      debugPrint("Error inserting stock: $e");
    }
  }

  // Compute stock indicators based on the "STATUS" column
  void _computeStockIndicators() {
    int inStock = 0;
    int warning = 0;
    int outOfStock = 0;

    for (var item in _stocks) {
      final statusStr = (item["STATUS"] ?? "").toString().toLowerCase();
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

  // Return a color based on the status text
  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == "in stock") return Colors.green;
    if (lower == "warning") return Colors.orange;
    if (lower == "out of stock") return Colors.red;
    return _isDarkMode ? Colors.white : Colors.black;
  }

  // Search by "PRODUCT ID" or "PRODUCT NAME" in stocks and by batchId in expiry data
  void _searchItem(String query) {
    setState(() {
      _filteredStocks = _stocks.where((item) {
        final productId = (item["PRODUCT ID"] ?? "").toString().toLowerCase();
        final productName = (item["PRODUCT NAME"] ?? "").toString().toLowerCase();
        final combined = "$productId $productName";
        return combined.contains(query.toLowerCase());
      }).toList();

      _filteredExpiry = _batchExpiryItems.where((batch) {
        final combined = "${batch['batchId']}".toLowerCase();
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Bottom navigation
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
        MaterialPageRoute(builder: (context) => TransactionScreen(isDarkMode: _isDarkMode)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserScreen(isDarkMode: _isDarkMode)),
      );
    } else if (index == 3) {
      // Stay on Inventory
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
              // Manage Inventory Section
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
                    // Product ID
                    _buildTextField(
                      controller: _productIdController,
                      label: "Enter product ID",
                    ),
                    const SizedBox(height: 10),
                    // Quantity
                    _buildTextField(
                      controller: _quantityController,
                      label: "Enter quantity to add",
                    ),
                    const SizedBox(height: 10),
                    // Amount
                    _buildTextField(
                      controller: _amountController,
                      label: "Enter amount",
                    ),
                    const SizedBox(height: 10),
                    // Submit Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2A5E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stock Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStockIndicator(count: _inStockCount, label: "In stock", color: Colors.green),
                  _buildStockIndicator(count: _warningCount, label: "Warning", color: Colors.orange),
                  _buildStockIndicator(count: _outOfStockCount, label: "Out of stock", color: Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              // Search and Add New Product
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Search",
                        labelStyle: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
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
              // Main Inventory Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Batch ID")),
                    DataColumn(label: Text("Product ID")),
                    DataColumn(label: Text("Product Name")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Count")),
                  ],
                  rows: _filteredStocks.map((item) {
                    final batchId = item["BATCH ID"]?.toString() ?? "";
                    final productId = item["PRODUCT ID"]?.toString() ?? "";
                    final productName = item["PRODUCT NAME"]?.toString() ?? "";
                    final amountStr = item["AMOUNT"]?.toString() ?? "0";
                    final statusStr = item["STATUS"]?.toString() ?? "Out of stock";
                    final countStr = item["COUNT"]?.toString() ?? "0";
                    return DataRow(cells: [
                      DataCell(Text(batchId)),
                      DataCell(Text(productId)),
                      DataCell(Text(productName)),
                      DataCell(Text(amountStr)),
                      DataCell(
                        Text(
                          statusStr,
                          style: TextStyle(
                            color: _getStatusColor(statusStr),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text(countStr)),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Batch Expiry Management Table
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
                  columns: const [
                    DataColumn(label: Text("Batch ID")),
                    DataColumn(label: Text("Expiration")),
                    DataColumn(label: Text("Supplier")),
                    DataColumn(label: Text("Date Received")),
                  ],
                  rows: _filteredExpiry.map((batch) {
                    return DataRow(cells: [
                      DataCell(Text(batch["batchId"] ?? "")),
                      DataCell(Text(batch["expiration"] ?? "")),
                      DataCell(Text(batch["supplier"] ?? "")),
                      DataCell(Text(batch["dateReceived"] ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Refresh Button
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
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDarkMode ? Colors.white70 : Colors.black54,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Helper for the dropdown (if needed)
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: _isDarkMode ? Colors.grey[900] : Colors.white,
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Helper for the colored stock indicator boxes
  Widget _buildStockIndicator({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 80,
      height: 80,
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
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
