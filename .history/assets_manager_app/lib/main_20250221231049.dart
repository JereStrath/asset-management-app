import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';  // Updated path
import 'screens/auth/register_screen.dart';  // Updated path
import 'screens/home_screen.dart';
import 'screens/asset_categories_screen.dart';
import 'screens/asset_management_screen.dart';
import 'screens/maintenance_schedule_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/search_screen.dart';
import 'screens/asset_details_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: AuthenticationWrapper(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/categories': (context) => AssetCategoriesScreen(),
        '/assets': (context) => AssetManagementScreen(),
        '/maintenance': (context) => MaintenanceScheduleScreen(assetId: '', assetName: ''),
        '/reports': (context) => ReportsScreen(),
        '/users': (context) => UserManagementScreen(),
        '/search': (context) => SearchScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          return HomeScreen();
        }
        
        return LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/categories');
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Assets'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assets');
              },
            ),
            ListTile(
              leading: Icon(Icons.build),
              title: Text('Maintenance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/maintenance');
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('User Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/users');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Implement settings navigation
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            'Categories',
            Icons.category,
            '/categories',
            Colors.blue,
          ),
          _buildMenuCard(
            context,
            'Assets',
            Icons.inventory,
            '/assets',
            Colors.green,
          ),
          _buildMenuCard(
            context,
            'Maintenance',
            Icons.build,
            '/maintenance',
            Colors.orange,
          ),
          _buildMenuCard(
            context,
            'Reports',
            Icons.assessment,
            '/reports',
            Colors.purple,
          ),
          _buildMenuCard(
            context,
            'Users',
            Icons.people,
            '/users',
            Colors.red,
          ),
          _buildMenuCard(
            context,
            'Search',
            Icons.search,
            '/search',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      String route, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 