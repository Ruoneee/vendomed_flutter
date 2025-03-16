import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';

class USBHelper {
  static final USBHelper _instance = USBHelper._internal();
  factory USBHelper() => _instance;

  USBHelper._internal();

  UsbPort? _port;
  UsbDevice? _device;
  bool _isConnected = false;

  final Map<String, String> medicineMap = {
    "Paracetamol": "1",
    "Ibuprofen": "2",
    "Loperamide": "3",
    "Buscopan": "4",
    "Antacid": "5",
    "Cetirizine": "6",
  };

  Future<void> initUSB() async {
    if (_isConnected) return; // ✅ Prevent reinitialization if already connected

    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isNotEmpty) {
      _device = devices.first;
      await _connectToDevice(_device!);
    } else {
      print("No USB devices found");
    }

    UsbSerial.usbEventStream!.listen((UsbEvent event) async {
      print("USB Event: ${event.event}");
      if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
        await initUSB();
      } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
        disconnectUSB();
      }
    });
  }

  Future<void> _connectToDevice(UsbDevice device) async {
    _port = await device.create();
    if (await _port?.open() ?? false) {
      _port!.setDTR(true);
      _port!.setRTS(true);
      _port!.setPortParameters(115200, 8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
      _isConnected = true;
      print("Connected to ESP32 via USB");
    } else {
      print("Failed to open port");
    }
  }

  Future<void> sendOrdersToESP32(List<Map<String, String>> orders) async {
    if (!_isConnected || _port == null) {
      print("ESP32 is not connected via USB");
      return;
    }

    for (var order in orders) {
      String medicineName = order['name'] ?? "Unknown";
      int quantity = int.tryParse(order['quantity'] ?? "1") ?? 1;

      if (medicineMap.containsKey(medicineName)) {
        String espCommand = medicineMap[medicineName]!;

        for (int i = 0; i < quantity; i++) {
          Uint8List data = Uint8List.fromList(espCommand.codeUnits);
          await _port!.write(data);
          print("Sent command to ESP32: $espCommand for $medicineName");
          await Future.delayed(Duration(milliseconds: 500));
        }
      } else {
        print("Medicine not recognized: $medicineName");
      }
    }
  }

  void disconnectUSB() {
    _port?.close();
    _isConnected = false;
    print("Disconnected from USB");
  }

  bool isConnected() => _isConnected;
}
