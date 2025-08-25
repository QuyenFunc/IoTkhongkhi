import 'dart:io';

void main(List<String> args) async {
  print('🔒 Firebase Database Rules Deployment');
  
  final environment = args.isNotEmpty ? args[0] : 'dev';
  
  if (environment != 'dev' && environment != 'prod') {
    print('❌ Invalid environment. Use: dev or prod');
    exit(1);
  }
  
  print('📝 Environment: $environment');
  
  try {
    // Check if Firebase CLI is installed
    print('\n🔍 Checking Firebase CLI...');
    final cliResult = await Process.run('firebase', ['--version']);
    
    if (cliResult.exitCode != 0) {
      print('❌ Firebase CLI not found. Please install it first:');
      print('npm install -g firebase-tools');
      exit(1);
    }
    
    print('✅ Firebase CLI found');
    
    // Check if logged in
    print('\n🔐 Checking Firebase login...');
    final loginResult = await Process.run('firebase', ['projects:list']);
    
    if (loginResult.exitCode != 0) {
      print('❌ Not logged in to Firebase. Please run:');
      print('firebase login');
      exit(1);
    }
    
    print('✅ Firebase login verified');
    
    // Deploy rules
    final rulesFile = environment == 'dev' 
        ? 'firebase/database.rules.dev.json'
        : 'firebase/database.rules.json';
    
    print('\n🚀 Deploying database rules from: $rulesFile');
    
    // Copy rules file to firebase.json location
    final sourceFile = File(rulesFile);
    final targetFile = File('database.rules.json');
    
    if (!sourceFile.existsSync()) {
      print('❌ Rules file not found: $rulesFile');
      exit(1);
    }
    
    await sourceFile.copy(targetFile.path);
    print('📋 Rules file copied');
    
    // Deploy
    final deployResult = await Process.run('firebase', [
      'deploy',
      '--only',
      'database',
      '--project',
      'iotsmart-7a145'
    ]);
    
    if (deployResult.exitCode == 0) {
      print('✅ Database rules deployed successfully!');
      print(deployResult.stdout);
    } else {
      print('❌ Deployment failed:');
      print(deployResult.stderr);
      exit(1);
    }
    
    // Clean up
    if (targetFile.existsSync()) {
      await targetFile.delete();
    }
    
    print('\n🎉 Rules deployment completed!');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
