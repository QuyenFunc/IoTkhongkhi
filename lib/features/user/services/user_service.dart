import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:air_quality/shared/models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get current user profile from Realtime Database
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      if (kDebugMode) {
        print('📱 Getting user profile for: ${user.uid}');
      }

      final snapshot = await _database.ref('users/${user.uid}').get();
      
      if (snapshot.exists && snapshot.value != null) {
        // Safe type conversion from Firebase data
        final rawData = snapshot.value;
        final data = _convertFirebaseData(rawData);
        final userModel = UserModel.fromJson(data);
        
        if (kDebugMode) {
          print('✅ User profile loaded: ${userModel.name}');
        }
        
        return userModel;
      } else {
        if (kDebugMode) {
          print('⚠️ User profile not found in database');
          print('🔄 Attempting to create profile from auth data...');
        }

        // Auto-create profile if it doesn't exist
        return await _createProfileFromAuthData(user);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user profile: $e');
      }
      throw Exception('Không thể tải thông tin người dùng: ${e.toString()}');
    }
  }

  /// Update user profile in both Firebase Auth and Realtime Database
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    UserPreferences? preferences,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      if (kDebugMode) {
        print('📝 Updating user profile for: ${user.uid}');
      }

      // Get current profile (this will auto-create if missing)
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Không thể tải hoặc tạo thông tin người dùng');
      }

      // Update Firebase Auth profile if needed
      if (displayName != null && displayName != user.displayName) {
        await user.updateDisplayName(displayName);
        if (kDebugMode) {
          print('✅ Updated Firebase Auth display name');
        }
      }

      // Create updated user model
      final updatedProfile = currentProfile.copyWith(
        name: displayName ?? currentProfile.name,
        phoneNumber: phoneNumber ?? currentProfile.phoneNumber,
        profileImageUrl: profileImageUrl ?? currentProfile.profileImageUrl,
        preferences: preferences ?? currentProfile.preferences,
        updatedAt: DateTime.now(),
        isEmailVerified: user.emailVerified,
      );

      // Save to Realtime Database with proper serialization
      final profileJson = updatedProfile.toJson();
      profileJson['preferences'] = updatedProfile.preferences.toJson();

      await _database
          .ref('users/${user.uid}')
          .set(profileJson);

      if (kDebugMode) {
        print('✅ User profile updated successfully');
      }

      return updatedProfile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      throw Exception('Cập nhật thông tin thất bại: ${e.toString()}');
    }
  }

  /// Upload profile image and update user profile
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      if (kDebugMode) {
        print('📸 Uploading profile image for: ${user.uid}');
      }

      // Check if Firebase Storage is available
      try {
        await _storage.ref().child('test').getDownloadURL();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Firebase Storage not available: $e');
        }
        throw Exception('Dịch vụ lưu trữ ảnh chưa được kích hoạt');
      }

      // Create unique filename
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images/$fileName');

      // Upload file
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Profile image uploaded: $downloadUrl');
      }

      // Update user profile with new image URL
      await updateUserProfile(profileImageUrl: downloadUrl);

      // Update Firebase Auth photo URL
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading profile image: $e');
      }
      throw Exception('Tải ảnh lên thất bại: ${e.toString()}');
    }
  }

  /// Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      if (kDebugMode) {
        print('🗑️ Deleting user account: ${user.uid}');
      }

      // Delete user data from Realtime Database
      await _database.ref('users/${user.uid}').remove();

      // Delete profile image from Storage (if exists)
      try {
        final profileImages = await _storage.ref('profile_images').listAll();
        for (final item in profileImages.items) {
          if (item.name.contains(user.uid)) {
            await item.delete();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not delete profile images: $e');
        }
      }

      // Delete Firebase Auth account
      await user.delete();

      if (kDebugMode) {
        print('✅ User account deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting user account: $e');
      }
      throw Exception('Xóa tài khoản thất bại: ${e.toString()}');
    }
  }

  /// Check if user profile exists in database
  Future<bool> userProfileExists(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid').get();
      return snapshot.exists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking user profile existence: $e');
      }
      return false;
    }
  }

  /// Sync Firebase Auth data with Realtime Database
  Future<void> syncUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (kDebugMode) {
        print('🔄 Syncing user data for: ${user.uid}');
      }

      final profileExists = await userProfileExists(user.uid);
      
      if (!profileExists) {
        // Create profile if it doesn't exist
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Người dùng',
          phoneNumber: user.phoneNumber,
          profileImageUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
          preferences: UserPreferences.defaultPreferences(),
        );

        // Save with proper serialization
        final userJson = userModel.toJson();
        userJson['preferences'] = userModel.preferences.toJson();

        await _database.ref('users/${user.uid}').set(userJson);
        
        if (kDebugMode) {
          print('✅ User profile created during sync');
        }
      } else {
        // Update existing profile with latest Auth data
        await updateUserProfile(
          displayName: user.displayName,
          profileImageUrl: user.photoURL,
        );
        
        if (kDebugMode) {
          print('✅ User profile synced');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing user data: $e');
      }
    }
  }

  /// Get user profile stream for real-time updates
  Stream<UserModel?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _database.ref('users/${user.uid}').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  /// Create user profile from Firebase Auth data
  Future<UserModel> _createProfileFromAuthData(User user) async {
    try {


      // Try to get a meaningful name
      String userName = 'Người dùng';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        // Extract name from email if no display name
        final emailParts = user.email!.split('@');
        if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
          userName = emailParts[0];
        }
      }



      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: userName,
        phoneNumber: user.phoneNumber,
        profileImageUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: user.emailVerified,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Save to database with proper serialization
      final userJson = userModel.toJson();
      userJson['preferences'] = userModel.preferences.toJson();

      await _database.ref('users/${user.uid}').set(userJson);

      if (kDebugMode) {
        print('✅ Profile created from auth data: ${userModel.name}');
      }

      return userModel;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating profile from auth data: $e');
      }
      throw Exception('Không thể tạo hồ sơ người dùng: ${e.toString()}');
    }
  }

  /// Convert Firebase data to Map<String, dynamic> safely
  Map<String, dynamic> _convertFirebaseData(dynamic data) {
    if (data == null) {
      return {};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        if (key != null) {
          result[key.toString()] = _convertFirebaseValue(value);
        }
      });
      return result;
    }

    throw Exception('Unexpected data type from Firebase: ${data.runtimeType}');
  }

  /// Convert Firebase value to appropriate Dart type
  dynamic _convertFirebaseValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        if (key != null) {
          result[key.toString()] = _convertFirebaseValue(val);
        }
      });
      return result;
    }

    if (value is List) {
      return value.map((item) => _convertFirebaseValue(item)).toList();
    }

    // For other types, convert to string
    return value.toString();
  }

  /// Fix user profile name if it's showing default value
  Future<UserModel?> fixUserProfileName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) return null;

      // Check if profile name is default and user has displayName
      if (currentProfile.name == 'Người dùng' &&
          user.displayName != null &&
          user.displayName!.isNotEmpty) {



        return await updateUserProfile(displayName: user.displayName!);
      }

      return currentProfile;
    } catch (e) {
      return null;
    }
  }

  /// Force update profile name from email if displayName is null
  Future<UserModel?> forceUpdateProfileName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final currentProfile = await getCurrentUserProfile();
      if (currentProfile == null) return null;

      // Extract name from email if profile name is default
      if (currentProfile.name == 'Người dùng' &&
          user.email != null &&
          user.email!.isNotEmpty) {

        final emailParts = user.email!.split('@');
        if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
          final extractedName = emailParts[0];



          return await updateUserProfile(displayName: extractedName);
        }
      }

      return currentProfile;
    } catch (e) {
      return null;
    }
  }
}
