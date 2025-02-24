import 'package:flutter/material.dart';
import 'qr_code_screen.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _scanQRCode(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScreen()),
    );

    if (result != null) {
      // Process the result and prefill the table
      debugPrint('Scanned QR Code: $result');
      // Update your table with the scanned data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _scanQRCode(context),
          child: const Text('Scan QR Code'),
        ),
      ),
    );
  }
} 