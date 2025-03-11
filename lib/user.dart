import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transaction.dart';
import 'database_helper.dart';

class UserScreen extends StatefulWidget {
  final bool isDarkMode;
  const UserScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _isDarkMode = false;
  int _selectedTabIndex = 2;

  // Form fields
  final TextEditingController _rfidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();

  // Search field
  final TextEditingController _searchController = TextEditingController();

  // User list from the DB and a filtered copy
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchUsersFromDB(); // Load users from vendomed.db on startup
  }

  // Fetch all users from the 'users' table and update lists
  Future<void> _fetchUsersFromDB() async {
    try {
      final userList = await DatabaseHelper.instance.getAllUsers();
      print("Fetched ${userList.length} users from DB");
      setState(() {
        _users = userList;
        _filteredUsers = List.from(userList);
      });
    } catch (e) {
      print("Error fetching users from DB: $e");
    }
  }

  @override
  void dispose() {
    _rfidController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _expirationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Insert a new user into the DB and refresh the list
  Future<void> _onConfirm() async {
    final newUser = {
      // Use exact column names from your table.
      'RFID': _rfidController.text,
      'NAME': _nameController.text,
      'EMAIL': _emailController.text,
      'EXPIRATIONS': _expirationController.text,
      'POINTS': '0', // Default value for points.
      'ROLE': 'User', // Default role.
    };

    try {
      await DatabaseHelper.instance.insertUser(newUser);
      await _fetchUsersFromDB(); // Refresh the list
      // Clear form fields
      _rfidController.clear();
      _nameController.clear();
      _emailController.clear();
      _expirationController.clear();
    } catch (e) {
      print("Error inserting user into DB: $e");
    }
  }

  // Filter users based on search query (by RFID or NAME)
  void _searchUser(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        final rfid = (user['RFID'] ?? '').toString().toLowerCase();
        final name = (user['NAME'] ?? '').toString().toLowerCase();
        final combined = "$rfid $name";
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Bottom navigation logic
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
      // Stay on Users
    } else if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory screen not implemented")),
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
          "User Dashboard",
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
              // ======= MANAGE USER SECTION (Box/Container) =======
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
                    // Title
                    Text(
                      "Manage User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // RFID
                    _buildTextField(
                      controller: _rfidController,
                      label: "Enter RFID Number",
                    ),
                    const SizedBox(height: 10),

                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: "User's Name",
                    ),
                    const SizedBox(height: 10),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                    ),
                    const SizedBox(height: 10),

                    // Expirations
                    _buildTextField(
                      controller: _expirationController,
                      label: "Expirations",
                    ),
                    const SizedBox(height: 10),

                    // Confirm button BELOW Expirations field, centered
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2A5E),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 18),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ======= USER INFORMATION & SEARCH (blue box) =======
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A5E), // Blue background
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade300, // Visible border
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // "User Information" in white
                    Text(
                      "User Information",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // White search bar on the right
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: "Search User",
                          labelStyle: const TextStyle(color: Colors.black54),
                          fillColor: Colors.white,
                          filled: true,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => _searchUser(value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ======= DATA TABLE =======
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("RFID")),
                    DataColumn(label: Text("NAME")),
                    DataColumn(label: Text("EMAIL")),
                    DataColumn(label: Text("EXPIRATIONS")),
                    DataColumn(label: Text("POINTS")),
                  ],
                  rows: _filteredUsers.map((user) {
                    return DataRow(cells: [
                      DataCell(Text(user["RFID"]?.toString() ?? "")),
                      DataCell(Text(user["NAME"]?.toString() ?? "")),
                      DataCell(Text(user["EMAIL"]?.toString() ?? "")),
                      DataCell(Text(user["EXPIRATIONS"]?.toString() ?? "")),
                      DataCell(Text(user["POINTS"]?.toString() ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ======= EDIT, REFRESH, DELETE BUTTONS (side-by-side) =======
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Edit User
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement update logic here.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Edit User clicked")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Edit User"),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Refresh
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () async {
                        _searchController.clear();
                        await _fetchUsersFromDB();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Refresh"),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Delete User
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement delete logic here.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Delete User clicked")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Delete User"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build styled TextFields
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
