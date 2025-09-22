import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_control_service.dart';
import '../../../shared/models/device_model.dart';

class DeviceControlScreen extends ConsumerStatefulWidget {
  final DeviceModel device;

  const DeviceControlScreen({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends ConsumerState<DeviceControlScreen>
    with SingleTickerProviderStateMixin {
  final DeviceControlService _controlService = DeviceControlService();
  late TabController _tabController;
  
  bool _isOnline = false;
  Map<String, dynamic>? _deviceConfig;
  List<Map<String, dynamic>> _commandHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeviceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceData() async {
    // Check if device is online
    final isOnline = await _controlService.isDeviceOnline(widget.device.id);
    
    // Get device configuration
    final config = await _controlService.getDeviceConfig(widget.device.id);
    
    // Get command history
    final history = await _controlService.getCommandHistory(widget.device.id);

    if (mounted) {
      setState(() {
        _isOnline = isOnline;
        _deviceConfig = config;
        _commandHistory = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Điều khiển - ${widget.device.name}'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeviceData,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Điều khiển', icon: Icon(Icons.control_camera)),
            Tab(text: 'Cấu hình', icon: Icon(Icons.settings)),
            Tab(text: 'Lịch sử', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.circle : Icons.circle_outlined,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'Thiết bị đang hoạt động' : 'Thiết bị ngoại tuyến',
                  style: TextStyle(
                    color: _isOnline ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!_isOnline)
                  Text(
                    'Một số lệnh có thể không khả dụng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildControlTab(),
                _buildConfigTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lệnh điều khiển',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          _buildControlCard(
            'Khởi động lại thiết bị',
            'Khởi động lại ESP32 để áp dụng cấu hình mới',
            Icons.restart_alt,
            Colors.orange,
            () => _showRestartConfirmation(),
          ),

          const SizedBox(height: 12),

          _buildControlCard(
            'Bật/Tắt đèn báo',
            'Điều khiển LED chỉ thị trên thiết bị',
            Icons.lightbulb,
            Colors.yellow.shade700,
            () => _toggleLED(),
          ),

          const SizedBox(height: 12),

          _buildControlCard(
            'Hiệu chuẩn cảm biến',
            'Thực hiện hiệu chuẩn lại các cảm biến',
            Icons.tune,
            Colors.blue,
            () => _calibrateSensors(),
          ),

          const SizedBox(height: 12),

          _buildControlCard(
            'Chế độ cấu hình',
            'Bật chế độ WiFi AP để cấu hình lại',
            Icons.wifi_tethering,
            Colors.purple,
            () => _toggleConfigMode(),
          ),

          const SizedBox(height: 12),

          _buildControlCard(
            'Đặt lại nhà máy',
            'Xóa tất cả cài đặt và trở về mặc định',
            Icons.factory,
            Colors.red,
            () => _showFactoryResetConfirmation(),
            dangerous: true,
          ),

          const SizedBox(height: 24),

          // Update interval setting
          Text(
            'Tần suất cập nhật dữ liệu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildIntervalSelector(),
        ],
      ),
    );
  }

  Widget _buildControlCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool dangerous = false,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: dangerous ? Colors.red.shade700 : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: dangerous ? Colors.red.shade300 : null,
        ),
        onTap: _isOnline ? onTap : null,
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = [5, 10, 30, 60, 300, 600]; // seconds
    final currentInterval = _deviceConfig?['updateInterval'] as int? ?? 30;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiện tại: ${_formatInterval(currentInterval)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: intervals.map((interval) {
                final isSelected = interval == currentInterval;
                return FilterChip(
                  label: Text(_formatInterval(interval)),
                  selected: isSelected,
                  onSelected: _isOnline ? (selected) {
                    if (selected && interval != currentInterval) {
                      _setUpdateInterval(interval);
                    }
                  } : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cấu hình thiết bị',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_deviceConfig != null) ...[
            _buildConfigItem('Tên thiết bị', widget.device.name),
            _buildConfigItem('Device ID', widget.device.id),
            _buildConfigItem('Phiên bản firmware', _deviceConfig!['firmware'] ?? 'N/A'),
            _buildConfigItem('WiFi SSID', _deviceConfig!['wifiSSID'] ?? 'N/A'),
            _buildConfigItem('Địa chỉ IP', _deviceConfig!['ipAddress'] ?? 'N/A'),
            _buildConfigItem('Tần suất cập nhật', '${_deviceConfig!['updateInterval'] ?? 30}s'),
            _buildConfigItem('LED báo hiệu', _deviceConfig!['ledEnabled'] == true ? 'Bật' : 'Tắt'),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Đang tải cấu hình...'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Location setting
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vị trí thiết bị',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                Text(
                  widget.device.location.isNotEmpty ? widget.device.location : 'Chưa đặt',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isOnline ? _changeLocation : null,
                    icon: const Icon(Icons.edit_location),
                    label: const Text('Thay đổi vị trí'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // WiFi settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cấu hình WiFi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thay đổi mạng WiFi mà thiết bị kết nối',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isOnline ? _changeWiFiSettings : null,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Cấu hình WiFi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
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

  Widget _buildHistoryTab() {
    if (_commandHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Chưa có lệnh nào được thực hiện'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commandHistory.length,
      itemBuilder: (context, index) {
        final command = _commandHistory[index];
        return _buildHistoryItem(command);
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> command) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      command['timestamp'] as int? ?? 0,
    );
    final commandName = command['command'] as String? ?? 'Unknown';
    final status = command['status'] as String? ?? 'unknown';
    
    IconData icon;
    Color color;
    
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'sent':
      case 'pending':
      default:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(_getCommandDisplayName(commandName)),
        subtitle: Text(
          '${_formatDateTime(timestamp)} • ${_getStatusDisplayName(status)}',
        ),
        trailing: command['value'] != null 
            ? Text(
                command['value'].toString(),
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
    );
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}m';
    } else {
      return '${seconds ~/ 3600}h';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getCommandDisplayName(String command) {
    switch (command) {
      case 'restart':
        return 'Khởi động lại';
      case 'factoryReset':
        return 'Đặt lại nhà máy';
      case 'ledEnabled':
        return 'Bật/Tắt LED';
      case 'updateInterval':
        return 'Thay đổi tần suất cập nhật';
      case 'location':
        return 'Thay đổi vị trí';
      case 'configMode':
        return 'Chế độ cấu hình';
      case 'calibrate':
        return 'Hiệu chuẩn cảm biến';
      case 'wifiConfig':
        return 'Cấu hình WiFi';
      default:
        return command;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      case 'sent':
        return 'Đã gửi';
      case 'pending':
        return 'Đang xử lý';
      default:
        return 'Không xác định';
    }
  }

  // Command handlers
  Future<void> _showRestartConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận khởi động lại'),
        content: const Text(
          'Thiết bị sẽ khởi động lại và mất kết nối trong vài giây. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Khởi động lại'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controlService.restartDevice(widget.device.id);
      _showResult('Khởi động lại thiết bị', success);
      if (success) {
        _loadDeviceData();
      }
    }
  }

  Future<void> _toggleLED() async {
    final currentState = _deviceConfig?['ledEnabled'] as bool? ?? false;
    final success = await _controlService.toggleLED(widget.device.id, !currentState);
    _showResult('Thay đổi trạng thái LED', success);
    if (success) {
      _loadDeviceData();
    }
  }

  Future<void> _calibrateSensors() async {
    final success = await _controlService.calibrateSensors(widget.device.id);
    _showResult('Hiệu chuẩn cảm biến', success);
    if (success) {
      _loadDeviceData();
    }
  }

  Future<void> _toggleConfigMode() async {
    final success = await _controlService.toggleConfigMode(widget.device.id, true);
    _showResult('Bật chế độ cấu hình', success);
    if (success) {
      _loadDeviceData();
    }
  }

  Future<void> _showFactoryResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cảnh báo: Đặt lại nhà máy'),
        content: const Text(
          'Tất cả cài đặt sẽ bị xóa và thiết bị sẽ trở về trạng thái ban đầu. '
          'Bạn sẽ cần cấu hình lại từ đầu. Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đặt lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controlService.factoryResetDevice(widget.device.id);
      _showResult('Đặt lại nhà máy', success);
      if (success) {
        _loadDeviceData();
      }
    }
  }

  Future<void> _setUpdateInterval(int interval) async {
    final success = await _controlService.setUpdateInterval(widget.device.id, interval);
    _showResult('Thay đổi tần suất cập nhật', success);
    if (success) {
      _loadDeviceData();
    }
  }

  Future<void> _changeLocation() async {
    final currentLocation = widget.device.location.isNotEmpty ? widget.device.location : '';
    final controller = TextEditingController(text: currentLocation);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi vị trí'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Vị trí thiết bị',
            hintText: 'VD: Phòng khách, Phòng ngủ...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final success = await _controlService.setDeviceLocation(widget.device.id, result);
      _showResult('Thay đổi vị trí', success);
      if (success) {
        _loadDeviceData();
      }
    }
  }

  Future<void> _changeWiFiSettings() async {
    // TODO: Implement WiFi configuration dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng cấu hình WiFi sẽ được triển khai trong bản cập nhật tiếp theo'),
      ),
    );
  }

  void _showResult(String action, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '$action thành công' : '$action thất bại',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
