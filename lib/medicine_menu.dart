import 'package:flutter/material.dart';
import 'user_selection_screen.dart';
import 'payment_method.dart';
import 'payment.dart';
import 'database_helper.dart';
import 'dart:async';

// your two extracted widgets
import 'widgets/medicine_item.dart';
import 'widgets/medicine_detail_modal.dart';

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
  bool _isRegisteredUser = false;   // ← NEW FLAG
  List<Map<String, dynamic>> medicines = [];
  Timer? _stockUpdateTimer;

  // *** per‑day purchase caps ***
  final Map<String, int> _dailyLimits = {
    'Paracetamol': 4,
    'Ibuprofen': 2,
    'Cetirizine': 1,
    'Loperamide': 3,
    'Antacid': 3,
    'Buscopan': 2,
  };

  Map<String, int> _dailyPurchased = {}; // bought so far today

  // --- Extracted details maps ---
  static const Map<String, Map<String, String>> _medicineDetails = {
    'Ibuprofen': {
      'dosage': 'Adults: 200-400 mg every 4-6 hours as needed, max 3200 mg/day. Take with food.',
      'ingredients': 'Active: Ibuprofen 200 mg or 400 mg. Inactive: Colloidal silicon dioxide, croscarmellose sodium, magnesium stearate, etc.',
      'warnings': 'May cause stomach upset or bleeding. Avoid if allergic to NSAIDs, have ulcers, or severe kidney/liver disease.',
      'additionalMedia': 'Consult the FDA‑approved label or a healthcare provider for full details.',
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

  static const Map<String, String> _defaultDetail = {
    'dosage': 'No dosage information available.',
    'ingredients': 'No ingredients information available.',
    'warnings': 'No warnings information available.',
    'additionalMedia': '',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingOrders != null) {
      orders = List.from(widget.existingOrders!);
    }
    // first figure out if registered, then fetch everything else
    _loadUserNameAndPoints().then((_) {
      _fetchMedicines();
      _fetchDailyPurchasedCounts();
      _startStockListener();
    });
  }

  @override
  void dispose() {
    _stockUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStockListener() {
    _stockUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMedicines();
      _fetchDailyPurchasedCounts();
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
      if (!mounted) return;
      setState(() {
        if (result.isNotEmpty) {
          _isRegisteredUser = true;
          _userName = result.first['NAME']?.toString() ?? widget.rfidData;
          _userPoints = result.first['POINTS']?.toString() ?? '0';
        } else {
          _isRegisteredUser = false;
          _userName = widget.rfidData;
          _userPoints = '0';
        }
      });
    } catch (e) {
      debugPrint("Error loading user name/points: $e");
      if (!mounted) return;
      setState(() {
        _isRegisteredUser = false;
        _userName = widget.rfidData;
        _userPoints = '0';
      });
    }
  }

  Future<void> _fetchMedicines() async {
    try {
      final db = await DatabaseHelper().db;
      final results = await db.query('stocks');
      if (!mounted) return;
      setState(() {
        medicines = results.map((row) {
          // 1) safely convert to String
          final String name = row['product_name']?.toString() ?? 'Unknown';

          // 2) only if you still track tap state here:
          // _isTapped.putIfAbsent(name, () => false);
          return {
            'product_name': name,
            'amount':        row['amount']?.toString() ?? '0',
            'count':         int.tryParse(row['count']?.toString() ?? '0') ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching medicines: $e");
    }
  }


  Future<void> _fetchDailyPurchasedCounts() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (!_isRegisteredUser) {
      // guests have no cap
      if (!mounted) return;
      setState(() => _dailyPurchased = {});
      return;
    }
    try {
      final counts = await DatabaseHelper.instance.getDailyPurchaseCounts(
        rfid: widget.rfidData,
        date: today,
      );
      if (!mounted) return;
      setState(() => _dailyPurchased = counts);
    } catch (e) {
      debugPrint("Error fetching daily counts: $e");
    }
  }


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

  /// Opens a centered dialog with detailed product info and per‑day limits.
  void _openMedicineDetail(
      String productName,
      String amountStr,
      String imagePath,
      int displayStock,
      ) {
    final bought = _dailyPurchased[productName] ?? 0;
    final limit = _dailyLimits[productName] ?? 0;
    final dailyRemaining = _isRegisteredUser
        ? (limit - bought).clamp(0, limit)
        : displayStock;

    final medicineDetail = _medicineDetails[productName] ?? _defaultDetail;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          Dialog(
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            child: MedicineDetailModal(
              productName: productName,
              amountStr: amountStr,
              imagePath: imagePath,
              stockCount: displayStock,
              dosage: medicineDetail['dosage']!,
              ingredients: medicineDetail['ingredients']!,
              warnings: medicineDetail['warnings']!,
              additionalMedia: medicineDetail['additionalMedia']!,
              dailyRemaining: dailyRemaining,
              onAddToCart: (qty) {
                Navigator.pop(_);
                _addToOrder(productName, amountStr, qty);
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleLarge  = Theme.of(context).textTheme.titleLarge;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final bodyMedium  = Theme.of(context).textTheme.bodyMedium;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Welcome, ${_userName.isNotEmpty ? _userName : widget.rfidData}!",
            style: titleLarge?.copyWith(color: Colors.white, fontSize: 20),
          ),
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2A5E), Color(0xFF0D2A5E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2A5E), Color(0xFF1E5D6F)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              if (_isRegisteredUser)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFF0D2A5E), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
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

              // Your Orders header
              SliverPersistentHeader(
                pinned: true,
                delegate: OrdersHeaderDelegate(
                  height: 170,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D2A5E), Color(0xFF0D2A5E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Orders:",
                          style: titleLarge
                              ?.copyWith(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
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
                              itemBuilder: (ctx, i) {
                                final o = orders[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    "${i + 1}. ${o['name']} (Qty: ${o['quantity']}) – ₱${o['price']}",
                                    style: bodyMedium?.copyWith(fontSize: 16, color: Colors.black),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Remove Item'),
                                          content: Text('Remove ${o['name']} from your order?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                setState(() => orders.removeAt(i));
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('${o['name']} removed from your order.')),
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

              // Medicines grid or loader
              if (medicines.isEmpty)
                SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final m = medicines[index];
                        final name = m['product_name'] as String;
                        final stock = m['count'] as int;
                        final inCart = int.tryParse(
                          orders.firstWhere((o) => o['name'] == name, orElse: () => {'quantity': '0'})['quantity']!,
                        ) ?? 0;
                        final displayStock = (stock - inCart).clamp(0, stock);

                        return MedicineItem(
                          productName:      name,
                          amountStr:        m['amount'] as String,
                          imagePath:        _getImagePath(name),
                          stockCount:       displayStock,
                          isRegisteredUser: _isRegisteredUser,
                          purchasedToday:   _dailyPurchased[name] ?? 0,
                          dailyLimit:       _dailyLimits[name] ?? 0,
                          onTap: () => _openMedicineDetail(
                            name,
                            m['amount'] as String,
                            _getImagePath(name),
                            displayStock,
                          ), // <-- comma closes the onTap argument
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

                SliverToBoxAdapter(child: const SizedBox(height: 20)),

                // Row with RESET and CHECKOUT buttons.
              // Reset / Checkout buttons
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

              // final spacer
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

    // Accepts the selected quantity from the detail modal.
    void _addToOrder(String productName, String unitPriceStr, int quantity) {
      final medicineIndex =
      medicines.indexWhere((m) => m['product_name'] == productName);
      if (medicineIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("$productName not found in stock list."),
              backgroundColor: Colors.red),
        );
        return;
      }

      final int availableStock = medicines[medicineIndex]['count'] ?? 0;
      final double unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
      final existingIndex =
      orders.indexWhere((item) => item['name'] == productName);
      final int cartQty = existingIndex != -1
          ? int.parse(orders[existingIndex]['quantity']!)
          : 0;
      final int boughtToday = _dailyPurchased[productName] ?? 0;
      final int perDayLimit = _dailyLimits[productName] ?? 0;

      // stock check
      if (quantity + cartQty > availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Only $availableStock pieces available for $productName."),
              backgroundColor: Colors.red),
        );
        return;
      }

      // daily cap check (only for RFID users)
      if (_userName != widget.rfidData &&
          boughtToday + cartQty + quantity > perDayLimit) {
        final canBuy =
        (perDayLimit - boughtToday - cartQty).clamp(0, perDayLimit);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "You can only buy $canBuy more of $productName today."),
              backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() {
        // update dailyPurchased
        if (_userName != widget.rfidData) {
          _dailyPurchased[productName] = boughtToday + cartQty + quantity;
        }
        final newQty = cartQty + quantity;
        final newTotal = unitPrice * newQty;
        if (existingIndex != -1) {
          orders[existingIndex]['quantity'] = newQty.toString();
          orders[existingIndex]['price'] = newTotal.toStringAsFixed(2);
        } else {
          orders.add({
            'name': productName,
            'quantity': quantity.toString(),
            'price': newTotal.toStringAsFixed(2),
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

      // Copy so the payment screen can't mutate our original list
      final List<Map<String, String>> ordersCopy =
      List<Map<String, String>>.from(orders);

// Decide which page to push
      final MaterialPageRoute nextRoute = _isRegisteredUser
      // Registered (RFID) users pick their payment method
          ? MaterialPageRoute(
        builder: (_) =>
            PaymentMethodPage(
              orders: ordersCopy,
              rfidData: widget.rfidData,
            ),
      )
      // Guests go straight to the cash‐only page
          : MaterialPageRoute(
        builder: (_) =>
            PaymentPage(
              orders: ordersCopy,
              rfidData: widget.rfidData,
              medicinesToBeDisabled: const [],
            ),
      );

      // Push and then, when returning, clear cart & reload today's counts
      Navigator.push(context, nextRoute).then((_) {
        setState(() {
          orders.clear();
        });
        _fetchDailyPurchasedCounts();
      });
    }
  }

  class OrdersHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  OrdersHeaderDelegate({required this.height, required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
  child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant OrdersHeaderDelegate old) =>
  old.height != height || old.child != child;
  }