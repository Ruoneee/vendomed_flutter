import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'database_helper.dart';
import 'dart:async';

class MedicineMenu extends StatefulWidget {
  final String rfidData;

  const MedicineMenu({super.key, required this.rfidData});

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  List<Map<String, String>> orders = [];
  String _userName = "";
  List<Map<String, dynamic>> medicines = [];
  Timer? _stockUpdateTimer;
  Map<String, bool> _isTapped = {};

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchMedicines();
    _startStockListener();
  }

  @override
  void dispose() {
    _stockUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStockListener() {
    _stockUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMedicines();
    });
  }

  Future<void> _loadUserName() async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['NAME'],
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );
      setState(() {
        _userName = result.isNotEmpty ? result.first['NAME'] as String : widget.rfidData;
      });
    } catch (e) {
      print("Error loading user name: $e");
      setState(() {
        _userName = widget.rfidData;
      });
    }
  }

  Future<void> _fetchMedicines() async {
    try {
      final db = await DatabaseHelper().db;
      final List<Map<String, dynamic>> results = await db.query('stocks');

      setState(() {
        medicines = results.map((medicine) {
          final String medicineName = medicine['NAME'] ?? 'Unknown';
          _isTapped.putIfAbsent(medicineName, () => false);
          return {
            'NAME': medicineName,
            'AMOUNT': medicine['AMOUNT']?.toString() ?? '0',
            'STOCKS': medicine['STOCKS'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching medicines: $e");
    }
  }

  String _getImagePath(String name) {
    final Map<String, String> imagePaths = {
      'Ibuprofen': 'assets/images/ibuprofen.png',
      'Cetirizine': 'assets/images/cetirizine.png',
      'Paracetamol': 'assets/images/paracetamol.png',
      'Loperamide': 'assets/images/loperamide.png',
      'Antacid': 'assets/images/antacid.png',
      'Buscopan': 'assets/images/buscopan.png',
    };
    return imagePaths[name] ?? 'assets/images/default.png';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/userIcons/user_icon.png'),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSelectionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildMedicineGrid()),
            _buildUserButtons(), // Reset & Checkout Buttons (Dashboard removed)
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: medicines.map((medicine) {
        return _buildMedicineItem(
          medicine['NAME'],
          medicine['AMOUNT'].toString(),
          _getImagePath(medicine['NAME']),
          medicine['STOCKS'],
        );
      }).toList(),
    );
  }

  Widget _buildUserButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _resetOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("RESET", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2A5E),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("CHECKOUT", style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(String? name, String? unitPrice, String imagePath, int? stocks) {
    return GestureDetector(
      onTap: () async {
        if (stocks != null && stocks > 0) {
          await _addToOrder(name!, unitPrice ?? '0.00');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Out of stock!"), backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Image.asset(imagePath, height: 100, fit: BoxFit.contain),
            Text(name ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('₱${unitPrice ?? "0.00"}', style: const TextStyle(fontSize: 18, color: Colors.black54)),
            Text('Remaining: ${stocks ?? 0} pc/s', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D2A5E))),
          ],
        ),
      ),
    );
  }

  Future<void> _addToOrder(String name, String unitPriceStr) async {
    setState(() {
      orders.add({'name': name, 'quantity': '1', 'price': unitPriceStr});
    });
  }

  void _resetOrders() {
    setState(() {
      orders.clear();
    });
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodPage(orders: orders, rfidData: widget.rfidData),
      ),
    ).then((_) => setState(() => orders.clear()));
  }
}
