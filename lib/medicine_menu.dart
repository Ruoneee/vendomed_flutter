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
      debugPrint("Error loading user name/points: $e");
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
      debugPrint("Error fetching medicines: $e");
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
    };
    return imagePaths[productName] ?? '';
  }

  /// Opens a centered dialog with detailed product info.
  void _openMedicineDetail(String productName, String amountStr, String imagePath, int stockCount) {
    final Map<String, Map<String, String>> detailsMap = {
      'Ibuprofen': {
        'dosage': 'Adults: 200-400 mg every 4-6 hours as needed, max 3200 mg/day. Take with food.',
        'ingredients': 'Active: Ibuprofen 200 mg or 400 mg. Inactive: Colloidal silicon dioxide, croscarmellose sodium, magnesium stearate, etc.',
        'warnings': 'May cause stomach upset or bleeding. Avoid if allergic to NSAIDs, have ulcers, or severe kidney/liver disease.',
        'additionalMedia': 'Consult the FDA-approved label or a healthcare provider for full details.',
      },
      'Cetirizine': {
        'dosage': 'Adults and children over 6: 5-10 mg once daily. Adjust for kidney impairment.',
        'ingredients': 'Active: Cetirizine Hydrochloride 10 mg. Inactive: Lactose monohydrate, microcrystalline cellulose, etc.',
        'warnings': 'May cause drowsiness. Avoid alcohol. Not recommended if allergic to hydroxyzine.',
        'additionalMedia': 'Refer to product packaging or pharmacist for complete information.',
      },
      'Paracetamol': {
        'dosage': 'Adults: 500-1000 mg every 4-6 hours, max 4000 mg/day. Do not exceed recommended dose.',
        'ingredients': 'Active: Paracetamol (Acetaminophen) 500 mg. Inactive: Starch, povidone, etc.',
        'warnings': 'Overdose can cause liver damage. Avoid alcohol. Consult doctor if fever persists over 3 days.',
        'additionalMedia': 'See FDA guidelines or consult a healthcare professional.',
      },
      'Loperamide': {
        'dosage': 'Adults: 4 mg initially, then 2 mg after each loose stool, max 16 mg/day. Stop after 48 hours if no improvement.',
        'ingredients': 'Active: Loperamide Hydrochloride 2 mg. Inactive: Lactose, cornstarch, magnesium stearate, etc.',
        'warnings': 'May cause constipation or drowsiness. Do not use if diarrhea is bloody or with fever.',
        'additionalMedia': 'Refer to FDA label or Drugs.com for detailed usage instructions.',
      },
      'Antacid': {
        'dosage': 'Adults: 1-2 tablets as needed after meals or at bedtime, max 8 tablets/day (varies by brand).',
        'ingredients': 'Active: Calcium Carbonate 500 mg or Aluminum Hydroxide/Magnesium Hydroxide. Inactive: Sucrose, etc.',
        'warnings': 'May cause constipation or diarrhea. Avoid if on a low-sodium diet or with kidney issues.',
        'additionalMedia': 'Check specific product labeling for exact formulation and instructions.',
      },
      'Buscopan': {
        'dosage': 'Adults: 1-2 tablets (10 mg each) 3-4 times daily. Max 6 tablets/day. Swallow whole.',
        'ingredients': 'Active: Hyoscine Butylbromide 10 mg. Inactive: Sucrose, calcium hydrogen phosphate, etc.',
        'warnings': 'May cause dry mouth or blurred vision. Avoid if you have glaucoma or bowel obstruction.',
        'additionalMedia': 'See Patient.info or consult a pharmacist for full prescribing details.',
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
          elevation: 0,
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D2A5E),
                  Color(0xFF0D2A5E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D2A5E),
                Color(0xFF1E5D6F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: CustomScrollView(
            slivers: [
              // VendoPoints container (if user is not a guest).
              if (_userName != widget.rfidData)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
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
                  ),
                ),
              // Pinned "Your Orders" section (header + orders container).
              SliverPersistentHeader(
                pinned: true,
                delegate: OrdersHeaderDelegate(
                  height: 170, // Adjust to ensure no overflow
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0D2A5E),
                          Color(0xFF0D2A5E),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Orders:",
                          style: titleLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '${index + 1}. $orderName (Qty: $orderQuantity) - ₱$orderPrice',
                                    style: bodyMedium?.copyWith(fontSize: 16, color: Colors.black),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Item'),
                                          content: Text('Remove $orderName from your order?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  orders.removeAt(index);
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('$orderName removed from your order.'),
                                                  ),
                                                );
                                              },
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer after pinned orders.
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              // Medicines grid or loading indicator.
              if (medicines.isEmpty)
                SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12.0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final medicine = medicines[index];
                        return _buildMedicineItem(
                          medicine['product_name'] as String,
                          medicine['amount'] as String,
                          _getImagePath(medicine['product_name'] as String),
                          medicine['count'] as int,
                        );
                      },
                      childCount: medicines.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                  ),
                ),
              // Spacer.
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              // Row with RESET and CHECKOUT buttons.
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _resetOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A4D6F),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text(
                        "RESET",
                        style: titleMedium?.copyWith(fontSize: 22, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2A5E),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text(
                        "CHECKOUT",
                        style: titleMedium?.copyWith(fontSize: 22, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Spacer.
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
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
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No orders placed. Please add items to cart."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Map<String, String>> ordersCopy = List.from(orders);
    if (_userName == widget.rfidData) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            orders: ordersCopy,
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
            orders: ordersCopy,
            rfidData: widget.rfidData,
          ),
        ),
      ).then((_) => setState(() => orders.clear()));
    }
  }
}

class OrdersHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  OrdersHeaderDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant OrdersHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
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
                      backgroundColor: const Color(0xFF0D2A5E),
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
                      backgroundColor: Colors.grey[800],
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