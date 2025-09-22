import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../user/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../devices/screens/device_list_screen.dart';
import '../../../devices/screens/device_setup_screen.dart';
import '../../services/dashboard_service.dart';
import '../../../air_monitor/screens/main_air_monitor_screen.dart';
import '../../../notifications/services/background_notification_service.dart';
import '../../../voice_assistant/screens/voice_assistant_screen.dart';
import '../../../voice_assistant/services/voice_assistant_service.dart';

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
    const MainAirMonitorScreen(), // Use real air monitor instead of placeholder
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Test Quick Voice Commands
          FloatingActionButton.small(
            onPressed: () async {
              final voiceService = VoiceAssistantService();
              await voiceService.initialize();
              await voiceService.quickAirQualityCheck();
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.speed, color: Colors.white),
            heroTag: "test_voice",
          ),
          const SizedBox(height: 8),
          // Voice Assistant
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceAssistantScreen(),
                ),
              );
            },
            child: const Icon(Icons.assistant),
            heroTag: "voice_assistant",
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
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    await _dashboardService.initialize();
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
              
              // Quick Stats - Real Data from Firebase
              Text(
                'Thống kê nhanh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Real stats from Firebase
              StreamBuilder<DashboardStats>(
                stream: _dashboardService.statsStream,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? const DashboardStats(
                    totalDevices: 0,
                    onlineDevices: 0,
                    offlineDevices: 0,
                    activeAlerts: 0,
                  );
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Thiết bị',
                              '${stats.totalDevices}',
                              Icons.devices,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Trực tuyến',
                              '${stats.onlineDevices}',
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
                              '${stats.activeAlerts}',
                              Icons.warning,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Ngoại tuyến',
                              '${stats.offlineDevices}',
                              Icons.wifi_off,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Recent Devices - Real Data from Firebase
              Text(
                'Thiết bị gần đây',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              StreamBuilder<List<DeviceInfo>>(
                stream: _dashboardService.devicesStream,
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  
                  if (devices.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có thiết bị nào',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thêm thiết bị ESP32 đầu tiên của bạn để bắt đầu giám sát chất lượng không khí',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DeviceSetupScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm thiết bị'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: devices.map((device) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: device.isOnline ? Colors.green : Colors.red,
                          child: Icon(
                            device.isOnline ? Icons.router : Icons.router_outlined,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(device.name),
                        subtitle: Text('${device.type} • ${device.statusText}'),
                        trailing: device.isOnline 
                            ? const Icon(Icons.wifi, color: Colors.green)
                            : const Icon(Icons.wifi_off, color: Colors.red),
                        onTap: () {
                          // Navigate to device details or air monitor
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainAirMonitorScreen(),
                            ),
                          );
                        },
                      ),
                    )).toList(),
                  );
                },
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


}

// Devices Tab - Now using DeviceListScreen instead of this commented code

// DevicesTab removed - replaced with DeviceListScreen which loads real data from Firebase

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

              // Real sensor data from Firebase
              StreamBuilder(
                stream: null, // TODO: Add real sensor data stream
                builder: (context, snapshot) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              'Nhiệt độ',
                              '--°C', // Real temperature from ESP32
                              Icons.thermostat,
                              Colors.orange,
                              'Chờ dữ liệu',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              'Độ ẩm',
                              '--%', // Real humidity from ESP32
                              Icons.water_drop,
                              Colors.blue,
                              'Chờ dữ liệu',
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
                              'Chờ dữ liệu', // Real air quality from ESP32
                              Icons.air,
                              Colors.grey,
                              'AQI: --',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              context,
                              'Áp suất',
                              '-- hPa', // Real pressure from ESP32
                              Icons.speed,
                              Colors.purple,
                              'Chờ dữ liệu',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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

              // Real alerts will be loaded from Firebase
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có cảnh báo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tất cả thiết bị đang hoạt động bình thường',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
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


}

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  final DashboardService _dashboardService = DashboardService();
  List<RecentAlert> _allAlerts = [];

  @override
  void initState() {
    super.initState();
    _initializeAlerts();
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _initializeAlerts() async {
    await _dashboardService.initialize();
    _loadAlertHistory();
  }

  Future<void> _loadAlertHistory() async {
    try {
      // Load alert history from Firebase
      final database = FirebaseDatabase.instance;
      final snapshot = await database.ref('/air_monitor/alert_history').limitToLast(50).get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        List<RecentAlert> alerts = [];
        
        for (final entry in data.entries) {
          try {
            final alertData = Map<String, dynamic>.from(entry.value as Map);
            final alert = RecentAlert(
              id: entry.key,
              message: alertData['reason'] as String? ?? '',
              timestamp: alertData['timestamp'] as int? ?? 0,
              severity: _getSeverityFromReason(alertData['reason'] as String? ?? ''),
            );
            alerts.add(alert);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error parsing alert: $e');
            }
          }
        }
        
        // Sort by timestamp descending (newest first)
        alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        setState(() {
          _allAlerts = alerts;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading alert history: $e');
      }
    }
  }

  AlertSeverity _getSeverityFromReason(String reason) {
    if (reason.toLowerCase().contains('pm2.5')) {
      return AlertSeverity.critical;
    } else if (reason.toLowerCase().contains('temperature')) {
      return AlertSeverity.warning;
    } else if (reason.toLowerCase().contains('humidity')) {
      return AlertSeverity.info;
    }
    return AlertSeverity.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Cảnh báo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertHistory,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              // Test notification
              final notificationService = BackgroundNotificationService();
              await notificationService.testNotification();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📱 Đã gửi thông báo thử nghiệm'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Test thông báo',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlertHistory,
        child: StreamBuilder<List<RecentAlert>>(
          stream: _dashboardService.alertsStream,
          builder: (context, snapshot) {
            // Combine real-time alerts with historical alerts
            final realtimeAlerts = snapshot.data ?? [];
            final combinedAlerts = [...realtimeAlerts, ..._allAlerts];
            
            // Remove duplicates and sort
            final uniqueAlerts = <String, RecentAlert>{};
            for (final alert in combinedAlerts) {
              uniqueAlerts[alert.id] = alert;
            }
            final sortedAlerts = uniqueAlerts.values.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (sortedAlerts.isEmpty) {
              return _buildEmptyState(theme);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedAlerts.length,
              itemBuilder: (context, index) {
                final alert = sortedAlerts[index];
                return _buildAlertCard(alert, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có cảnh báo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tất cả thiết bị đang hoạt động bình thường',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final notificationService = BackgroundNotificationService();
                await notificationService.testNotification();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📱 Đã gửi thông báo thử nghiệm'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test thông báo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(RecentAlert alert, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.severity.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alert.severity.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getSeverityIcon(alert.severity),
                color: alert.severity.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Alert content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: alert.severity.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.severity.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alert.severity.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        alert.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ESP32 Air Monitor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.critical:
        return Icons.error;
    }
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
