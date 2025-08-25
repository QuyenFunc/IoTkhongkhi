import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:air_quality/features/user/services/user_service.dart';
import 'package:air_quality/features/auth/services/auth_service.dart';
import 'package:air_quality/firebase_options.dart';

void main() {
  group('UserService Tests', () {
    late UserService userService;
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
      
      userService = UserService();
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

    test('should create user profile in database after registration', () async {
      final testEmail = 'userservice_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'User Service Test';

      print('🧪 Testing user profile creation for: $testEmail');

      try {
        // Register user (this should create profile in database)
        final userCredential = await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        );

        expect(userCredential.user, isNotNull);

        // Check if profile exists in database
        final profileExists = await userService.userProfileExists(userCredential.user!.uid);
        expect(profileExists, isTrue);

        // Get profile from database
        final profile = await userService.getCurrentUserProfile();
        expect(profile, isNotNull);
        expect(profile!.email, equals(testEmail));
        expect(profile.name, equals(testName));
        expect(profile.id, equals(userCredential.user!.uid));
        
        print('✅ User profile creation test passed');
      } catch (e) {
        print('❌ User profile creation test failed: $e');
        rethrow;
      }
    });

    test('should update user profile successfully', () async {
      final testEmail = 'update_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Update Test User';
      const updatedName = 'Updated Test User';
      const updatedPhone = '+84123456789';

      print('🧪 Testing user profile update');

      try {
        // Register user first
        await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        );

        // Update profile
        final updatedProfile = await userService.updateUserProfile(
          displayName: updatedName,
          phoneNumber: updatedPhone,
        );

        expect(updatedProfile.name, equals(updatedName));
        expect(updatedProfile.phoneNumber, equals(updatedPhone));

        // Verify update in database
        final profileFromDb = await userService.getCurrentUserProfile();
        expect(profileFromDb!.name, equals(updatedName));
        expect(profileFromDb.phoneNumber, equals(updatedPhone));
        
        print('✅ User profile update test passed');
      } catch (e) {
        print('❌ User profile update test failed: $e');
        rethrow;
      }
    });

    test('should sync user data correctly', () async {
      final testEmail = 'sync_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Sync Test User';

      print('🧪 Testing user data sync');

      try {
        // Register user
        await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        );

        // Run sync
        await userService.syncUserData();

        // Verify profile exists and is correct
        final profile = await userService.getCurrentUserProfile();
        expect(profile, isNotNull);
        expect(profile!.email, equals(testEmail));
        expect(profile.name, equals(testName));
        
        print('✅ User data sync test passed');
      } catch (e) {
        print('❌ User data sync test failed: $e');
        rethrow;
      }
    });

    test('should handle non-existent user profile gracefully', () async {
      print('🧪 Testing non-existent user profile handling');

      try {
        // Try to get profile when no user is signed in
        final profile = await userService.getCurrentUserProfile();
        expect(profile, isNull);
        
        print('✅ Non-existent user profile test passed');
      } catch (e) {
        print('❌ Non-existent user profile test failed: $e');
        rethrow;
      }
    });

    test('should validate user preferences defaults', () async {
      final testEmail = 'prefs_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      const testPassword = 'TestPassword123!';
      const testName = 'Preferences Test User';

      print('🧪 Testing user preferences defaults');

      try {
        // Register user
        await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          fullName: testName,
        );

        // Get profile and check default preferences
        final profile = await userService.getCurrentUserProfile();
        expect(profile, isNotNull);
        
        final prefs = profile!.preferences;
        expect(prefs.language, equals('vi'));
        expect(prefs.theme, equals('system'));
        expect(prefs.notificationsEnabled, isTrue);
        expect(prefs.dataRefreshInterval, equals(30));
        
        print('✅ User preferences defaults test passed');
      } catch (e) {
        print('❌ User preferences defaults test failed: $e');
        rethrow;
      }
    });
  });
}
