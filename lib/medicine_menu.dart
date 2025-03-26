import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'payment.dart'; // <-- Import your PaymentPage here
import 'database_helper.dart';
import 'dart:async';

class MedicineMenu extends StatefulWidget {
  final String rfidData;
  /// Optional: use this to pass existing orders when coming back from Payment screens.
  final List<Map<String, String>>? existingOrders;

  const MedicineMenu({
    Key? key,
    required this.rfidData,
    this.existingOrders,
  }) : super(key: key);

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  /// Each order is a map with keys: 'name', 'quantity', and 'price'.
  List<Map<String, String>> orders = [];

  String _userName = "";
  String _userPoints = "0"; // Store the user's points

  List<Map<String, dynamic>> medicines = [];
  Timer? _stockUpdateTimer;

  // For handling tap animations on medicine items.
  Map<String, bool> _isTapped = {};

  @override
  void initState() {
    super.initState();
    // If there are existing orders passed in, use them.
    if (widget.existingOrders != null) {
      orders = List.from(widget.existingOrders!);
    }
    _loadUserNameAndPoints(); // Load user name and points
    _fetchMedicines();
    _startStockListener();
  }

  @override
  void dispose() {
    _stockUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStockListener() {
    // Refresh the medicines every 2 seconds.
    _stockUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMedicines();
    });
  }

  /// Fetch both user NAME and POINTS from 'users' table by RFID.
  /// If no user record is found, treat them as a Guest (userName == widget.rfidData).
  Future<void> _loadUserNameAndPoints() async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['NAME', 'POINTS'], // Ensure 'POINTS' column exists
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );

      if (result.isNotEmpty) {
        setState(() {
          _userName = result.first['NAME']?.toString() ?? widget.rfidData;
          _userPoints = result.first['POINTS']?.toString() ?? '0';
        });
      } else {
        // If no user found with that RFID, fallback to showing the raw RFID
        setState(() {
          _userName = widget.rfidData; // Treat as Guest
          _userPoints = '0';
        });
      }
    } catch (e) {
      print("Error loading user name/points: $e");
      setState(() {
        _userName = widget.rfidData;
        _userPoints = '0';
      });
    }
  }

  /// Reads medicines from the 'stocks' table.
  /// Your table has columns: product_name, amount, count.
  Future<void> _fetchMedicines() async {
    try {
      final db = await DatabaseHelper().db;
      final List<Map<String, dynamic>> results = await db.query('stocks');

      setState(() {
        medicines = results.map((row) {
          final String productName = row['product_name'] ?? 'Unknown';
          _isTapped.putIfAbsent(productName, () => false);

          final String amountStr = row['amount']?.toString() ?? '0';
          final int stockCount =
              int.tryParse(row['count']?.toString() ?? '0') ?? 0;

          return {
            'product_name': productName,
            'amount': amountStr,
            'count': stockCount,
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching medicines: $e");
    }
  }

  /// Returns the image asset path based on product name.
  /// If no match is found, returns an empty string (so a placeholder is shown).
  String _getImagePath(String productName) {
    final Map<String, String> imagePaths = {
      'Ibuprofen': 'assets/images/ibuprofen.png',
      'Cetirizine': 'assets/images/cetirizine.png',
      'Paracetamol': 'assets/images/paracetamol.png',
      'Loperamide': 'assets/images/loperamide.png',
      'Antacid': 'assets/images/antacid.png',
      'Buscopan': 'assets/images/buscopan.png',
    };
    return imagePaths[productName] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Disable Android's back button.
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          // Removed the user icon from the title.
          title: Text(
            "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // Navigate back to the UserSelectionScreen.
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
              // Show "VendoPoints" (or "Current Points") if the user is an RFID user.
              if (_userName != widget.rfidData) ...[
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    // Border based on AppBar color.
                    border: Border.all(
                      color: const Color(0xFF0D2A5E),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "VendoPoints: $_userPoints",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // "Your Orders"
              const Text(
                "Your Orders:",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Orders list in a white box
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
                          horizontal: 6.0,
                          vertical: 3.0,
                        ),
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

              // Medicine grid
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
                      medicine['product_name'] as String,
                      medicine['amount'] as String,
                      _getImagePath(medicine['product_name'] as String),
                      medicine['count'] as int,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // RESET and CHECKOUT Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _resetOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      "RESET",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
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
      String productName,
      String amountStr,
      String imagePath,
      int stockCount,
      ) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.18;
    bool isTapped = _isTapped[productName] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped[productName] = true;
        });
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _isTapped[productName] = false;
          });
        });
        if (stockCount > 0) {
          _addToOrder(productName, amountStr);
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
          _isTapped[productName] = false;
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
              if (imagePath.isNotEmpty)
                Image.asset(
                  imagePath,
                  height: imageHeight,
                  fit: BoxFit.contain,
                )
              else
                Container(
                  height: imageHeight,
                  alignment: Alignment.center,
                  child: const Text(
                    "No image",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '₱$amountStr',
                style: const TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Remaining: $stockCount pc/s',
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

  void _addToOrder(String productName, String unitPriceStr) {
    setState(() {
      final double unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
      final existingIndex =
      orders.indexWhere((item) => item['name'] == productName);

      if (existingIndex != -1) {
        final oldQuantity =
            int.tryParse(orders[existingIndex]['quantity'] ?? '1') ?? 1;
        final newQuantity = oldQuantity + 1;
        final double newTotalPrice = unitPrice * newQuantity;
        orders[existingIndex]['quantity'] = newQuantity.toString();
        orders[existingIndex]['price'] = newTotalPrice.toStringAsFixed(2);
      } else {
        orders.add({
          'name': productName,
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
    // Check if this user is a "guest" (i.e., no record in DB => _userName == widget.rfidData)
    if (_userName == widget.rfidData) {
      // GUEST user => go directly to PaymentPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            orders: orders,
            rfidData: widget.rfidData,
            medicinesToBeDisabled: const [], // Provide an empty list if needed
          ),
        ),
      ).then((_) => setState(() => orders.clear()));
    } else {
      // RFID user => proceed to PaymentMethodPage
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
  }
}
