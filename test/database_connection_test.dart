import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality/firebase_options.dart';

void main() {
  group('Database Connection Tests', () {
    test('should have correct database URL format for Asia Southeast region', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;

      // Check Android database URL
      expect(androidOptions.databaseURL, contains('asia-southeast1'));
      expect(androidOptions.databaseURL, contains('firebasedatabase.app'));
      expect(androidOptions.databaseURL, startsWith('https://'));
      expect(androidOptions.databaseURL, contains('iotsmart-7a145-default-rtdb'));

      // Check Web database URL
      expect(webOptions.databaseURL, contains('asia-southeast1'));
      expect(webOptions.databaseURL, contains('firebasedatabase.app'));
      expect(webOptions.databaseURL, startsWith('https://'));
      expect(webOptions.databaseURL, contains('iotsmart-7a145-default-rtdb'));

      print('✅ Database URLs are correctly configured for Asia Southeast region');
      print('Android DB URL: ${androidOptions.databaseURL}');
      print('Web DB URL: ${webOptions.databaseURL}');
    });

    test('should not use old firebaseio.com domain', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;

      // Ensure old domain is not used
      expect(androidOptions.databaseURL, isNot(contains('firebaseio.com')));
      expect(webOptions.databaseURL, isNot(contains('firebaseio.com')));

      print('✅ Old firebaseio.com domain is not used');
    });

    test('should have consistent database URLs across platforms', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;

      // Both should point to same database
      expect(androidOptions.databaseURL, equals(webOptions.databaseURL));

      print('✅ Database URLs are consistent across platforms');
    });

    test('should have valid URL structure', () {
      final databaseUrl = DefaultFirebaseOptions.android.databaseURL;

      // Parse URL to validate structure
      final uri = Uri.parse(databaseUrl!);
      
      expect(uri.scheme, equals('https'));
      expect(uri.host, contains('iotsmart-7a145-default-rtdb'));
      expect(uri.host, contains('asia-southeast1'));
      expect(uri.host, endsWith('firebasedatabase.app'));

      print('✅ Database URL structure is valid');
      print('Scheme: ${uri.scheme}');
      print('Host: ${uri.host}');
      print('Full URL: $databaseUrl');
    });

    test('should match expected region-specific URL pattern', () {
      final expectedUrl = 'https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app';
      final androidUrl = DefaultFirebaseOptions.android.databaseURL;
      final webUrl = DefaultFirebaseOptions.web.databaseURL;

      expect(androidUrl, equals(expectedUrl));
      expect(webUrl, equals(expectedUrl));

      print('✅ Database URLs match expected pattern');
    });
  });
}
