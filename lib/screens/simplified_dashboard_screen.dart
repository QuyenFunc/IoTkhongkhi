import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/simplified_firebase_service.dart';

class SimplifiedDashboardScreen extends ConsumerStatefulWidget {
  const SimplifiedDashboardScreen({super.key});

  @override
  ConsumerState<SimplifiedDashboardScreen> createState() => _SimplifiedDashboardScreenState();
}

class _SimplifiedDashboardScreenState extends ConsumerState<SimplifiedDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SimplifiedFirebaseService _firebaseService = SimplifiedFirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Air Quality Monitor'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Live Data', icon: Icon(Icons.sensors)),
            Tab(text: 'Alerts', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDevicesTab(),
          _buildLiveDataTab(),
          _buildAlertsTab(),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    return StreamBuilder<List<DeviceData>>(
      stream: _firebaseService.getAllDevices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No devices found'),
                const SizedBox(height: 8),
                const Text('Make sure your ESP32 is connected and sending data'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return _buildDeviceCard(device);
          },
        );
      },
    );
  }

  Widget _buildDeviceCard(DeviceData device) {
    final theme = Theme.of(context);
    final isOnline = device.isOnline;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sensors,
                    color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        device.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Device ID', device.deviceId.substring(0, 12) + '...'),
                ),
                Expanded(
                  child: _buildInfoItem('WiFi', device.wifiSSID),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('IP Address', device.ipAddress),
                ),
                Expanded(
                  child: _buildInfoItem('Firmware', device.firmware),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeviceControls(device),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Controls'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showLiveData(device),
                  icon: const Icon(Icons.show_chart, size: 16),
                  label: const Text('View Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLiveDataTab() {
    return StreamBuilder<List<DeviceData>>(
      stream: _firebaseService.getAllDevices(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return const Center(child: Text('No devices available'));
        }

        // For simplicity, show first device's data
        final device = devices.first;
        
        return StreamBuilder<SensorData?>(
          stream: _firebaseService.getLatestSensorData(device.deviceId),
          builder: (context, sensorSnapshot) {
            if (sensorSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final sensorData = sensorSnapshot.data;
            
            if (sensorData == null) {
              return const Center(child: Text('No sensor data available'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Sensor Data - ${device.deviceName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_formatDateTime(sensorData.timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  // Sensor cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          'Temperature',
                          '${sensorData.temperature.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSensorCard(
                          'Humidity',
                          '${sensorData.humidity.toStringAsFixed(1)}%',
                          Icons.water_drop,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          'Air Quality',
                          '${sensorData.airQuality.toStringAsFixed(1)} μg/m³',
                          Icons.air,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSensorCard(
                          'PM2.5',
                          '${(sensorData.pm25 ?? 0).toStringAsFixed(1)} μg/m³',
                          Icons.grain,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  if (sensorData.battery != null || sensorData.rssi != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (sensorData.battery != null)
                          Expanded(
                            child: _buildSensorCard(
                              'Battery',
                              '${sensorData.battery}%',
                              Icons.battery_full,
                              Colors.teal,
                            ),
                          ),
                        if (sensorData.battery != null && sensorData.rssi != null)
                          const SizedBox(width: 12),
                        if (sensorData.rssi != null)
                          Expanded(
                            child: _buildSensorCard(
                              'WiFi Signal',
                              '${sensorData.rssi} dBm',
                              Icons.wifi,
                              Colors.indigo,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<List<DeviceData>>(
      stream: _firebaseService.getAllDevices(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return const Center(child: Text('No devices available'));
        }

        // Show alerts for first device
        final device = devices.first;
        
        return StreamBuilder<List<AlertData>>(
          stream: _firebaseService.getDeviceAlerts(device.deviceId),
          builder: (context, alertSnapshot) {
            if (alertSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final alerts = alertSnapshot.data ?? [];
            
            if (alerts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No alerts'),
                    Text('All sensor readings are within normal ranges'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(alert);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlertCard(AlertData alert) {
    final isAcknowledged = alert.acknowledged;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isAcknowledged ? null : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAcknowledged ? Icons.check_circle : Icons.warning,
                  color: isAcknowledged ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isAcknowledged ? null : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatDateTime(alert.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Value: ${alert.value.toStringAsFixed(1)} (Threshold: ${alert.threshold.toStringAsFixed(1)})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (!isAcknowledged) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _acknowledgeAlert(alert),
                child: const Text('Acknowledge'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeviceControls(DeviceData device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Device Controls - ${device.deviceName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Restart Device'),
              onTap: () => _sendCommand(device.deviceId, 'restart', true),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Toggle LED'),
              onTap: () => _sendCommand(device.deviceId, 'ledEnabled', true),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Calibrate Sensors'),
              onTap: () => _sendCommand(device.deviceId, 'calibrate', true),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveData(DeviceData device) {
    // Navigate to detailed view or show in dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing live data for ${device.deviceName}')),
    );
  }

  Future<void> _sendCommand(String deviceId, String command, dynamic value) async {
    Navigator.pop(context); // Close bottom sheet
    
    final success = await _firebaseService.sendDeviceCommand(deviceId, command, value);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Command sent successfully' : 'Failed to send command'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _acknowledgeAlert(AlertData alert) async {
    final success = await _firebaseService.acknowledgeAlert(alert.deviceId, alert.alertId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Alert acknowledged' : 'Failed to acknowledge alert'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
