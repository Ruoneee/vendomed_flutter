import 'package:flutter/material.dart';

class MedicineItem extends StatefulWidget {
  final String      productName;
  final String      amountStr;
  final String      imagePath;
  final int         stockCount;
  final bool        isRegisteredUser;
  final int         purchasedToday;
  final int         dailyLimit;
  final VoidCallback onTap;

  const MedicineItem({
    Key? key,
    required this.productName,
    required this.amountStr,
    required this.imagePath,
    required this.stockCount,
    required this.isRegisteredUser,
    required this.purchasedToday,
    required this.dailyLimit,
    required this.onTap,
  }) : super(key: key);

  @override
  _MedicineItemState createState() => _MedicineItemState();
}

class _MedicineItemState extends State<MedicineItem> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    // how many this user can still buy today
    final int dailyRemaining = widget.isRegisteredUser
        ? (widget.dailyLimit - widget.purchasedToday).clamp(0, widget.dailyLimit)
        : widget.stockCount;

    // mark unavailable if out of stock or daily cap reached
    final bool unavailable =
        widget.stockCount == 0 || (widget.isRegisteredUser && dailyRemaining == 0);

    final titleLarge  = Theme.of(context).textTheme.titleLarge;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final bodyMedium  = Theme.of(context).textTheme.bodyMedium;

    return GestureDetector(
      onTapDown: (_) {
        if (!unavailable) setState(() => _isTapped = true);
      },
      onTapUp: (_) {
        if (unavailable) return;
        // show pressed effect briefly
        Future.delayed(
          const Duration(milliseconds: 150),
              () => setState(() => _isTapped = false),
        );
        widget.onTap();
      },
      onTapCancel: () {
        if (!unavailable) setState(() => _isTapped = false);
      },
      child: Opacity(
        opacity: unavailable ? 0.5 : 1.0,
        child: AnimatedScale(
          scale: _isTapped ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: unavailable ? Colors.grey[300] : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Spacer(),
                if (widget.imagePath.isNotEmpty)
                  Image.asset(
                    widget.imagePath,
                    height: MediaQuery.of(context).size.height * 0.18,
                    fit: BoxFit.contain,
                  )
                else
                  Container(
                    height: MediaQuery.of(context).size.height * 0.18,
                    alignment: Alignment.center,
                    child: Text(
                      "No image",
                      style: bodyMedium
                          ?.copyWith(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  widget.productName,
                  style: titleLarge
                      ?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '₱${widget.amountStr}',
                  style: titleMedium
                      ?.copyWith(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Remaining: ${widget.stockCount} pc/s',
                  style: titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.stockCount == 0
                        ? Colors.grey[600]
                        : const Color(0xFF0D2A5E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (widget.isRegisteredUser)
                  Text(
                    'Today Remaining: $dailyRemaining',
                    style: bodyMedium?.copyWith(
                      fontSize: 16,
                      color: dailyRemaining == 0
                          ? Colors.red
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
