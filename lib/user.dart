// user.dart

import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'transaction.dart';
import 'database_helper.dart';
import 'inventory.dart';

// Branding
const Color _brandStart = Color(0xFF0D2A5E);
const Color _brandEnd   = Color(0xFF1E5D6F);
const LinearGradient _brandGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_brandStart, _brandEnd],
);
final ButtonStyle _brandButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: _brandStart,
  padding: const EdgeInsets.symmetric(vertical: 16),
  textStyle: const TextStyle(fontSize: 16),
);

class UserScreen extends StatefulWidget {
  final bool isDarkMode;
  const UserScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late bool _isDarkMode;
  bool _formVisible = false;
  bool _isLoading   = true;
  int _selectedTabIndex = 2;
  String? _selectedRfid;

  final _rfidCtrl   = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _expCtrl    = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _users         = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _formVisible = true);
    });
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      _users         = list;
      _filteredUsers = List.from(list);
      _isLoading     = false;
    });
  }

  void _searchUser(String q) {
    setState(() {
      _filteredUsers = _users.where((u) {
        final combined = "${u['RFID']} ${u['NAME']} ${u['ROLE']}"
            .toLowerCase();
        return combined.contains(q.toLowerCase());
      }).toList();
    });
  }

  Future<void> _addUser() async {
    if ([ _rfidCtrl, _nameCtrl, _emailCtrl, _expCtrl ]
        .any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }
    await DatabaseHelper.instance.insertUser({
      'RFID'      : _rfidCtrl.text,
      'NAME'      : _nameCtrl.text,
      'EMAIL'     : _emailCtrl.text,
      'EXPIRATION': _expCtrl.text,
      'POINTS'    : 0,
      'ROLE'      : 'User',
    });
    await _fetchUsers();
    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User added")),
    );
  }

  Future<void> _editUser() async {
    if (_selectedRfid == null) return;
    await DatabaseHelper.instance.updateUserByRFID({
      'RFID'      : _rfidCtrl.text,
      'NAME'      : _nameCtrl.text,
      'EMAIL'     : _emailCtrl.text,
      'EXPIRATION': _expCtrl.text,
    }, _selectedRfid!);
    setState(() => _selectedRfid = _rfidCtrl.text);
    await _fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User updated")),
    );
  }

  Future<void> _deleteUser() async {
    if (_selectedRfid == null) return;
    await DatabaseHelper.instance.deleteUserByRFID(_selectedRfid!);
    await _fetchUsers();
    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User deleted")),
    );
  }

  void _clearForm() {
    _rfidCtrl.clear();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _expCtrl.clear();
    setState(() => _selectedRfid = null);
  }

  void _onTab(int i) {
    setState(() => _selectedTabIndex = i);
    final dest = [
      DashboardScreen(),
      TransactionScreen(isDarkMode: _isDarkMode),
      widget,
      InventoryScreen(isDarkMode: _isDarkMode),
    ][i];
    if (dest != widget) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dest),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _brandStart,
        title: const Text(
          "User Dashboard",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold) ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onTab,
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Sales"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: "Payments"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Users"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Inventory"
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _brandGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [

              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _formVisible ? 1 : 0,
                  child: _ManageUserForm(
                    rfidCtrl: _rfidCtrl,
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    expCtrl: _expCtrl,
                    onAdd  : _addUser,
                    onClear: _clearForm,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              SliverToBoxAdapter(
                child: _UserInfoHeader(
                  searchCtrl: _searchCtrl,
                  onSearch : _searchUser,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              if (_isLoading) ...[
                SliverToBoxAdapter(
                  child: Column(
                    children: List.generate(5, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        height: 24,
                        width: double.infinity,
                        color: Colors.white24,
                      );
                    }),
                  ),
                )
              ] else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                      final u = _filteredUsers[i];
                      final rfid = u['RFID'].toString();
                      final isSel = rfid == _selectedRfid;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        color: isSel ? Colors.white24 : Colors.transparent,
                        child: ListTile(
                          title: Text(u['NAME'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            "RFID: $rfid  •  EXP: ${u['EXPIRATION']}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text("${u['POINTS']}", style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedRfid = rfid;
                              _rfidCtrl.text = rfid;
                              _nameCtrl.text = u['NAME'] ?? '';
                              _emailCtrl.text = u['EMAIL'] ?? '';
                              _expCtrl.text = u['EXPIRATION'] ?? '';
                            });
                          },
                        ),
                      );
                    },
                    childCount: _filteredUsers.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              SliverToBoxAdapter(
                child: _UserActionsBar(
                  onEdit   : _editUser,
                  onRefresh: _fetchUsers,
                  onDelete : _deleteUser,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _ManageUserForm extends StatelessWidget {
  final TextEditingController rfidCtrl, nameCtrl, emailCtrl, expCtrl;
  final VoidCallback onAdd, onClear;
  const _ManageUserForm({
    Key? key,
    required this.rfidCtrl,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.expCtrl,
    required this.onAdd,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    Widget field(TextEditingController ctrl, String label) => TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          field(rfidCtrl, "Enter RFID Number"),
          const SizedBox(height: 10),
          field(nameCtrl, "User's Name"),
          const SizedBox(height: 10),
          field(emailCtrl, "Email Address"),
          const SizedBox(height: 10),
          field(expCtrl, "Expiration"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: _brandButtonStyle.copyWith(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: onAdd,
                  child: const Text("Add User", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white
                  ),
                  onPressed: onClear,
                  child: const Text("Clear", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserInfoHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  const _UserInfoHeader({
    Key? key,
    required this.searchCtrl,
    required this.onSearch
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _brandStart, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Expanded(
            child: Text("User Information",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search User",
                fillColor: Colors.white,
                filled: true,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionsBar extends StatelessWidget {
  final VoidCallback onEdit, onRefresh, onDelete;
  const _UserActionsBar({
    Key? key,
    required this.onEdit,
    required this.onRefresh,
    required this.onDelete
  }) : super(key: key);

  @override
  Widget build(BuildContext c) {
    Widget btn(String label, VoidCallback cb) => SizedBox(
      width: 120,
      child: ElevatedButton(
        style: _brandButtonStyle.copyWith(
          foregroundColor: MaterialStateProperty.all(Colors.white),
        ),
        onPressed: cb,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn("Edit User", onEdit),
        const SizedBox(width: 16),
        btn("Refresh", onRefresh),
        const SizedBox(width: 16),
        btn("Delete User", onDelete),
      ],
    );
  }
}
