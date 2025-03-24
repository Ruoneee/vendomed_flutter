import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

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

  // Buffer to accumulate incoming serial data
  String _incomingBuffer = "";

  // Flag to indicate that a reset is in progress.
  bool _isResetting = false;

  // StreamController to broadcast credit updates
  final StreamController<int> _creditController = StreamController<int>.broadcast();
  Stream<int> get creditStream => _creditController.stream;

  Future<void> initUSB() async {
    if (_isConnected) return; // Prevent reinitialization if already connected

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

      // Listen to incoming data from the ESP32
      _port!.inputStream?.listen((Uint8List data) {
        // Append incoming data to the buffer
        _incomingBuffer += String.fromCharCodes(data);

        // Check if the buffer contains a newline character
        if (_incomingBuffer.contains("\n")) {
          // Split the buffer into lines
          List<String> lines = _incomingBuffer.split("\n");
          // Process all complete lines except the last (which may be incomplete)
          for (int i = 0; i < lines.length - 1; i++) {
            String line = lines[i].trim();
            if (line.isNotEmpty) {
              int newCredit = int.tryParse(line) ?? 0;
              // If a reset is in progress, ignore nonzero updates.
              if (_isResetting && newCredit != 0) {
                print("Ignoring non-zero update while resetting: $newCredit");
              } else {
                print("Received credit from ESP32: $newCredit");
                _creditController.add(newCredit);
              }
            }
          }
          // Save the last part of the buffer (it may be incomplete) for future data
          _incomingBuffer = lines.last;
        }
      });
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

  /// Call this to reset the credit both locally and on the ESP32.
  Future<void> resetCredit() async {
    _isResetting = true;
    // Clear the local buffer to prevent processing any stale data
    _incomingBuffer = "";
    // Send a reset command (e.g., "R\n") to the ESP32.
    // (Make sure your ESP32 firmware resets its credit when it receives "R")
    if (_port != null && _isConnected) {
      Uint8List data = Uint8List.fromList("R\n".codeUnits);
      await _port!.write(data);
      print("Sent reset command to ESP32");
    }
    // Wait sufficiently long to allow the ESP32 to process the reset command.
    await Future.delayed(Duration(milliseconds: 1000));
    // Force a zero value update.
    _creditController.add(0);
    _isResetting = false;
  }

  void disconnectUSB() {
    _port?.close();
    _isConnected = false;
    print("Disconnected from USB");
  }

  bool isConnected() => _isConnected;
}
