import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const projectId = 'iotsmart-7a145';
  
  try {
    // Read rules file
    final rulesFile = File('firebase/optimized-database-rules.json');
    if (!rulesFile.existsSync()) {
      print('❌ Rules file not found: firebase/optimized-database-rules.json');
      return;
    }
    
    final rulesContent = await rulesFile.readAsString();
    final rules = jsonDecode(rulesContent);
    
    print('📋 Deploying Firebase Database Rules...');
    print('Project: $projectId');
    
    // This would require Firebase Admin SDK or REST API with proper authentication
    // For now, just validate the rules JSON
    print('✅ Rules JSON is valid');
    print('📄 Rules content:');
    print(JsonEncoder.withIndent('  ').convert(rules));
    
    print('\n🔧 To deploy these rules:');
    print('1. Go to Firebase Console: https://console.firebase.google.com/project/$projectId/database/iotsmart-7a145-default-rtdb/rules');
    print('2. Copy and paste the rules from firebase/optimized-database-rules.json');
    print('3. Click "Publish"');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
