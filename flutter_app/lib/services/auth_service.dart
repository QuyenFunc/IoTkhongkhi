import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user != null) {
        // Update last login
        await _updateUserProfile(result.user!);
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi không mong muốn: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user != null) {
        // Update user profile
        await result.user!.updateDisplayName(displayName.trim());
        
        // Create user profile in database
        await _createUserProfile(result.user!, displayName.trim());
        
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Đã xảy ra lỗi không mong muốn: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google (optional - requires additional setup)
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      
      // This would require google_sign_in package and additional setup
      // For now, just show error
      _setError('Đăng nhập Google chưa được thiết lập');
      return false;
      
    } catch (e) {
      _setError('Đăng nhập Google thất bại: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.signOut();
    } catch (e) {
      _setError('Đăng xuất thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Gửi email đặt lại mật khẩu thất bại: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (currentUser == null) {
        _setError('Người dùng chưa đăng nhập');
        return false;
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName.trim());
      }
      
      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
      }

      // Update database profile
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName.trim();
      if (photoURL != null) updates['photoURL'] = photoURL;
      
      if (updates.isNotEmpty) {
        await _database
            .child('users')
            .child(currentUser!.uid)
            .child('profile')
            .update(updates);
      }

      return true;
    } catch (e) {
      _setError('Cập nhật thông tin thất bại: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (currentUser == null) {
        _setError('Người dùng chưa đăng nhập');
        return false;
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await currentUser!.updatePassword(newPassword);
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Đổi mật khẩu thất bại: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (currentUser == null) {
        _setError('Người dùng chưa đăng nhập');
        return false;
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Delete user data from database
      await _database.child('users').child(currentUser!.uid).remove();
      
      // Delete account
      await currentUser!.delete();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Xóa tài khoản thất bại: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      DatabaseEvent event = await _database
          .child('users')
          .child(currentUser!.uid)
          .child('profile')
          .once();
      
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      await _database.child('users').child(user.uid).child('profile').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoURL': user.photoURL,
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'emailVerified': user.emailVerified,
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // Update user profile
  Future<void> _updateUserProfile(User user) async {
    try {
      await _database
          .child('users')
          .child(user.uid)
          .child('profile')
          .update({
        'lastLogin': ServerValue.timestamp,
        'emailVerified': user.emailVerified,
      });
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho tài khoản khác';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Thao tác này không được phép';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này';
      case 'credential-already-in-use':
        return 'Thông tin đăng nhập này đã được sử dụng cho tài khoản khác';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ';
      case 'account-exists-with-different-credential':
        return 'Tài khoản đã tồn tại với thông tin đăng nhập khác';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Gửi email xác nhận thất bại: $e');
      return false;
    }
  }

  // Reload user data
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      notifyListeners();
    } catch (e) {
      print('Error reloading user: $e');
    }
  }
}