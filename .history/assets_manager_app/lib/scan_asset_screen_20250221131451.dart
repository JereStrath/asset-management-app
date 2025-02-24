import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';

class ScanAssetScreen extends StatelessWidget {
  Future<void> scanBarcode(BuildContext context) async {
    try {
      String barcode = await BarcodeScanner.scan();
      // Handle the scanned barcode (e.g., fetch asset details from Firestore)
      print("Scanned barcode: $barcode");
    } catch (e) {
      print("Error scanning barcode: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Asset')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => scanBarcode(context),
          child: Text('Scan Barcode/QR Code'),
        ),
      ),
    );
  }
}
