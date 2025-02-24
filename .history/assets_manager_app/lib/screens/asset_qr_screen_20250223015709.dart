import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

class AssetQRScreen extends StatelessWidget {
  final String assetId;
  final String serialNumber;
  final String assetName;

  AssetQRScreen({
    required this.assetId,
    required this.serialNumber,
    required this.assetName,
  });

  Future<void> _printQRCode() async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: assetId,
                  width: 200,
                  height: 200,
                ),
                pw.SizedBox(height: 20),
                pw.Text(assetName),
                pw.Text('Asset ID: $assetId'),
                pw.Text('S/N: $serialNumber'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qr = Barcode.qrCode();
    final qrData = json.encode({
      'assetId': assetId,
      'serialNumber': serialNumber,
      'assetName': assetName,
    });
    final svg = qr.toSvg(qrData, width: 200, height: 200);

    return Scaffold(
      appBar: AppBar(
        title: Text('Asset QR Code'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printQRCode,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(svg),
            SizedBox(height: 20),
            Text(
              assetName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Asset ID: $assetId'),
            Text('S/N: $serialNumber'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.print),
              label: Text('Print QR Code'),
              onPressed: _printQRCode,
            ),
          ],
        ),
      ),
    );
  }
} 