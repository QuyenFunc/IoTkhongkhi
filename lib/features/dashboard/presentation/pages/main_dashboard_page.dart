import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../user/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../devices/screens/device_list_screen.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const DeviceListScreen(),
    const MonitoringTab(),
    const AlertsTab(),
    const SettingsTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Thiết bị',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_outlined),
            selectedIcon: Icon(Icons.monitor),
            label: 'Giám sát',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Cảnh báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _userName = 'Người dùng';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final UserService userService = UserService();
      final profile = await userService.getCurrentUserProfile();

      if (profile != null && mounted) {
        setState(() {
          _userName = profile.name;
          _isLoadingProfile = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _userName = 'Người dùng';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Người dùng';
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang làm mới dữ liệu...')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isLoadingProfile
                                ? Text(
                                    'Đang tải...',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    'Xin chào, $_userName!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            Text(
                              'Chào mừng bạn đến với hệ thống giám sát',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              // Quick Stats
              Text(
                'Thống kê nhanh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Thiết bị',
                      '3',
                      Icons.devices,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Trực tuyến',
                      '2',
                      Icons.wifi,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Cảnh báo',
                      '1',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Ngoại tuyến',
                      '1',
                      Icons.wifi_off,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Devices
              Text(
                'Thiết bị gần đây',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildDeviceCard(
                context,
                'ESP32 - Phòng khách',
                'Trực tuyến',
                '25°C, 60%',
                'Cập nhật 2 phút trước',
                true,
              ),
              
              const SizedBox(height: 12),
              
              _buildDeviceCard(
                context,
                'ESP32 - Phòng ngủ',
                'Trực tuyến',
                '23°C, 55%',
                'Cập nhật 1 phút trước',
                true,
              ),
              
              const SizedBox(height: 12),
              
              _buildDeviceCard(
                context,
                'ESP32 - Nhà bếp',
                'Ngoại tuyến',
                'Không có dữ liệu',
                'Cập nhật 15 phút trước',
                false,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm thiết bị mới sẽ sớm được triển khai')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    String name,
    String status,
    String data,
    String lastUpdate,
    bool isOnline,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOnline ? Colors.green : Colors.red,
          child: Icon(
            Icons.sensors,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data),
            const SizedBox(height: 2),
            Text(
              lastUpdate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở chi tiết thiết bị: $name')),
          );
        },
      ),
    );
  }
}

// Devices Tab - Now using DeviceListScreen
/*
class DevicesTab extends StatelessWidget {
  const DevicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tìm kiếm thiết bị sẽ sớm được triển khai')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Trực tuyến'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Ngoại tuyến'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Cảnh báo'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Device List
            _buildDeviceCard(
              context,
              'ESP32-001',
              'Phòng khách',
              'Trực tuyến',
              '25°C, 60%',
              'Cập nhật 2 phút trước',
              true,
              false,
            ),

            const SizedBox(height: 12),

            _buildDeviceCard(
              context,
              'ESP32-002',
              'Phòng ngủ',
              'Trực tuyến',
              '23°C, 55%',
              'Cập nhật 1 phút trước',
              true,
              false,
            ),

            const SizedBox(height: 12),

            _buildDeviceCard(
              context,
              'ESP32-003',
              'Nhà bếp',
              'Ngoại tuyến',
              'Không có dữ liệu',
              'Cập nhật 15 phút trước',
              false,
              false,
            ),

            const SizedBox(height: 12),

            _buildDeviceCard(
              context,
              'ESP32-004',
              'Phòng làm việc',
              'Trực tuyến',
              '27°C, 65%',
              'Cập nhật 30 giây trước',
              true,
              true,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm thiết bị mới sẽ sớm được triển khai')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm thiết bị'),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    String deviceId,
    String location,
    String status,
    String data,
    String lastUpdate,
    bool isOnline,
    bool hasAlert,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở chi tiết thiết bị: $deviceId')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Device Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sensors,
                      color: isOnline
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Device Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              deviceId,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasAlert) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Data and Last Update
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    lastUpdate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

class MonitoringTab extends StatelessWidget {
  const MonitoringTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám sát'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bộ lọc sẽ sớm được triển khai')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTimeRangeChip('1 giờ', true),
                    const SizedBox(width: 8),
                    _buildTimeRangeChip('24 giờ', false),
                    const SizedBox(width: 8),
                    _buildTimeRangeChip('7 ngày', false),
                    const SizedBox(width: 8),
                    _buildTimeRangeChip('30 ngày', false),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Current Readings
              Text(
                'Đo lường hiện tại',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Nhiệt độ',
                      '25°C',
                      Icons.thermostat,
                      Colors.orange,
                      'Bình thường',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Độ ẩm',
                      '60%',
                      Icons.water_drop,
                      Colors.blue,
                      'Bình thường',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Chất lượng KK',
                      'Tốt',
                      Icons.air,
                      Colors.green,
                      'AQI: 45',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Áp suất',
                      '1013 hPa',
                      Icons.speed,
                      Colors.purple,
                      'Bình thường',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Chart Placeholder
              Text(
                'Biểu đồ theo thời gian',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Biểu đồ thời gian thực',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sẽ được triển khai với thư viện fl_chart',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Alerts
              Text(
                'Cảnh báo gần đây',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildAlertCard(
                context,
                'Nhiệt độ cao',
                'ESP32-004 - Phòng làm việc',
                '27°C (vượt ngưỡng 26°C)',
                '5 phút trước',
                Colors.orange,
              ),

              const SizedBox(height: 12),

              _buildAlertCard(
                context,
                'Thiết bị ngoại tuyến',
                'ESP32-003 - Nhà bếp',
                'Mất kết nối từ 15 phút trước',
                '15 phút trước',
                Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String status,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String device,
    String description,
    String time,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            Icons.warning,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device),
            const SizedBox(height: 2),
            Text(description),
            const SizedBox(height: 2),
            Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tùy chọn cảnh báo sẽ sớm được triển khai')),
            );
          },
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chi tiết cảnh báo: $title')),
          );
        },
      ),
    );
  }
}

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cảnh báo')),
      body: const Center(
        child: Text('Tab Cảnh báo - Sẽ được triển khai sau'),
      ),
    );
  }
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _userName = 'Người dùng';
  String _userEmail = 'user@example.com';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final UserService userService = UserService();
      final profile = await userService.getCurrentUserProfile();
      final authUser = FirebaseAuth.instance.currentUser;

      if (profile != null && mounted) {
        setState(() {
          _userName = profile.name;
          _userEmail = profile.email;
          _isLoadingProfile = false;
        });
      } else if (authUser != null && mounted) {
        setState(() {
          _userName = authUser.displayName ?? 'Người dùng';
          _userEmail = authUser.email ?? 'user@example.com';
          _isLoadingProfile = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _userName = 'Người dùng';
            _userEmail = 'user@example.com';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Người dùng';
          _userEmail = 'user@example.com';
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppRoutes.navigateToLogin(context);
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingProfile
                            ? Text(
                                'Đang tải...',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                _userName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        const SizedBox(height: 4),
                        _isLoadingProfile
                            ? Text(
                                'Đang tải...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Text(
                                _userEmail,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chỉnh sửa hồ sơ sẽ sớm được triển khai')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Settings Sections
          Text(
            'Cài đặt ứng dụng',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Thông báo'),
                  subtitle: const Text('Quản lý cài đặt thông báo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cài đặt thông báo sẽ sớm được triển khai')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Giao diện'),
                  subtitle: const Text('Chế độ sáng/tối, màu sắc'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cài đặt giao diện sẽ sớm được triển khai')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Ngôn ngữ'),
                  subtitle: const Text('Tiếng Việt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cài đặt ngôn ngữ sẽ sớm được triển khai')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Thiết bị & Dữ liệu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_outlined),
                  title: const Text('Đồng bộ dữ liệu'),
                  subtitle: const Text('Tự động đồng bộ với cloud'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cài đặt đồng bộ sẽ sớm được triển khai')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Quản lý dữ liệu'),
                  subtitle: const Text('Xóa cache, xuất dữ liệu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quản lý dữ liệu sẽ sớm được triển khai')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Hỗ trợ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Trợ giúp'),
                  subtitle: const Text('Hướng dẫn sử dụng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trợ giúp sẽ sớm được triển khai')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Về ứng dụng'),
                  subtitle: const Text('Phiên bản 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thông tin ứng dụng sẽ sớm được triển khai')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
