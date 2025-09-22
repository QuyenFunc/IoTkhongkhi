import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/main_viewmodel.dart';
import '../models/control_model.dart';
import '../widgets/sensor_data_card.dart';
import '../widgets/device_status_card.dart';
import '../widgets/alerts_card.dart';
import '../services/alert_service.dart';
import 'history_screen.dart';
import 'threshold_settings_screen.dart';

/// Màn hình chính của ứng dụng giám sát chất lượng không khí
class MainAirMonitorScreen extends StatefulWidget {
  const MainAirMonitorScreen({super.key});

  @override
  State<MainAirMonitorScreen> createState() => _MainAirMonitorScreenState();
}

class _MainAirMonitorScreenState extends State<MainAirMonitorScreen> {
  late MainViewModel _viewModel;
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<MainViewModel>();
    _viewModel.initialize();
    
    // Start listening for alerts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alertService.startListening(context);
    });
  }
  
  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌬️ Chất Lượng Không Khí',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<MainViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: viewModel.isLoading ? null : () => viewModel.refresh(),
                tooltip: 'Làm mới',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThresholdSettingsScreen()),
              );
            },
            tooltip: 'Ngưỡng cảnh báo',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistory(),
            tooltip: 'Lịch sử',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'Cài đặt',
          ),
        ],
      ),
      body: Consumer<MainViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.sensorData.timestamp == 0) {
            return const _LoadingView();
          }

          if (viewModel.errorMessage != null) {
            return _ErrorView(
              message: viewModel.errorMessage!,
              onRetry: () => viewModel.refresh(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Status Card
                  DeviceStatusCard(
                    deviceStatus: viewModel.deviceStatus,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sensor Data Cards
                  SensorDataCard(
                    sensorData: viewModel.sensorData,
                  ),
                  const SizedBox(height: 16),
                  
                  // Alerts Card (if any)
                  if (viewModel.hasAlerts)
                    AlertsCard(
                      alerts: viewModel.currentAlerts,
                    ),
                  
                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          );
        },
      ),
      // Đã gỡ FAB mở Lịch sử & Biểu đồ
    );
  }


  /// Navigate to history screen
  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        viewModel: _viewModel,
      ),
    );
  }
}

/// Loading view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
            Text(
              '🔄 Đang tải dữ liệu...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

/// Error view
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử Lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings dialog
class _SettingsDialog extends StatefulWidget {
  final MainViewModel viewModel;

  const _SettingsDialog({
    required this.viewModel,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late TextEditingController _tempMinController;
  late TextEditingController _tempMaxController;
  late TextEditingController _humiMinController;
  late TextEditingController _humiMaxController;
  late TextEditingController _pm25MaxController;

  @override
  void initState() {
    super.initState();
    final thresholds = widget.viewModel.thresholds;
    _tempMinController = TextEditingController(
      text: thresholds.temperature.min.toString(),
    );
    _tempMaxController = TextEditingController(
      text: thresholds.temperature.max.toString(),
    );
    _humiMinController = TextEditingController(
      text: thresholds.humidity.min.toString(),
    );
    _humiMaxController = TextEditingController(
      text: thresholds.humidity.max.toString(),
    );
    _pm25MaxController = TextEditingController(
      text: thresholds.pm25.max.toString(),
    );
  }

  @override
  void dispose() {
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _humiMinController.dispose();
    _humiMaxController.dispose();
    _pm25MaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('⚙️ Cài Đặt Ngưỡng Cảnh Báo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Temperature thresholds
            const Text(
              '🌡️ Nhiệt Độ (°C)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tối thiểu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _tempMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tối đa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Humidity thresholds
            const Text(
              '💧 Độ Ẩm (%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _humiMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tối thiểu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _humiMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tối đa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // PM2.5 threshold
            const Text(
              '🌫️ PM2.5 (μg/m³)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pm25MaxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tối đa',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  void _saveSettings() async {
    try {
      final newThresholds = AlertThresholds(
        temperature: TemperatureThreshold(
          min: double.parse(_tempMinController.text),
          max: double.parse(_tempMaxController.text),
        ),
        humidity: HumidityThreshold(
          min: double.parse(_humiMinController.text),
          max: double.parse(_humiMaxController.text),
        ),
        pm25: PM25Threshold(
          max: double.parse(_pm25MaxController.text),
        ),
      );

      final success = await widget.viewModel.updateThresholds(newThresholds);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? '✅ Cài đặt đã được lưu'
                  : '❌ Không thể lưu cài đặt',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Giá trị không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
