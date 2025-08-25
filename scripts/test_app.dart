import 'dart:io';

void main() async {
  print('🚀 Testing Flutter app...');
  
  try {
    // Test 1: Check if emulator is running
    print('\n📱 Checking Android emulator...');
    final emulatorResult = await Process.run('flutter', ['devices']);
    
    if (emulatorResult.stdout.toString().contains('emulator')) {
      print('✅ Android emulator is running');
    } else {
      print('❌ No Android emulator found');
      print('Please start an Android emulator first');
      return;
    }
    
    // Test 2: Run flutter doctor
    print('\n🩺 Running flutter doctor...');
    final doctorResult = await Process.run('flutter', ['doctor', '--verbose']);
    
    if (doctorResult.exitCode == 0) {
      print('✅ Flutter doctor passed');
    } else {
      print('⚠️ Flutter doctor has issues:');
      print(doctorResult.stdout);
    }
    
    // Test 3: Build APK to test Android configuration
    print('\n🔨 Building APK to test Android configuration...');
    final buildResult = await Process.run('flutter', ['build', 'apk', '--debug']);
    
    if (buildResult.exitCode == 0) {
      print('✅ APK build successful');
    } else {
      print('❌ APK build failed:');
      print(buildResult.stderr);
      return;
    }
    
    // Test 4: Run tests
    print('\n🧪 Running tests...');
    final testResult = await Process.run('flutter', ['test']);
    
    if (testResult.exitCode == 0) {
      print('✅ All tests passed');
    } else {
      print('❌ Some tests failed:');
      print(testResult.stdout);
    }
    
    print('\n🎉 App testing completed!');
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
