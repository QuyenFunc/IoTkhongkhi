import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../services/user_service.dart';
import '../../../core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Try to fix profile name first
      await _userService.fixUserProfileName();
      
      // Then load the profile
      final profile = await _userService.getCurrentUserProfile();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading profile: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.pushNamed(
      context, 
      AppRoutes.profileSetup,
      arguments: {'isFirstTime': false},
    );
    
    if (result == true) {
      // Profile was updated, reload
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editProfile,
            tooltip: 'Chỉnh sửa hồ sơ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải thông tin hồ sơ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _userProfile!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(profile),
          
          const SizedBox(height: 24),
          
          // Profile Information
          _buildProfileInfo(profile),
          
          const SizedBox(height: 24),
          
          // Settings Section
          _buildSettingsSection(profile),
          
          const SizedBox(height: 24),
          
          // Debug Section (only in debug mode)
          if (kDebugMode) _buildDebugSection(profile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: profile.profileImageUrl != null
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: profile.profileImageUrl == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      profile.isEmailVerified 
                          ? Icons.verified 
                          : Icons.warning,
                      size: 16,
                      color: profile.isEmailVerified 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.isEmailVerified 
                          ? 'Email đã xác thực' 
                          : 'Email chưa xác thực',
                      style: TextStyle(
                        fontSize: 12,
                        color: profile.isEmailVerified 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(UserModel profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              icon: Icons.person,
              label: 'Họ và tên',
              value: profile.name,
            ),
            
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: profile.email,
            ),
            
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Số điện thoại',
              value: profile.phoneNumber ?? 'Chưa cập nhật',
            ),
            
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo tài khoản',
              value: _formatDate(profile.createdAt),
            ),
            
            _buildInfoRow(
              icon: Icons.update,
              label: 'Cập nhật lần cuối',
              value: _formatDate(profile.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(UserModel profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSettingRow(
              icon: Icons.language,
              label: 'Ngôn ngữ',
              value: profile.preferences.language == 'vi' ? 'Tiếng Việt' : 'English',
            ),
            
            _buildSettingRow(
              icon: Icons.palette,
              label: 'Giao diện',
              value: _getThemeDisplayName(profile.preferences.theme),
            ),
            
            _buildSettingRow(
              icon: Icons.thermostat,
              label: 'Đơn vị nhiệt độ',
              value: profile.preferences.temperatureUnit.name,
            ),
            
            _buildSettingRow(
              icon: Icons.notifications,
              label: 'Thông báo',
              value: profile.preferences.notificationsEnabled ? 'Bật' : 'Tắt',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(UserModel profile) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              icon: Icons.fingerprint,
              label: 'User ID',
              value: profile.id,
            ),
            
            _buildInfoRow(
              icon: Icons.image,
              label: 'Profile Image URL',
              value: profile.profileImageUrl ?? 'None',
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await _userService.fixUserProfileName();
                _loadUserProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fix Profile Name'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      case 'system':
        return 'Theo hệ thống';
      default:
        return theme;
    }
  }
}
