import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 Deploying Optimized Firebase Structure...');
  
  try {
    final rulesFile = File('firebase/optimized-database-rules.json');
    if (!rulesFile.existsSync()) {
      print('❌ Error: optimized-database-rules.json not found');
      exit(1);
    }
    
    final rulesContent = await rulesFile.readAsString();
    final rulesJson = jsonDecode(rulesContent);
    
    final outputFile = File('firebase.rules.json');
    const encoder = JsonEncoder.withIndent('  ');
    await outputFile.writeAsString(encoder.convert(rulesJson));
    
    print('✅ Firebase rules updated successfully');
    print('📋 Next steps:');
    print('   1. Deploy rules: firebase deploy --only database');
    print('   2. Update ESP32 code with optimized_air_monitor.ino');
    print('   3. Update Android app to use main_optimized.dart');
    print('   4. Test the integration');
    
    print('\n🔥 New Firebase Structure:');
    print('/air_monitor/');
    print('  ├── latest_data          // Real-time sensor data (5s updates)');
    print('  ├── history              // Historical data (5min intervals)');
    print('  ├── status               // Device status & heartbeat');
    print('  ├── control              // LED commands from app');
    print('  └── thresholds           // Alert thresholds');
    
    print('\n📱 Benefits:');
    print('  ✅ Simpler Firebase paths');
    print('  ✅ No user authentication required');
    print('  ✅ Reduced data usage');
    print('  ✅ Better performance');
    print('  ✅ Easier to maintain');
    
  } catch (e) {
    print('❌ Error deploying structure: $e');
    exit(1);
  }
}
