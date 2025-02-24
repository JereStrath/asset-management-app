import 'package:flutter/material.dart';
import '../models/asset.dart';

class AssetDetailsScreen extends StatelessWidget {
  final Asset asset;

  const AssetDetailsScreen({Key? key, required this.asset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset Details'),
      ),
      body: Center(
        child: Text('Asset Details Screen - Coming Soon'),
      ),
    );
  }
}
