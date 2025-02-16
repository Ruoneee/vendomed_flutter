// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'database_helper.dart';

class MedicineMenu extends StatefulWidget {
  final String rfidData;

  const MedicineMenu({super.key, required this.rfidData});

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  List<Map<String, String>> orders = [];
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final db = await DatabaseHelper().db;
      // Adjust table name and column names to match your actual database
      final result = await db.query(
        'users',             // <-- match your actual table name
        columns: ['NAME'],  // <-- match the column name for the user's name
        where: 'RFID = ?',  // <-- match the column name for the RFID
        whereArgs: [widget.rfidData],
      );
      if (result.isNotEmpty) {
        setState(() {
          _userName = result.first['NAME'] as String;
        });
      } else {
        // If no matching row is found, fallback to showing the RFID
        setState(() {
          _userName = widget.rfidData;
        });
      }
    } catch (e) {
      print("Error loading user name: $e");
      setState(() {
        _userName = widget.rfidData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent the back button
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
              const SizedBox(width: 10),
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
                  MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
                );
              },
            ),
          ],
        ),
        body: Container(
          color: const Color(0xF21588d),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Your Orders:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      height: 95,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 0.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                '${index + 1}. ${orders[index]['name']} - ${orders[index]['price']}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildMedicineItem('Ibuprofen', '10.00', 'assets/images/ibuprofen.png', 4),
                      _buildMedicineItem('Cetirizine', '18.00', 'assets/images/cetirizine.png', 1),
                      _buildMedicineItem('Paracetamol', '5.00', 'assets/images/paracetamol.png', 4),
                      _buildMedicineItem('Loperamide', '10.00', 'assets/images/loperamide.png', 2),
                      _buildMedicineItem('Antacid', '8.00', 'assets/images/antacid.png', 3),
                      _buildMedicineItem('Buscopan', '12.00', 'assets/images/buscopan.png', 1),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _resetOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        ),
                        child: const Text("RESET", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _proceedToCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2A5E),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        ),
                        child: const Text("CHECKOUT", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineItem(String name, String price, String imagePath, int recommendedQuantity) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.20;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontSize: 20, color: Colors.black54),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Recommended: $recommendedQuantity pcs.',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _addToOrder(name, price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
                ),
                child: const Text(
                  'Add to Order',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToOrder(String name, String price) {
    setState(() {
      orders.add({'name': name, 'price': price});
    });
  }

  void _resetOrders() {
    setState(() {
      orders.clear();
    });
  }

  void _proceedToCheckout() {
    if (orders.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Orders'),
            content: const Text('Please add items to your order before proceeding to checkout.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodPage(
            orders: orders,
            rfidData: widget.rfidData,
          ),
        ),
      ).then((result) {
        if (result == true) {
          setState(() {
            orders.clear();
          });
        }
      });
    }
  }
}
