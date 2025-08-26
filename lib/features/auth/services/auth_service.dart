import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/user_model.dart';


class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializePlatformSpecific();
  }

  // Platform-specific initialization
  void _initializePlatformSpecific() {
    if (kDebugMode) {
      print('Initializing AuthService for platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    }

    // Configure Firebase Auth settings
    _auth.setSettings(
      appVerificationDisabledForTesting: kDebugMode,
      forceRecaptchaFlow: false,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Configure for both web and Android
    scopes: ['email', 'profile'],
    // Web client ID will be automatically used on web
    // Android will use the one from google-services.json
  );

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Generate unique user key for device pairing
  String _generateUserKey() {
    // Generate a UUID-based user key with prefix for easy identification
    return 'USR_${_uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase()}';
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('Starting registration for email: $email');
      }

      // Create user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('User account created successfully: ${userCredential.user?.uid}');
      }

      // Update display name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        // Reload user to get updated displayName
        await userCredential.user!.reload();
        if (kDebugMode) {
          print('Display name updated: $fullName');
          print('Current displayName: ${userCredential.user!.displayName}');
        }
      }

      // Create user profile in database
      if (userCredential.user != null) {
        await _createUserProfile(
          user: userCredential.user!,
          fullName: fullName,
          phoneNumber: phoneNumber,
        );
        if (kDebugMode) {
          print('User profile created in database');
        }
      }

      if (kDebugMode) {
        print('Registration completed successfully');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
      }
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign-In process...');
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Đăng nhập Google bị hủy');
      }

      if (kDebugMode) {
        print('Google user signed in: ${googleUser.email}');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Không thể lấy token từ Google');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('Signing in to Firebase with Google credential...');
      }

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('Firebase sign-in successful: ${userCredential.user?.email}');
      }

      // Check if this is a new user and create profile
      if (userCredential.additionalUserInfo?.isNewUser == true && userCredential.user != null) {
        await _createUserProfile(
          user: userCredential.user!,
          fullName: userCredential.user!.displayName ?? 'Người dùng',
          phoneNumber: userCredential.user!.phoneNumber,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      throw Exception('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Gửi email đặt lại mật khẩu thất bại: ${e.toString()}');
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile({
    required User user,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('Creating user profile for: ${user.uid}');
      }

      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: fullName,
        phoneNumber: phoneNumber,
        profileImageUrl: user.photoURL,
        userKey: _generateUserKey(), // Generate unique key for device pairing
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: user.emailVerified,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Manually serialize to ensure UserPreferences is properly converted
      final userJson = userModel.toJson();
      userJson['preferences'] = userModel.preferences.toJson();

      await _database
          .ref('users/${user.uid}')
          .set(userJson);

      if (kDebugMode) {
        print('User profile created successfully in database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating user profile: $e');
        print('Stack trace: ${StackTrace.current}');
      }

      // This is critical - if profile creation fails, we should know about it
      throw Exception('Tạo hồ sơ người dùng thất bại: ${e.toString()}');
    }
  }

  // Get user profile from database
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId').get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Fix for old users without userKey - generate and update
        if (userData['userKey'] == null || userData['userKey'].toString().isEmpty) {
          final newUserKey = _generateUserKey();
          userData['userKey'] = newUserKey;
          
          // Update user in database with new userKey
          await _database.ref('users/$userId/userKey').set(newUserKey);
          
          if (kDebugMode) {
            print('🔧 Generated new userKey for existing user: $newUserKey');
          }
        }
        
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Lấy thông tin người dùng thất bại: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    try {
      await _database
          .ref('users/${userModel.id}')
          .update(userModel.toJson());
    } catch (e) {
      throw Exception('Cập nhật hồ sơ thất bại: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }

  // Check if email is verified
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Gửi email xác thực thất bại: ${e.toString()}');
    }
  }

  // Reload user to get updated email verification status
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw Exception('Cập nhật thông tin người dùng thất bại: ${e.toString()}');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user data from database
        await _database.ref('users/${user.uid}').remove();
        
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Xóa tài khoản thất bại: ${e.toString()}');
    }
  }
}
