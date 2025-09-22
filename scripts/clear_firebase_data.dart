import 'dart:io';

/// Script to clear Firebase Realtime Database test/sample data
void main() async {
  print('🧹 Firebase Data Cleaner');
  print('=======================');
  
  print('\n⚠️  WARNING: This will clear test/sample data from Firebase!');
  print('Make sure you are targeting the correct Firebase project.');
  
  // Ask for confirmation
  print('\nType "CONFIRM" to proceed:');
  final input = stdin.readLineSync();
  
  if (input != 'CONFIRM') {
    print('❌ Operation cancelled');
    return;
  }
  
  print('\n🔥 Connecting to Firebase...');
  
  try {
    // Instructions for manual cleanup since we can't directly access Firebase from Dart script
    print('''
📋 Manual Firebase Cleanup Instructions:

1. 🌐 Go to Firebase Console:
   https://console.firebase.google.com/

2. 🎯 Select your project: iotsmart-7a145

3. 🗃️  Go to Realtime Database

4. 🧹 Clear the following nodes if they contain test data:
   • /devices (remove any test devices)
   • /sensorData (remove test sensor data)
   • /pendingDevices (remove any pending test devices)
   • /alerts (remove test alerts)
   • /test (remove test data)
   • /deviceRegistry (remove test device registrations)

5. 👥 In the users node:
   • Keep your real user accounts
   • Remove any test user accounts
   • Clear test devices from real users

6. 🔧 For each real user:
   • Go to users/{userId}/devices
   • Remove any test devices (ESP32-TEST, Demo devices, etc.)

Specific test data patterns to look for:
   • Device names containing "Test", "Demo", "Sample"
   • Device IDs like "ESP32-TEST123", "DEMO-DEVICE"
   • Old sensor data with fake readings
   • Pending devices from testing

⚠️  BE CAREFUL: Only delete test data, keep real user data!
    ''');
    
    print('\n✅ Instructions provided');
    print('Please follow the manual steps above to clean Firebase data');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
