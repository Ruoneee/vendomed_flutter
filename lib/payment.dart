import 'package:flutter/material.dart';
import 'confirmation_screen.dart';
import 'database_helper.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, String>> orders;
  final List<String> medicinesToBeDisabled;
  final String rfidData;

  const PaymentPage({
    super.key,
    required this.orders,
    required this.medicinesToBeDisabled,
    required this.rfidData,
  });

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  final TextEditingController _coinsInsertedController = TextEditingController();

  int coinInserted = 0;
  bool coinEqualToAmount = false;
  double totalAmount = 0.0;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _calculateTotalAmount();
    _loadUserName();
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
      if (result.isNotEmpty) {
        setState(() {
          _userName = result.first['NAME'] as String;
        });
      } else {
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

  void _calculateTotalAmount() {
    totalAmount = 0.0;

    // We expect each item in widget.orders to have:
    // 'name': 'Ibuprofen',
    // 'quantity': '2',
    // 'price': '40.00' (the total cost, not per item)
    for (var order in widget.orders) {
      // If 'price' is already the total, we can parse it directly:
      String rawPrice = order['price'] ?? '0.00';
      // Remove any leading '₱' if it exists, then parse to double.
      rawPrice = rawPrice.replaceAll('₱', '').trim();
      totalAmount += double.parse(rawPrice);
    }
  }

  void _onProceedButtonPressed() {
    if (coinEqualToAmount) {
      setState(() {
        coinEqualToAmount = false;
        coinInserted = 0;
      });
      print("Transaction Successful");

      // Return to previous screen (MedicineMenu) with the list of disabled medicines
      Navigator.pop(context, widget.medicinesToBeDisabled);

      // Navigate to the confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient Coins Inserted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // disable device back button
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
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orders label
              const Text(
                'YOUR ORDER/S:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold, // Keep label bold if you like
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Orders list
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: widget.orders.length,
                    itemBuilder: (context, index) {
                      // We display:
                      //   {name} (Qty: {quantity}) - ₱{price}
                      final orderName = widget.orders[index]['name'] ?? 'Unknown';
                      final orderQuantity = widget.orders[index]['quantity'] ?? '1';
                      final orderPrice = widget.orders[index]['price'] ?? '0.00';

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '$orderName (Qty: $orderQuantity) - ₱$orderPrice',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          softWrap: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Total amount label
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Display total in a disabled TextFormField
              TextFormField(
                enabled: false,
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: 'Total amount will appear here',
                ),
                initialValue: '₱${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // CANCEL + PROCEED
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D2A5E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onProceedButtonPressed,
                    child: const Text('PROCEED'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
