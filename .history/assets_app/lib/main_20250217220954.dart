import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(AssetsApp());
}

class AssetsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assets App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('assets.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE assets (id INTEGER PRIMARY KEY, name TEXT, description TEXT)'
        );
      },
    );
  }

  Future<void> insertAsset(Map<String, dynamic> asset) async {
    final db = await instance.database;
    await db.insert('assets', asset);
  }

  Future<List<Map<String, dynamic>>> fetchAssets() async {
    final db = await instance.database;
    return await db.query('assets');
  }
}

class ImportAssetsScreen extends StatefulWidget {
  @override
  _ImportAssetsScreenState createState() => _ImportAssetsScreenState();
}

class _ImportAssetsScreenState extends State<ImportAssetsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      await DatabaseHelper.instance.insertAsset({
        'name': nameController.text,
        'description': descriptionController.text,
      });
      nameController.clear();
      descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Asset Saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Import Assets')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Asset Name'),
                validator: (value) => value!.isEmpty ? 'Enter Asset Name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Asset Description'),
                validator: (value) => value!.isEmpty ? 'Enter Asset Description' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAsset,
                child: Text('Import Asset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckAssetsScreen extends StatefulWidget {
  @override
  _CheckAssetsScreenState createState() => _CheckAssetsScreenState();
}

class _CheckAssetsScreenState extends State<CheckAssetsScreen> {
  List<Map<String, dynamic>> assets = [];

  void _loadAssets() async {
    final data = await DatabaseHelper.instance.fetchAssets();
    setState(() {
      assets = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check Assets')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(assets[index]['name']),
                    subtitle: Text(assets[index]['description']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectAssetsScreen extends StatefulWidget {
  @override
  _CollectAssetsScreenState createState() => _CollectAssetsScreenState();
}

class _CollectAssetsScreenState extends State<CollectAssetsScreen> {
  String scannedSerial = '';

  Future<void> _scanQR() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      scannedSerial = result.rawContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Collect Assets')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Scanned Serial: $scannedSerial'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _scanQR,
              child: Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
