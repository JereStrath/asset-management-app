import 'package:flutter/material.dart';
import 'user_service.dart';
import 'auth_service.dart';

class AdminDashboard extends StatelessWidget {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['email']),
                subtitle: Text('Role: ${user['role']}'),
                trailing: DropdownButton<String>(
                  value: user['role'],
                  items: <String>['admin', 'editor', 'viewer']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _userService.setUserRole(user['id'], newValue);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 