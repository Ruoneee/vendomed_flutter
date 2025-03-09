import 'package:usb_serial/usb_serial.dart';

class USBService {
  // Singleton instance.
  static final USBService _instance = USBService._internal();
  factory USBService() => _instance;
  USBService._internal();

  UsbPort? _port;

  bool get isConnected => _port != null;
  UsbPort? get port => _port;

  /// Connects to the provided [device] and stores the open port.
  Future<void> connectToDevice(UsbDevice device) async {
    UsbPort? port = await device.create();
    if (port == null) {
      throw Exception('Failed to open port for ${device.productName}');
    }
    bool openResult = await port.open();
    if (!openResult) {
      throw Exception('Could not open port for ${device.productName}');
    }
    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(
      115200, // Typical baud rate for ESP32.
      8,      // Data bits.
      1,      // Stop bits.
      UsbPort.PARITY_NONE,
    );
    _port = port;
  }

  /// Disconnects from the current device.
  Future<void> disconnect() async {
    if (_port != null) {
      await _port!.close();
      _port = null;
    }
  }
}
