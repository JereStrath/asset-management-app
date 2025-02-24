import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose(); // Dispose of the camera controller
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop(); // Stop the camera when the app is not active
    } else if (state == AppLifecycleState.resumed) {
      _controller.start(); // Restart the camera when the app resumes
    }
  }

  void _onQRCodeScanned(String data) {
    setState(() {
      // Handle the scanned data
    });
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (barcode, args) {
          if (barcode.rawValue != null) {
            _onQRCodeScanned(barcode.rawValue!);
          }
        },
      ),
    );
  }
} 