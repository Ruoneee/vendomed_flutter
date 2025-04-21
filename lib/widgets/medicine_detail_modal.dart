import 'package:flutter/material.dart';

class MedicineDetailModal extends StatefulWidget {
  final String productName;
  final String amountStr;
  final String imagePath;
  final int stockCount;
  final String dosage;
  final String ingredients;
  final String warnings;
  final String additionalMedia;
  final int dailyRemaining;
  final void Function(int) onAddToCart;

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
    required this.dailyRemaining,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _MedicineDetailModalState createState() => _MedicineDetailModalState();
}

class _MedicineDetailModalState extends State<MedicineDetailModal> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final bodyMedium = theme.textTheme.bodyMedium;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(widget.productName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize:26, fontWeight:FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height:12),
            // price & stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price: ₱${widget.amountStr}', style: bodyMedium?.copyWith(fontSize:20)),
                Text('In Stock: ${widget.stockCount}', style: bodyMedium?.copyWith(fontSize:20)),
              ],
            ),
            const SizedBox(height:12),
            // image
            if (widget.imagePath.isNotEmpty)
              Center(child: Image.asset(widget.imagePath, height:350, fit:BoxFit.contain))
            else
              Center(child: Text("No image", style:bodyMedium?.copyWith(fontSize:20))),
            const SizedBox(height:12),
            // daily cap
            if (widget.dailyRemaining < widget.stockCount)
              Text("You can add up to ${widget.dailyRemaining} pcs today.",
                  style: bodyMedium?.copyWith(fontSize:18, fontWeight:FontWeight.w500)),
            const SizedBox(height:12),
            // quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize:36,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantity>1 ? () => setState(()=> _quantity--) : null,
                ),
                Text('$_quantity',
                    style: bodyMedium?.copyWith(fontSize:28, fontWeight:FontWeight.bold)),
                IconButton(
                  iconSize:36,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _quantity < widget.stockCount && _quantity < widget.dailyRemaining
                      ? () => setState(()=> _quantity++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height:20),
            // dosage, ingredients, warnings...
            _section("Dosage Information:", widget.dosage, theme, bodyMedium),
            _section("Ingredients:", widget.ingredients, theme, bodyMedium),
            _section("Warnings & Side Effects:", widget.warnings, theme, bodyMedium),
            if (widget.additionalMedia.isNotEmpty)
              _section("Additional Information:", widget.additionalMedia, theme, bodyMedium),
            const SizedBox(height:24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onAddToCart(_quantity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2A5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical:20),
                      textStyle: const TextStyle(fontSize:20, fontWeight:FontWeight.bold),
                    ),
                    child: const Text("Add to Cart"),
                  ),
                ),
                const SizedBox(width:12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical:20),
                      textStyle: const TextStyle(fontSize:20, fontWeight:FontWeight.bold),
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

  Widget _section(String title, String content, ThemeData theme, TextStyle? style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontSize:22, fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        Text(content, style: style?.copyWith(fontSize:20, height:1.4)),
        const SizedBox(height:16),
      ],
    );
  }
}
