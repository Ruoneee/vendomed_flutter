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

  // Form fields to insert a new item
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _stocksController = TextEditingController();

  // Search field
  final TextEditingController _searchController = TextEditingController();

  // Full list from DB and a filtered list for searching
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _filteredStocks = [];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchStocksFromDB();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _stocksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch all rows from 'stocks' table
  Future<void> _fetchStocksFromDB() async {
    try {
      final stockList = await DatabaseHelper.instance.getAllStocks();
      setState(() {
        _stocks = stockList;
        _filteredStocks = List.from(stockList);
      });
      debugPrint("Fetched ${stockList.length} stocks from DB");
    } catch (e) {
      debugPrint("Error fetching stocks from DB: $e");
    }
  }

  // Insert a new row into 'stocks'
  Future<void> _onSubmit() async {
    final newItem = {
      // Make sure these match your column names in 'stocks' table
      'NAME': _nameController.text,
      'AMOUNT': _amountController.text,
      'STOCKS': _stocksController.text,
    };

    try {
      await DatabaseHelper.instance.insertStock(newItem);
      await _fetchStocksFromDB();
      // Clear fields
      _nameController.clear();
      _amountController.clear();
      _stocksController.clear();
    } catch (e) {
      debugPrint("Error inserting stock: $e");
    }
  }

  // Filter by name or anything else if needed
  void _searchItem(String query) {
    setState(() {
      _filteredStocks = _stocks.where((item) {
        final name = (item['NAME'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
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
        MaterialPageRoute(
          builder: (context) => TransactionScreen(isDarkMode: _isDarkMode),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserScreen(isDarkMode: _isDarkMode),
        ),
      );
    } else if (index == 3) {
      // Stay on Inventory
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
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
              // ======= MANAGE INVENTORY SECTION =======
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

                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: "Name",
                    ),
                    const SizedBox(height: 10),

                    // Amount
                    _buildTextField(
                      controller: _amountController,
                      label: "Amount",
                    ),
                    const SizedBox(height: 10),

                    // Stocks
                    _buildTextField(
                      controller: _stocksController,
                      label: "Stocks",
                    ),
                    const SizedBox(height: 10),

                    // Submit button
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

              // ======= SEARCH & HEADERS (Optional) =======
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Search field
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
                  // Add new product or other actions if needed
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

              // ======= INVENTORY TABLE =======
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("NAME")),
                    DataColumn(label: Text("AMOUNT")),
                    DataColumn(label: Text("STOCKS")),
                  ],
                  rows: _filteredStocks.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item["NAME"]?.toString() ?? "")),
                      DataCell(Text(item["AMOUNT"]?.toString() ?? "")),
                      DataCell(Text(item["STOCKS"]?.toString() ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ======= REFRESH BUTTON =======
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    _searchController.clear();
                    await _fetchStocksFromDB();
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

  // Helper for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDarkMode ? Colors.white70 : Colors.black54,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
