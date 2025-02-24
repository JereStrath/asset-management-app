import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';
class QRCodeScreen extends StatelessWidget {
  final String data;

  QRCodeScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code')),
      body: Center(
        child: QrImage(
          data: data,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
} 