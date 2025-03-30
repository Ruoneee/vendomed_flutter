import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'payment.dart'; // <-- Import your PaymentPage here
import 'database_helper.dart';
import 'dart:async';

class MedicineMenu extends StatefulWidget {
  final String rfidData;
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
  List<Map<String, String>> orders = [];
  String _userName = "";
  String _userPoints = "0";
  List<Map<String, dynamic>> medicines = [];
  Timer? _stockUpdateTimer;

  // Tracks tap animation states.
  Map<String, bool> _isTapped = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingOrders != null) {
      orders = List.from(widget.existingOrders!);
    }
    _loadUserNameAndPoints();
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

  Future<void> _loadUserNameAndPoints() async {
    try {
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'users',
        columns: ['NAME', 'POINTS'],
        where: 'RFID = ?',
        whereArgs: [widget.rfidData],
      );

      setState(() {
        if (result.isNotEmpty) {
          _userName = result.first['NAME']?.toString() ?? widget.rfidData;
          _userPoints = result.first['POINTS']?.toString() ?? '0';
        } else {
          // If no user found, treat them as Guest.
          _userName = widget.rfidData;
          _userPoints = '0';
        }
      });
    } catch (e) {
      print("Error loading user name/points: $e");
      setState(() {
        _userName = widget.rfidData;
        _userPoints = '0';
      });
    }
  }

  Future<void> _fetchMedicines() async {
    try {
      final db = await DatabaseHelper().db;
      final List<Map<String, dynamic>> results = await db.query('stocks');
      setState(() {
        medicines = results.map((row) {
          final String productName = row['product_name'] ?? 'Unknown';
          _isTapped.putIfAbsent(productName, () => false);
          final String amountStr = row['amount']?.toString() ?? '0';
          final int stockCount = int.tryParse(row['count']?.toString() ?? '0') ?? 0;
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

  /// Maps product names to corresponding image paths.
  String _getImagePath(String productName) {
    final Map<String, String> imagePaths = {
      'Ibuprofen': 'assets/images/ibuprofen.png',
      'Cetirizine': 'assets/images/cetirizine.png',
      'Paracetamol': 'assets/images/paracetamol.png',
      'Loperamide': 'assets/images/loperamide.png',
      'Antacid': 'assets/images/antacid.png',
      'Buscopan': 'assets/images/buscopan.png',
      'Gaviscon': 'assets/images/gaviscon.png',
    };
    return imagePaths[productName] ?? '';
  }

  /// Opens a centered dialog with detailed product info.
  void _openMedicineDetail(String productName, String amountStr, String imagePath, int stockCount) {
    final Map<String, Map<String, String>> detailsMap = {
      'Loperamide': {
        'dosage': 'Take 2 mg after each loose stool. Do not exceed 8 mg per day. Not for use in children under 6 years.',
        'ingredients': 'Active: Loperamide Hydrochloride 2 mg. Inactive ingredients as per product label.',
        'warnings': 'May cause constipation. Do not exceed recommended dose. Consult a doctor if diarrhea persists.',
        'additionalMedia': 'For detailed labeling, please refer to the official FDA document.',
      },
      'Ibuprofen': {
        'dosage': 'Adults: 200-400 mg every 4-6 hours as needed. Do not exceed 1200 mg per day for OTC use.',
        'ingredients': 'Active: Ibuprofen 200 mg. Inactive ingredients as per product label.',
        'warnings': 'May cause gastrointestinal bleeding. Take with food; not recommended for kidney patients.',
        'additionalMedia': 'For full drug facts, please review the official FDA label information.',
      },
      'Cetirizine': {
        'dosage': 'Take 10 mg once daily for adults and children 6 years and older.',
        'ingredients': 'Active: Cetirizine Hydrochloride 10 mg. Inactive ingredients as per product label.',
        'warnings': 'May cause drowsiness. Avoid operating machinery if affected.',
        'additionalMedia': 'See the official product information for complete details.',
      },
      'Buscopan': {
        'dosage': 'Take 10-20 mg up to 3-4 times daily as needed.',
        'ingredients': 'Active: Hyoscine Butylbromide 10 mg. Inactive ingredients as per product label.',
        'warnings': 'Not recommended for patients with glaucoma or certain heart conditions.',
        'additionalMedia': 'Refer to the official patient information leaflet for more details.',
      },
      'Antacid': {
        'dosage': 'Adults: 15-30 ml after meals and at bedtime. Shake well before use.',
        'ingredients': 'Active: Sodium alginate, potassium bicarbonate, sodium bicarbonate. Inactive ingredients as per product label.',
        'warnings': 'May cause bloating or gas. Do not exceed the recommended dose.',
        'additionalMedia': 'For full product details, consult the official label documentation.',
      },
      'Paracetamol': {
        'dosage': 'Take 500 mg every 4-6 hours as needed, not exceeding 3000 mg per day.',
        'ingredients': 'Active: Paracetamol 500 mg. Inactive ingredients as per product label.',
        'warnings': 'Overdose may cause liver damage. Follow the recommended dosing instructions.',
        'additionalMedia': 'Please refer to the official drug facts label for detailed information.',
      },
      'Gaviscon': {
        'dosage': 'Adults: 15-30 ml after meals and at bedtime. Shake well before use.',
        'ingredients': 'Active: Sodium alginate, potassium bicarbonate, sodium bicarbonate. Inactive ingredients as per product label.',
        'warnings': 'May cause bloating or gas. Do not exceed the recommended dose.',
        'additionalMedia': 'For full product details, consult the official label documentation.',
      },
    };

    final medicineDetail = detailsMap[productName] ?? {
      'dosage': 'No dosage information available.',
      'ingredients': 'No ingredients information available.',
      'warnings': 'No warnings information available.',
      'additionalMedia': '',
    };

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        double dialogWidth = MediaQuery.of(context).size.width * 0.9;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: MedicineDetailModal(
              productName: productName,
              amountStr: amountStr,
              imagePath: imagePath,
              stockCount: stockCount,
              dosage: medicineDetail['dosage']!,
              ingredients: medicineDetail['ingredients']!,
              warnings: medicineDetail['warnings']!,
              additionalMedia: medicineDetail['additionalMedia']!,
              onAddToCart: (int quantity) {
                Navigator.pop(context);
                _addToOrder(productName, amountStr, quantity);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleLarge = Theme.of(context).textTheme.titleLarge;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2A5E),
          automaticallyImplyLeading: false,
          title: Text(
            "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
            style: titleLarge?.copyWith(fontSize: 20, color: Colors.white),
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
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              if (_userName != widget.rfidData) ...[
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0D2A5E), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "VendoPoints: $_userPoints",
                        style: titleLarge?.copyWith(
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
              Text(
                "Your Orders:",
                style: titleLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                        child: Text(
                          '${index + 1}. $orderName (Qty: $orderQuantity) - ₱$orderPrice',
                          style: bodyMedium?.copyWith(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _resetOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      "RESET",
                      style: titleMedium?.copyWith(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      "CHECKOUT",
                      style: titleMedium?.copyWith(fontSize: 18, color: Colors.white),
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

  Widget _buildMedicineItem(String productName, String amountStr, String imagePath, int stockCount) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.18;
    bool isTapped = _isTapped[productName] ?? false;
    final titleLarge = Theme.of(context).textTheme.titleLarge;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;

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
          _openMedicineDetail(productName, amountStr, imagePath, stockCount);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Out of stock!"), backgroundColor: Colors.red),
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
                Image.asset(imagePath, height: imageHeight, fit: BoxFit.contain)
              else
                Container(
                  height: imageHeight,
                  alignment: Alignment.center,
                  child: Text("No image", style: bodyMedium?.copyWith(fontSize: 16, color: Colors.grey)),
                ),
              const SizedBox(height: 10),
              Text(
                productName,
                style: titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                '₱$amountStr',
                style: titleMedium?.copyWith(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Remaining: $stockCount pc/s',
                style: titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0D2A5E)),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Accepts the selected quantity from the detail modal.
  void _addToOrder(String productName, String unitPriceStr, int quantity) {
    final medicineIndex = medicines.indexWhere((m) => m['product_name'] == productName);
    if (medicineIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$productName not found in stock list."), backgroundColor: Colors.red),
      );
      return;
    }
    final int availableStock = medicines[medicineIndex]['count'] ?? 0;
    setState(() {
      final double unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
      final existingIndex = orders.indexWhere((item) => item['name'] == productName);
      if (existingIndex != -1) {
        final int currentQuantity = int.tryParse(orders[existingIndex]['quantity'] ?? '1') ?? 1;
        final int newQuantity = currentQuantity + quantity;
        if (newQuantity > 13) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Maximum of 13 pieces allowed for $productName."), backgroundColor: Colors.red),
          );
          return;
        }
        if (newQuantity > availableStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only $availableStock pieces available for $productName."), backgroundColor: Colors.red),
          );
          return;
        }
        final double newTotalPrice = unitPrice * newQuantity;
        orders[existingIndex]['quantity'] = newQuantity.toString();
        orders[existingIndex]['price'] = newTotalPrice.toStringAsFixed(2);
      } else {
        if (availableStock < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Out of stock!"), backgroundColor: Colors.red),
          );
          return;
        }
        orders.add({
          'name': productName,
          'quantity': quantity.toString(),
          'price': (unitPrice * quantity).toStringAsFixed(2),
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
    if (_userName == widget.rfidData) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            orders: orders,
            rfidData: widget.rfidData,
            medicinesToBeDisabled: const [],
          ),
        ),
      ).then((_) => setState(() => orders.clear()));
    } else {
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

class MedicineDetailModal extends StatefulWidget {
  final String productName;
  final String amountStr;
  final String imagePath;
  final int stockCount;
  final String dosage;
  final String ingredients;
  final String warnings;
  final String additionalMedia;
  final Function(int) onAddToCart;

  const MedicineDetailModal({
    Key? key,
    required this.productName,
    required this.amountStr,
    required this.imagePath,
    required this.stockCount,
    required this.dosage,
    required this.ingredients,
    required this.warnings,
    required this.additionalMedia,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _MedicineDetailModalState createState() => _MedicineDetailModalState();
}

class _MedicineDetailModalState extends State<MedicineDetailModal> {
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row and close icon.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.productName,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Price, Favorite Icon and Stock.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price with favorite icon beside it.
                Row(
                  children: [
                    Text(
                      'Price: ₱${widget.amountStr}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey,
                      ),
                      iconSize: 30,
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                    ),
                  ],
                ),
                // Stock.
                Text(
                  'In Stock: ${widget.stockCount}',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Enlarged Product Image.
            Center(
              child: widget.imagePath.isNotEmpty
                  ? Image.asset(widget.imagePath, height: 350, fit: BoxFit.contain)
                  : Text("No image", style: textTheme.bodyMedium?.copyWith(fontSize: 20)),
            ),
            const SizedBox(height: 12),
            // Enlarged Quantity Selector.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _quantity.toString(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_quantity < widget.stockCount) {
                      setState(() {
                        _quantity++;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Dosage Information.
            Text(
              "Dosage Information:",
              style: textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.dosage,
              style: textTheme.bodyMedium?.copyWith(fontSize: 20, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Ingredients.
            Text(
              "Ingredients:",
              style: textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ingredients,
              style: textTheme.bodyMedium?.copyWith(fontSize: 20, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Warnings & Side Effects.
            Text(
              "Warnings & Side Effects:",
              style: textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.warnings,
              style: textTheme.bodyMedium?.copyWith(fontSize: 20, height: 1.4),
            ),
            const SizedBox(height: 16),
            // Additional Information.
            if (widget.additionalMedia.isNotEmpty) ...[
              Text(
                "Additional Information:",
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.additionalMedia,
                style: textTheme.bodyMedium?.copyWith(fontSize: 20, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
            // Disclaimer.
            Text(
              "Information provided here is for reference only. Always consult a healthcare professional for medical advice.",
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onAddToCart(_quantity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E), // Navy blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Add to Cart"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800], // Dark grey
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
