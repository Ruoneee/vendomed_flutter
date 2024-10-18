// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';
import 'payment.dart';

class MedicineMenu extends StatefulWidget {
  const MedicineMenu({super.key});

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  List<Map<String, String>> orders = []; // List to keep track of selected medicines (name and price)
  List<bool> buttonStates = [true, true, true, true]; // Button states for each medicine

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return false; // Prevent the back button
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E5D6F),
            automaticallyImplyLeading: false,
            title: const Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/userIcons/user_icon.png'),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Text(
                  "Welcome, User!",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          body: Container(
            color: const Color(0xfffffe4e5),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                                padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                                child: Text(
                                  '${index + 1}. ${orders[index]['name']} - ${orders[index]['price']}',
                                  style: const TextStyle(fontSize: 16),
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
                        _buildMedicineItem('Ibuprofen', '₱10.00', 'assets/images/ibuprofen.png', 4, 0),
                        _buildMedicineItem('Cetirizine', '₱18.00', 'assets/images/cetirizine.png', 1, 1),
                        _buildMedicineItem('Paracetamol', '₱5.00', 'assets/images/paracetamol.png', 4, 2),
                        _buildMedicineItem('Loperamide', '₱10.00', 'assets/images/loperamide.png', 2, 3),
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
                          child: const Text(
                            "RESET",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _proceedToCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5D6F),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          ),
                          child: const Text(
                            "CHECKOUT",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildMedicineItem(String name, String price, String imagePath, int quantity, int index) {
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
            Image.asset(imagePath, height: 100),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              price,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$quantity pcs. daily',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF267489)),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed: buttonStates[index] ? () => _addToOrder(name, price, index) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonStates[index] ? const Color(0xFF1E5D6F) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
                  ),
                  child: const Text(
                    'Add to Order',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToOrder(String name, String price, int index) {
    setState(() {
      orders.add({'name': name, 'price': price});
      buttonStates[index] = false;
    });
  }

  void _resetOrders() {
    setState(() {
      orders.clear();
      buttonStates = [true, true, true, true];
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
          builder: (context) => PaymentPage(
            orders: orders, // Pass the orders list as is (containing name and price)
          ),
        ),
      );
    }
  }
}
