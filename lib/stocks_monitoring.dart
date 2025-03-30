import 'dart:async';
import 'dart:typed_data';
import 'database_helper.dart';
import 'usb_helper.dart';

class StocksMonitoring {
  static final StocksMonitoring _instance = StocksMonitoring._internal();
  factory StocksMonitoring() => _instance;
  StocksMonitoring._internal();

  Timer? _monitorTimer;
  final Set<String> _notifiedWarnings = {}; // To prevent duplicate alerts

  void start() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStocks());
    print("Stock monitoring started.");
  }

  void stop() {
    _monitorTimer?.cancel();
    print("Stock monitoring stopped.");
  }

  Future<void> _checkStocks() async {
    final stockList = await DatabaseHelper.instance.getAllStocks();

    for (final stock in stockList) {
      final productName = stock['product_name'] as String;
      final count = stock['count'] ?? 0;
      print("Checking $productName: count=$count");

      if (count == 5 && !_notifiedWarnings.contains('${productName}_5')) {
        _sendStockWarning(productName, low: true);
        _notifiedWarnings.add('${productName}_5');
      } else if (count == 0 && !_notifiedWarnings.contains('${productName}_0')) {
        _sendStockWarning(productName, low: false);
        _notifiedWarnings.add('${productName}_0');
      }
    }
  }

  void _sendStockWarning(String productName, {required bool low}) {
    final Map<String, String> commandMap = {
      "Paracetamol": low ? "A" : "B",
      "Ibuprofen": low ? "C" : "D",
      "Loperamide": low ? "E" : "F",
      "Cetirizine": low ? "G" : "H",
      "Antacid": low ? "I" : "J",
      "Buscopan": low ? "K" : "L",
    };

    final command = commandMap[productName];
    if (command != null && USBHelper().isConnected()) {
      USBHelper().sendRawCommand(command);
      print("[StocksMonitoring] Sent command '$command' for $productName");
    } else {
      print("[StocksMonitoring] Skipped: USB not connected or unknown product '$productName'");
    }
  }
}
