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

  // Example user list (replace with DB calls as needed)
  List<Map<String, String>> _users = [
    {
      "rfid": "0102010",
      "name": "Rustan Chavez",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
    {
      "rfid": "0102011",
      "name": "Mai Cardenas",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
    {
      "rfid": "0102012",
      "name": "Russel Coquina",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
    {
      "rfid": "0102013",
      "name": "JM Romulo",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
    {
      "rfid": "0102014",
      "name": "Angelo Joe",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
    {
      "rfid": "0102010",
      "name": "Juan Santos",
      "email": "user@gmail.com",
      "expiration": "10/03/25",
      "points": "12345"
    },
  ];

  // Filtered list for search
  List<Map<String, String>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _filteredUsers = List.from(_users); // Initially show all
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

  // Simple "Confirm" action
  void _onConfirm() {
    // Example: Insert or update user in DB. For now, just print.
    print("RFID: ${_rfidController.text}");
    print("Name: ${_nameController.text}");
    print("Email: ${_emailController.text}");
    print("Expiration: ${_expirationController.text}");

    // Clear fields
    _rfidController.clear();
    _nameController.clear();
    _emailController.clear();
    _expirationController.clear();
  }

  // Search user by name or RFID
  void _searchUser(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        final combined = "${user['rfid']} ${user['name']}".toLowerCase();
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
        MaterialPageRoute(
          builder: (context) => TransactionScreen(isDarkMode: _isDarkMode),
        ),
      );
    } else if (index == 2) {
      // Stay on Users
    } else if (index == 3) {
      // Example: Navigate to "Inventory" screen
      // Navigator.pushReplacement(...);
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
        // MATCH the icon/text sizes from your other screens:
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
              // "Manage User" title
              Text(
                "Manage User",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // The four text fields (RFID, Name, Email, Expiration)
              _buildTextField(
                controller: _rfidController,
                label: "Enter RFID Number",
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                label: "User's Name",
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _expirationController,
                label: "Expiration",
              ),
              const SizedBox(height: 10),

              // Confirm button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2A5E),
                  ),
                  child: const Text("Confirm"),
                ),
              ),
              const SizedBox(height: 20),

              // "User Information"
              Text(
                "User Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Table + search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // We can just display the text "Search User" next to a field:
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: "Search User",
                        labelStyle: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) => _searchUser(value),
                    ),
                  ),
                  // Could add a separate "Search" button if needed
                ],
              ),
              const SizedBox(height: 10),

              // DataTable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("RFID")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Email")),
                    DataColumn(label: Text("Expiration")),
                    DataColumn(label: Text("Points")),
                  ],
                  rows: _filteredUsers.map((user) {
                    return DataRow(cells: [
                      DataCell(Text(user["rfid"] ?? "")),
                      DataCell(Text(user["name"] ?? "")),
                      DataCell(Text(user["email"] ?? "")),
                      DataCell(Text(user["expiration"] ?? "")),
                      DataCell(Text(user["points"] ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Edit User, Delete User, Refresh
              // (In the screenshot, these are stacked vertically.)
              ElevatedButton(
                onPressed: () {
                  // Example action: edit the selected user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Edit User clicked")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text("Edit User"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Example action: delete the selected user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Delete User clicked")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("Delete User"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Example action: refresh the table
                  setState(() {
                    _searchController.clear();
                    _filteredUsers = List.from(_users);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Refresh"),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
