import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../lib/firebase_options.dart';

void main() async {
  print('🗑️ Clearing old Firebase data...');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final database = FirebaseDatabase.instance;
    
    print('📋 Current Firebase structure:');
    final snapshot = await database.ref().get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.keys.forEach((key) {
        print('  - $key');
      });
    }
    
    print('\n⚠️ This will delete ALL data except /air_monitor/');
    print('Press Enter to continue or Ctrl+C to cancel...');
    stdin.readLineSync();
    
    final pathsToDelete = [
      'alerts',
      'commands', 
      'deviceRegistry',
      'devices',
      'pendingDevices',
      'sensorData',
      'users',
    ];
    
    for (final path in pathsToDelete) {
      print('🗑️ Deleting /$path...');
      await database.ref(path).remove();
    }
    
    print('\n✅ Old data cleared successfully!');
    print('📋 Remaining structure:');
    final remainingSnapshot = await database.ref().get();
    if (remainingSnapshot.exists) {
      final data = remainingSnapshot.value as Map<dynamic, dynamic>;
      data.keys.forEach((key) {
        print('  - $key');
      });
    } else {
      print('  (empty)');
    }
    
    print('\n🚀 Now you can:');
    print('1. Upload ESP32 code: esp32/optimized_air_monitor.ino');
    print('2. Run Android app: flutter run');
    print('3. ESP32 will create /air_monitor/ structure automatically');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
