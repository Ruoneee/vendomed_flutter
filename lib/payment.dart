import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final List<Map<String, String>> orders; // Accept the orders list with name and price

  const PaymentPage({super.key, required this.orders}); // Constructor to receive orders

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0.0;

    // Sum the total amount from the price in the orders list
    for (var order in orders) {
      String priceString = order['price']!.replaceAll('₱', '').trim(); // Remove '₱' and any spaces
      totalAmount += double.parse(priceString); // Convert to double and sum
    }

    // Sample data for transaction history
    final List<String> transactions = [
      'Transaction 1: P10.00',
      'Transaction 2: P15.00',
      'Transaction 3: P20.00',
    ];

    return WillPopScope(
      onWillPop: () async {
        // Returning false prevents the back button from working
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E5D6F),
          automaticallyImplyLeading: false, // Set app bar color
          title: const Row(
            children: [
              CircleAvatar(
                backgroundImage:
                AssetImage('assets/userIcons/user_icon.png'), // User icon image
                radius: 20, // Radius of the circle
              ),
              SizedBox(width: 10), // Space between icon and text
              Text(
                "Welcome, User!", // Welcome message
                style: TextStyle(
                  fontSize: 18, // Font size of the welcome message
                  color: Colors.white, // Text color
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xfffffe4e5), // Light beige background
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR ORDER/S:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: orders.length, // Display the passed orders
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${orders[index]['name']} - ${orders[index]['price']}'),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Total Amount
              const Text(
                'TOTAL AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: false, // Read-only field
                decoration: const InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Set border color to black
                  ),
                  hintText: 'Total amount will appear here',
                ),
                initialValue: 'P${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black), // Set text color to black// Display total amount
              ),
              const SizedBox(height: 20),

              // Entered Amount
              const Text(
                'ENTERED AMOUNT:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
              ),
              const SizedBox(height: 20),

              // Transaction History
              const Text(
                'TRANSACTION HISTORY:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: transactions.length, // Display transaction history
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(transactions[index]),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E5A5D), // Back button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white, // Set text color for the Back button
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('BACK'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5D6F), // Proceed button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      foregroundColor: Colors.white, // Set text color for the Proceed button
                    ),
                    onPressed: () {
                      Navigator.popAndPushNamed(context, '/rfid_screen'); // Done button action
                    },
                    child: const Text('PROCEED'),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}