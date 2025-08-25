import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/device_service.dart';
import '../../../shared/models/device_model.dart';

class DeviceManagementScreen extends StatefulWidget {
  final DeviceModel device;

  const DeviceManagementScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý ${widget.device.name}'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Info Card
            _buildDeviceInfoCard(theme),
            
            const SizedBox(height: 16),
            
            // Device Controls
            _buildDeviceControlsCard(theme),
            
            const SizedBox(height: 16),
            
            // Configuration
            _buildConfigurationCard(theme),
            
            const SizedBox(height: 16),
            
            // Calibration
            _buildCalibrationCard(theme),
            
            const SizedBox(height: 16),
            
            // Advanced Actions
            _buildAdvancedActionsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin thiết bị',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ID:', widget.device.id),
            _buildInfoRow('Tên:', widget.device.name),
            _buildInfoRow('Vị trí:', widget.device.location),
            _buildInfoRow('Trạng thái:', _getStatusText(widget.device.status)),
            _buildInfoRow('Loại:', _getTypeText(widget.device.type)),
            if (widget.device.lastSeenAt != null)
              _buildInfoRow('Lần cuối online:', _formatDateTime(widget.device.lastSeenAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceControlsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khiển thiết bị',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pingDevice(),
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Ping'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _restartDevice(),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Khởi động lại'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _toggleSleepMode(),
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Chế độ ngủ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt ngưỡng cảnh báo'),
              subtitle: const Text('Cấu hình ngưỡng cho các cảm biến'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showThresholdSettings(),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Tần suất báo cáo'),
              subtitle: Text('${widget.device.configuration.reportingInterval} giây'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showReportingIntervalSettings(),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Cảnh báo'),
              subtitle: Text(widget.device.configuration.alertsEnabled ? 'Bật' : 'Tắt'),
              trailing: Switch(
                value: widget.device.configuration.alertsEnabled,
                onChanged: (value) => _toggleAlerts(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu chuẩn',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hiệu chuẩn cảm biến để đảm bảo độ chính xác của dữ liệu.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _showCalibrationDialog(),
              icon: const Icon(Icons.tune),
              label: const Text('Hiệu chuẩn cảm biến'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedActionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động nâng cao',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.system_update, color: Colors.blue),
              title: const Text('Cập nhật firmware'),
              subtitle: const Text('Cập nhật phần mềm thiết bị'),
              onTap: () => _showFirmwareUpdateDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Khôi phục cài đặt gốc'),
              subtitle: const Text('Đặt lại thiết bị về cài đặt mặc định'),
              onTap: () => _showResetConfirmation(),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text('Xem nhật ký'),
              subtitle: const Text('Xem lịch sử hoạt động của thiết bị'),
              onTap: () => _showDeviceLogs(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa thiết bị'),
              subtitle: const Text('Xóa thiết bị khỏi tài khoản'),
              onTap: () => _showDeleteConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.active:
        return 'Hoạt động';
      case DeviceStatus.inactive:
        return 'Không hoạt động';
      case DeviceStatus.maintenance:
        return 'Bảo trì';
      case DeviceStatus.error:
        return 'Lỗi';
    }
  }

  String _getTypeText(DeviceType type) {
    switch (type) {
      case DeviceType.esp32:
        return 'ESP32';
      case DeviceType.arduino:
        return 'Arduino';
      case DeviceType.raspberryPi:
        return 'Raspberry Pi';
      case DeviceType.custom:
        return 'Tùy chỉnh';
      case DeviceType.other:
        return 'Khác';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pingDevice() async {
    setState(() => _isLoading = true);
    try {
      final isOnline = await _deviceService.pingDevice(widget.device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline ? 'Thiết bị đang online' : 'Thiết bị không phản hồi'),
            backgroundColor: isOnline ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restartDevice() async {
    setState(() => _isLoading = true);
    try {
      await _deviceService.restartDevice(widget.device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lệnh khởi động lại'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSleepMode() {
    // TODO: Implement sleep mode toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showThresholdSettings() {
    // TODO: Implement threshold settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showReportingIntervalSettings() {
    // TODO: Implement reporting interval settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _toggleAlerts(bool enabled) {
    // TODO: Implement alert toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showCalibrationDialog() {
    // TODO: Implement calibration dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showFirmwareUpdateDialog() {
    // TODO: Implement firmware update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục cài đặt gốc'),
        content: const Text('Bạn có chắc chắn muốn đặt lại thiết bị về cài đặt mặc định? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetDevice();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }

  void _showDeviceLogs() {
    // TODO: Implement device logs screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang phát triển')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thiết bị'),
        content: const Text('Bạn có chắc chắn muốn xóa thiết bị này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDevice();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDevice() async {
    setState(() => _isLoading = true);
    try {
      await _deviceService.resetDevice(widget.device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đặt lại thiết bị về cài đặt gốc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDevice() async {
    setState(() => _isLoading = true);
    try {
      await _deviceService.deleteDevice(widget.device.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thiết bị'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
