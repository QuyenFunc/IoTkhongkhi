import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:air_quality/features/user/services/user_service.dart';
import 'package:air_quality/shared/models/user_model.dart';
import 'package:air_quality/shared/widgets/custom_button.dart';
import 'package:air_quality/shared/widgets/custom_text_field.dart';
import 'package:air_quality/core/routes/app_routes.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  final UserModel? currentProfile;

  const ProfileSetupScreen({
    super.key,
    this.isFirstTime = true,
    this.currentProfile,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.currentProfile != null) {
      _nameController.text = widget.currentProfile!.name;
      _phoneController.text = widget.currentProfile!.phoneNumber ?? '';
      _currentImageUrl = widget.currentProfile!.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('🔄 Starting profile update...');
        print('Name: ${_nameController.text.trim()}');
        print('Phone: ${_phoneController.text.trim()}');
      }

      // Update profile (without image upload for now)
      await _userService.updateUserProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        // Skip image upload for now to avoid Firebase Storage issues
        // profileImageUrl: imageUrl,
      );

      if (kDebugMode) {
        print('✅ Profile updated successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isFirstTime) {
          // Navigate to dashboard for first-time setup
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          // Go back for profile edit
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profile update error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : _currentImageUrl != null
                    ? NetworkImage(_currentImageUrl!)
                    : null,
            child: _selectedImage == null && _currentImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[400], // Disabled color
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: null, // Disabled for now
                // onPressed: _isLoading ? null : _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Thiết lập hồ sơ' : 'Chỉnh sửa hồ sơ'),
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstTime) ...[
                  Text(
                    'Hoàn thiện thông tin cá nhân',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng cập nhật thông tin để có trải nghiệm tốt nhất',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // Profile Image
                _buildProfileImage(),
                const SizedBox(height: 32),

                // Name Field
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên hiển thị';
                    }
                    if (value.trim().length < 2) {
                      return 'Tên hiển thị phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone Field
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Số điện thoại (tùy chọn)',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 10) {
                        return 'Số điện thoại không hợp lệ';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  text: widget.isFirstTime ? 'Hoàn thành' : 'Lưu thay đổi',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),

                if (widget.isFirstTime) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                    },
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
