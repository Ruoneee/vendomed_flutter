// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'package:flutter/material.dart';

class MedicineMenu extends StatefulWidget {
  const MedicineMenu({super.key});

  @override
  MedicineMenuState createState() => MedicineMenuState();
}

class MedicineMenuState extends State<MedicineMenu> {
  List<String> orders = []; // List to keep track of selected medicines
  List<bool> buttonStates = [true, true, true, true]; // Button states for each medicine

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5D6F), // Set app bar color
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/userIcons/user_icon.png'), // User icon image
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
      body: Container(
        color: const Color(0xfffffe4e5), // Set background color
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding around the content
          child: Column(
            children: [
              const SizedBox(height: 10), // Space to push content down

              // Scrollable List for items (for receipt summary)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align title to the start
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0), // Space between title and list
                    child: Text(
                      "Your Orders:", // Title text
                      style: TextStyle(
                        fontSize: 18, // Font size of the title
                        fontWeight: FontWeight.bold, // Bold font weight
                        color: Colors.black, // Title text color
                      ),
                    ),
                  ),
                  Container(
                    height: 95, // Set a specific height for the ListView
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color of the list
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Scrollbar( // Add a Scrollbar here
                      child: ListView.builder(
                        padding: EdgeInsets.zero, // Remove default padding from the ListView
                        itemCount: orders.length, // Number of items in the orders
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0), // Set vertical padding to 0.0 for minimal spacing
                            child: Text(
                              '${index + 1}. ${orders[index]}', // Display each order with its index
                              style: const TextStyle(fontSize: 16), // You can also adjust the font size if needed
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20), // Space below the list

              // Grid of Medicines
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // Number of columns in the grid
                  childAspectRatio: 0.75, // Aspect ratio of each child
                  mainAxisSpacing: 16, // Vertical spacing between items
                  crossAxisSpacing: 16, // Horizontal spacing between items
                  children: [
                    // Medicine Item 1
                    _buildMedicineItem('Ibuprofen', '₱10.00', 'assets/images/ibuprofen.png', 4, 0),
                    // Medicine Item 2
                    _buildMedicineItem('Cetirizine', '₱18.00', 'assets/images/cetirizine.png', 1, 1),
                    // Medicine Item 3
                    _buildMedicineItem('Paracetamol', '₱5.00', 'assets/images/paracetamol.png', 4, 2),
                    // Medicine Item 4
                    _buildMedicineItem('Loperamide', '₱10.00', 'assets/images/loperamide.png', 2, 3),
                  ],
                ),
              ),

              // Bottom buttons: Reset and Checkout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space buttons evenly
                children: [
                  ElevatedButton(
                    onPressed: _resetOrders, // Reset orders on button press
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700], // Button color
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), // Padding for the button
                    ),
                    child: const Text(
                      "RESET", // Button text
                      style: TextStyle(
                        fontSize: 18, // Font size of the button text
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _proceedToCheckout, // Proceed to checkout on button press
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5D6F), // Checkout button color
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), // Padding for the button
                    ),
                    child: const Text(
                      "CHECKOUT", // Button text
                      style: TextStyle(
                        fontSize: 18, // Font size of the button text
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build each medicine item
  Widget _buildMedicineItem(String name, String price, String imagePath, int quantity, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color of medicine item
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding inside the item
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Image.asset(
              imagePath, // Image of the medicine
              height: 100, // Height of the medicine image
            ),
            const SizedBox(height: 2), // Space below the image
            Text(
              name, // Name of the medicine
              style: const TextStyle(
                fontSize: 16, // Font size of the medicine name
                fontWeight: FontWeight.bold, // Bold font weight
                color: Colors.black, // Text color
              ),
            ),
            Text(
              price, // Price of the medicine
              style: const TextStyle(
                fontSize: 14, // Font size of the price
                color: Colors.black54, // Text color for price
              ),
            ),
            const Spacer(), // Flexible space to push content up
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center quantity text
              children: [
                Text(
                  '+ $quantity', // Display quantity of the medicine
                  style: const TextStyle(
                    fontSize: 16, // Font size of quantity text
                    fontWeight: FontWeight.bold, // Bold font weight
                    color: Color(0xFF267489), // Quantity color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1), // Space below the quantity
            Material(
              color: Colors.transparent, // Make the button transparent
              child: ElevatedButton(
                onPressed: buttonStates[index] ? () => _addToOrder(name, index) : null, // Add to order if button is enabled
                child: const Text('Add to Order'), // Button text
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to add medicine to order
  void _addToOrder(String name, int index) {
    setState(() {
      orders.add(name); // Add medicine to the orders
      buttonStates[index] = false; // Disable the button
    });
  }

  // Function to reset orders
  void _resetOrders() {
    setState(() {
      orders.clear(); // Clear orders
      buttonStates = [true, true, true, true]; // Enable all buttons again
    });
  }

  // Function to proceed to checkout
  void _proceedToCheckout() {
    if (orders.isEmpty) {
      _showAlertDialog(); // Show alert if no orders are present
    } else {
      Navigator.pushNamed(context, '/payment'); // Navigate to payment page
    }
  }

  // Function to show alert dialog
  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Orders'), // Alert dialog title
          content: const Text('Please add medicines to your order before proceeding.'), // Alert dialog message
          actions: <Widget>[
            TextButton(
              child: const Text('OK'), // Button text
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }
}
