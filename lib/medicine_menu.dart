// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'database_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';

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
  Map<String, bool> _isTapped = {}; // Tracks the tap state of each item

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

// LOADING USER'S NAME FROM THE DATABASE

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

// FETCHING MEDICINES FROM DATABASE

  Future<void> _fetchMedicines() async {
    try {
      final db = await DatabaseHelper().db;
      final List<Map<String, dynamic>> results = await db.query('stocks');

      setState(() {
        medicines = results.map((medicine) {
          String medicineName = medicine['NAME'] ?? 'Unknown';
          _isTapped.putIfAbsent(medicineName, () => false); // Initialize tap state
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

// MAPPING MEDICINE NAME TO IMAGE PATH

  String _getImagePath(String name) {
    final Map<String, String> imagePaths = {
      'Ibuprofen': 'assets/images/Ibuprofen.png',
      'Cetirizine': 'assets/images/Cetirizine.png',
      'Paracetamol': 'assets/images/Paracetamol.png',
      'Loperamide': 'assets/images/Loperamide.png',
      'Antacid': 'assets/images/Antacid.png',
      'Buscopan': 'assets/images/Buscopan.png',
    };
    return imagePaths[name] ?? 'assets/images/default.png';
  }

// APP BAR FUNCTION

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

// LIST VIEW

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
                          fontSize: 30,
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

// MEDICINE CONTENTS

                const SizedBox(height: 30),
                Expanded(
                  child: medicines.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: medicines.map((medicine) {
                      return _buildMedicineItem(
                        medicine['NAME'],
                        medicine['AMOUNT'].toString(),
                        _getImagePath(medicine['NAME']),
                        medicine['STOCKS'],
                      );
                    }).toList(),
                  ),
                ),

// RESET AND CHECKOUT BUTTON DESIGN

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

  Widget _buildMedicineItem(String? name, String? price, String imagePath, int? stocks) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.18;
    bool isTapped = _isTapped[name] ?? false;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped[name!] = true; // Set tapped state
        });
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _isTapped[name!] = false; // Reset animation after tap
          });
        });

        if (stocks != null && stocks > 0) {
          _addToOrder(name!, price ?? '0.00');
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
          _isTapped[name!] = false; // Reset animation if tap is canceled
        });
      },
      child: AnimatedScale(
        scale: isTapped ? 0.95 : 1.0, // Shrink slightly when tapped
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Spacer(), // Push content down
                Image.asset(
                  imagePath,
                  height: imageHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 15),
                Text(
                  name ?? 'Unknown Medicine',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '₱${price ?? "0.00"}',
                  style: const TextStyle(fontSize: 30, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Text(
                  'Remaining: ${stocks ?? 0} pc/s',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2A5E),
                  ),
                ),
                const Spacer(), // Push content upward slightly
              ],
            ),
          ),
        ),
      ),
    );
  }


//BUTTON FUNCTIONALITIES

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
