import 'package:flutter/material.dart';

class MedicineItem extends StatelessWidget {
  final String productName;
  final String amountStr;
  final String imagePath;
  final int displayStock;
  final int dailyRemaining;
  final bool isRegisteredUser;
  final bool isTapped;
  final VoidCallback onTap;
  final VoidCallback onTapCancel;
  final ValueChanged<bool> onTapDown;

  const MedicineItem({
    Key? key,
    required this.productName,
    required this.amountStr,
    required this.imagePath,
    required this.displayStock,
    required this.dailyRemaining,
    required this.isRegisteredUser,
    required this.isTapped,
    required this.onTap,
    required this.onTapDown,
    required this.onTapCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleLarge  = Theme.of(context).textTheme.titleLarge;
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    final bodyMedium  = Theme.of(context).textTheme.bodyMedium;

    return GestureDetector(
      onTapDown: (_)   => onTapDown(true),
      onTapUp:   (_)   { Future.delayed(const Duration(milliseconds:150), () => onTapCancel()); onTap(); },
      onTapCancel:     onTapCancel,
      child: AnimatedScale(
        scale: isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds:150),
        child: Container(
          decoration: BoxDecoration(
            color: (isRegisteredUser && dailyRemaining == 0)
                ? Colors.grey[300]
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Spacer(),
              if (imagePath.isNotEmpty)
                Image.asset(imagePath, height: MediaQuery.of(context).size.height * .18, fit: BoxFit.contain)
              else
                Container(
                  height: MediaQuery.of(context).size.height * .18,
                  alignment: Alignment.center,
                  child: Text("No image", style: bodyMedium?.copyWith(fontSize:16, color:Colors.grey)),
                ),
              const SizedBox(height:10),
              Text(productName,
                  style: titleLarge?.copyWith(fontSize:24, fontWeight:FontWeight.bold),
                  textAlign: TextAlign.center),
              Text('₱$amountStr',
                  style: titleMedium?.copyWith(fontSize:18, color:Colors.black54),
                  textAlign: TextAlign.center),
              const SizedBox(height:6),
              Text('Remaining: $displayStock pc/s',
                  style: titleMedium?.copyWith(fontSize:20, fontWeight:FontWeight.bold, color:Color(0xFF0D2A5E)),
                  textAlign: TextAlign.center),
              const SizedBox(height:6),
              if (isRegisteredUser)
                Text('Today Remaining: $dailyRemaining',
                    style: bodyMedium?.copyWith(
                      fontSize:16,
                      color: dailyRemaining==0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    )),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
