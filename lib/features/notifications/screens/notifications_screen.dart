import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showNotificationSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: StreamBuilder<List<AirQualityAlert>>(
        stream: _notificationService.getUserAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Các cảnh báo về chất lượng không khí sẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(alert, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(AirQualityAlert alert, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: alert.isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getSeverityIcon(alert.severity),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getAlertTitle(alert.type),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
                        color: _getSeverityColor(alert.severity),
                      ),
                    ),
                  ),
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert.deviceName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: alert.isRead ? Colors.grey[600] : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(alert.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (alert.value > 0 && alert.threshold > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(alert.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${alert.value.toStringAsFixed(1)} / ${alert.threshold.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSeverityColor(alert.severity),
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case AlertSeverity.warning:
        return const Icon(Icons.warning, color: Colors.orange, size: 20);
      case AlertSeverity.info:
        return const Icon(Icons.info, color: Colors.blue, size: 20);
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  String _getAlertTitle(AlertType type) {
    switch (type) {
      case AlertType.highTemperature:
        return 'Nhiệt độ cao';
      case AlertType.lowTemperature:
        return 'Nhiệt độ thấp';
      case AlertType.highHumidity:
        return 'Độ ẩm cao';
      case AlertType.lowHumidity:
        return 'Độ ẩm thấp';
      case AlertType.highPM25:
        return 'PM2.5 cao';
      case AlertType.highPM10:
        return 'PM10 cao';
      case AlertType.highCO2:
        return 'CO2 cao';
      case AlertType.highVOC:
        return 'VOC cao';
      case AlertType.deviceOffline:
        return 'Thiết bị offline';
      case AlertType.deviceError:
        return 'Lỗi thiết bị';
      case AlertType.batteryLow:
        return 'Pin yếu';
      case AlertType.other:
        return 'Thông báo khác';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _markAsRead(AirQualityAlert alert) async {
    if (!alert.isRead) {
      await _notificationService.markAlertAsRead(alert.id);
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt thông báo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Thông báo push'),
              subtitle: const Text('Nhận thông báo khi có cảnh báo'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Update settings
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Âm thanh'),
              subtitle: const Text('Phát âm thanh khi có thông báo'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Update settings
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Rung'),
              subtitle: const Text('Rung khi có thông báo'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Update settings
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
