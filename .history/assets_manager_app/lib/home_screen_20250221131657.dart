import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'scan_asset_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset Management')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to scan asset screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanAssetScreen()),
                );
              },
              child: Text('Scan Asset'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                // Navigate to login screen
              },
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
