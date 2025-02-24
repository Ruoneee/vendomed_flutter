import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'database_helper.dart';
import 'dashboard.dart'; // Import the dashboard screen.
import 'dart:async';

class MedicineMenu extends StatefulWidget {
  final String rfidData;

  const MedicineMenu({super.key, required this.rfidData});

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  // Each order now includes: name, quantity, and price.
  List<Map<String, String>> orders = [];

  String _userName = "";
  List<Map<String, dynamic>> medicines = [];
  Timer? _stockUpdateTimer;
  Map<String, bool> _isTapped = {}; // Tracks the tap state of each item.

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
    // Fetches from the database every 2 seconds.
    _stockUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMedicines();
    });
  }

  // Load user name from DB.
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
        _userName = result.isNotEmpty
            ? result.first['NAME'] as String
            : widget.rfidData;
      });
    } catch (e) {
      print("Error loading user name: $e");
      setState(() {
        _userName = widget.rfidData;
      });
    }
  }

  // Fetch medicines from DB.
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

  // Map medicine name to image path.
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
      onWillPop: () async => false, // Prevent Android back button.
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
        body: Container(
          color: const Color(0xF21588d),
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              // "Your Orders" header.
              const Text(
                "Your Orders:",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Orders List Container.
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final orderName = orders[index]['name'] ?? 'Unknown';
                      final orderQuantity = orders[index]['quantity'] ?? '1';
                      final orderPrice = orders[index]['price'] ?? '0.00';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 3.0),
                        child: Text(
                          '${index + 1}. $orderName (Qty: $orderQuantity) - ₱$orderPrice',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Grid of medicines.
              if (medicines.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
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
                ),
              const SizedBox(height: 20),
              // DASHBOARD, RESET & CHECKOUT BUTTONS (RESET in the middle).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // DASHBOARD Button.
                  ElevatedButton(
                    onPressed: _navigateToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      "DASHBOARD",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  // RESET Button.
                  ElevatedButton(
                    onPressed: _resetOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      "RESET",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  // CHECKOUT Button.
                  ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      "CHECKOUT",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineItem(
      String? name,
      String? unitPrice,
      String imagePath,
      int? stocks,
      ) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.18;
    bool isTapped = _isTapped[name] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped[name!] = true;
        });
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _isTapped[name!] = false;
          });
        });
        if (stocks != null && stocks > 0) {
          _addToOrder(name!, unitPrice ?? '0.00');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Out of stock!"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onTapCancel: () {
        setState(() {
          _isTapped[name!] = false;
        });
      },
      child: AnimatedScale(
        scale: isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                imagePath,
                height: imageHeight,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '₱${unitPrice ?? "0.00"}',
                style: const TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Remaining: ${stocks ?? 0} pc/s',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2A5E),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Add or update the item in orders.
  void _addToOrder(String name, String unitPriceStr) {
    setState(() {
      final double unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
      final existingIndex =
      orders.indexWhere((item) => item['name'] == name);
      if (existingIndex != -1) {
        final oldQuantity =
            int.tryParse(orders[existingIndex]['quantity'] ?? '1') ?? 1;
        final newQuantity = oldQuantity + 1;
        final double newTotalPrice = unitPrice * newQuantity;
        orders[existingIndex]['quantity'] = newQuantity.toString();
        orders[existingIndex]['price'] = newTotalPrice.toStringAsFixed(2);
      } else {
        orders.add({
          'name': name,
          'quantity': '1',
          'price': unitPrice.toStringAsFixed(2),
        });
      }
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
        builder: (context) => PaymentMethodPage(
          orders: orders,
          rfidData: widget.rfidData,
        ),
      ),
    ).then((_) => setState(() => orders.clear()));
  }

  // Navigate to DashboardScreen.
  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }
}
