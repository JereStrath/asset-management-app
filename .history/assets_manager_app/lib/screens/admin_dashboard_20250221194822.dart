import 'package:flutter/material.dart';
import '../services/user_service.dart';  // Updated path
import '../services/auth_service.dart'; 
 // Updated path

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Controls',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Manage Users'),
                onTap: () {
                  // TODO: Implement user management
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.inventory),
                title: Text('Manage Assets'),
                onTap: () {
                  // TODO: Implement asset management
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('View Reports'),
                onTap: () {
                  // TODO: Implement reports
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 