import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String? scannedData;

  void _onQRCodeScanned(String data) {
    setState(() {
      scannedData = data;
    });
    // Navigate back or process the data
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: MobileScanner(
        onDetect: (barcode, args) {
          if (barcode.rawValue != null) {
            _onQRCodeScanned(barcode.rawValue!);
          }
        },
      ),
    );
  }
} 