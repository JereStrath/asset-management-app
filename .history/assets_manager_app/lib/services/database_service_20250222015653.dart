import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static Future<void> initializeDatabase() async {
    // Initialize local database
    await Hive.initFlutter();
    // Register adapters and open boxes
  }

  static Future<void> saveDataLocally(String key, dynamic data) async {
    final box = await Hive.openBox('offlineData');
    await box.put(key, data);
  }

  static Future<dynamic> getLocalData(String key) async {
    final box = await Hive.openBox('offlineData');
    return box.get(key);
  }
} 