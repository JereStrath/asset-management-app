import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class ScanAssetScreen extends StatefulWidget {
  @override
  _ScanAssetScreenState createState() => _ScanAssetScreenState();
}

class _ScanAssetScreenState extends State<ScanAssetScreen> {
  String? barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Asset'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String code = barcodes.first.rawValue ?? '';
                  setState(() {
                    barcode = code;
                  });
                  print('Barcode found! $code');
                }
              },
            ),
          ),
          if (barcode != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Scanned Code: $barcode'),
            ),
        ],
      ),
    );
  }
}