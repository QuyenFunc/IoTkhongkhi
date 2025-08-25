import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:air_quality/features/auth/services/auth_service.dart';
import 'package:air_quality/firebase_options.dart';

void main() {
  group('Authentication Tests', () {
    late AuthService authService;

    setUpAll(() async {
      // Initialize Flutter binding for testing
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase for testing
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized for testing');
      } catch (e) {
        print('⚠️ Firebase already initialized: $e');
      }

      authService = AuthService();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
          print('🧹 Test user deleted: ${user.email}');
        }
      } catch (e) {
        print('⚠️ Error cleaning up test user: $e');
      }
    });

    test('should register new user successfully', () async {
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Test User';

      print('🧪 Testing registration with email: $testEmail');

      try {
        final userCredential = await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        );

        expect(userCredential.user, isNotNull);
        expect(userCredential.user!.email, equals(testEmail));
        expect(userCredential.user!.displayName, equals(testName));
        
        print('✅ Registration test passed');
      } catch (e) {
        print('❌ Registration test failed: $e');
        rethrow;
      }
    });

    test('should fail registration with invalid email', () async {
      const invalidEmail = 'invalid-email';
      const testPassword = 'TestPassword123!';
      const testName = 'Test User';

      print('🧪 Testing registration with invalid email: $invalidEmail');

      expect(
        () async => await authService.registerWithEmailAndPassword(
          email: invalidEmail,
          password: testPassword,
          fullName: testName,
        ),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Invalid email test passed');
    });

    test('should fail registration with weak password', () async {
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const weakPassword = '123';
      const testName = 'Test User';

      print('🧪 Testing registration with weak password');

      expect(
        () async => await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: weakPassword,
          fullName: testName,
        ),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Weak password test passed');
    });

    test('should fail registration with duplicate email', () async {
      final testEmail = 'duplicate_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Test User';

      print('🧪 Testing duplicate email registration');

      // First registration should succeed
      await authService.registerWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        fullName: testName,
      );

      // Second registration with same email should fail
      expect(
        () async => await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        ),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Duplicate email test passed');
    });

    test('should login with valid credentials', () async {
      final testEmail = 'login_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Test User';

      print('🧪 Testing login with valid credentials');

      // First register a user
      await authService.registerWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
        fullName: testName,
      );

      // Sign out
      await authService.signOut();

      // Then try to login
      final userCredential = await authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, equals(testEmail));
      
      print('✅ Login test passed');
    });

    test('should fail login with invalid credentials', () async {
      const invalidEmail = 'nonexistent@example.com';
      const invalidPassword = 'WrongPassword123!';

      print('🧪 Testing login with invalid credentials');

      expect(
        () async => await authService.signInWithEmailAndPassword(
          email: invalidEmail,
          password: invalidPassword,
        ),
        throwsA(isA<Exception>()),
      );
      
      print('✅ Invalid credentials test passed');
    });
  });
}
