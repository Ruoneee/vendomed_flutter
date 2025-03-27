import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transaction.dart';
import 'database_helper.dart';
import 'inventory.dart';

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

  // Full user list from DB + filtered list for searching
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  // Instead of an integer ID, we'll track the selected RFID
  String? _selectedRfid;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _fetchUsersFromDB();
  }

  // Fetch all users from the DB
  Future<void> _fetchUsersFromDB() async {
    try {
      final userList = await DatabaseHelper.instance.getAllUsers();
      setState(() {
        _users = userList;
        _filteredUsers = List.from(userList);
      });
      debugPrint("Fetched ${userList.length} users from DB");
    } catch (e) {
      debugPrint("Error fetching users from DB: $e");
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

  // Update the selected user using RFID
  Future<void> _onEditUser() async {
    if (_selectedRfid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user selected for editing")),
      );
      return;
    }

    final updatedUser = {
      'NAME': _nameController.text,
      'EMAIL': _emailController.text,
      'EXPIRATION': _expirationController.text,
    };

    try {
      await DatabaseHelper.instance.updateUserByRFID(updatedUser, _selectedRfid!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User updated successfully")),
      );
      await _fetchUsersFromDB();
    } catch (e) {
      debugPrint("Error updating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user: $e")),
      );
    }
  }

  // Delete the selected user using RFID
  Future<void> _onDeleteUser() async {
    if (_selectedRfid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user selected for deletion")),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.deleteUserByRFID(_selectedRfid!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );
      await _fetchUsersFromDB();
      // Clear the form after deletion
      setState(() {
        _selectedRfid = null;
        _rfidController.clear();
        _nameController.clear();
        _emailController.clear();
        _expirationController.clear();
      });
    } catch (e) {
      debugPrint("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
    }
  }

  // Search user by RFID or NAME
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InventoryScreen(isDarkMode: _isDarkMode)),
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
              // Manage User
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isDarkMode ? Colors.white54 : Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _rfidController, label: "Enter RFID Number"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _nameController, label: "User's Name"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _emailController, label: "Email Address"),
                    const SizedBox(height: 10),
                    _buildTextField(controller: _expirationController, label: "Expiration"),
                    // Removed the Confirm button
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // User Information + Search
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A5E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "User Information",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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

              // Data Table with swapped columns (POINTS, then EMAIL)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text("RFID")),
                    DataColumn(label: Text("NAME")),
                    DataColumn(label: Text("POINTS")),      // Swapped up
                    DataColumn(label: Text("EXPIRATION")),
                    DataColumn(label: Text("EMAIL")),       // Swapped down
                  ],
                  rows: _filteredUsers.map((user) {
                    final rfid = user["RFID"]?.toString();
                    return DataRow(
                      selected: rfid == _selectedRfid,
                      onSelectChanged: (selected) {
                        if (selected == true && rfid != null) {
                          setState(() {
                            _selectedRfid = rfid;
                            _rfidController.text = rfid;
                            _nameController.text = user["NAME"]?.toString() ?? "";
                            _emailController.text = user["EMAIL"]?.toString() ?? "";
                            _expirationController.text = user["EXPIRATION"]?.toString() ?? "";
                          });
                        } else {
                          setState(() {
                            if (_selectedRfid == rfid) {
                              _selectedRfid = null;
                            }
                          });
                        }
                      },
                      cells: [
                        DataCell(Text(rfid ?? "")),
                        DataCell(Text(user["NAME"]?.toString() ?? "")),
                        DataCell(Text(user["POINTS"]?.toString() ?? "")), // Moved up
                        DataCell(Text(user["EXPIRATION"]?.toString() ?? "")),
                        DataCell(Text(user["EMAIL"]?.toString() ?? "")),    // Moved down
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Edit, Refresh, Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Edit User
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _onEditUser,
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
                      onPressed: _onDeleteUser,
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

  // Helper method for building styled TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
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
}
