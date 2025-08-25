import 'package:flutter/material.dart';
import '../../../shared/models/device_model.dart' as device_models;
import '../services/device_service.dart';
// QR Setup temporarily disabled - using placeholder models
import '../models/qr_setup_models_disabled.dart';

class DeviceDetailScreen extends StatefulWidget {
  final device_models.DeviceModel device;

  const DeviceDetailScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  final DeviceService _deviceService = DeviceService();
  late TabController _tabController;

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
        title: Text(widget.device.name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDeviceSettings,
            tooltip: 'Device Settings',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showDeviceMenu,
            tooltip: 'More options',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Live Data', icon: Icon(Icons.sensors)),
            Tab(text: 'History', icon: Icon(Icons.timeline)),
            Tab(text: 'Alerts', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveDataTab(theme),
          _buildHistoryTab(theme),
          _buildAlertsTab(theme),
        ],
      ),
    );
  }

  Widget _buildLiveDataTab(ThemeData theme) {
    return StreamBuilder<CurrentSensorData?>(
      stream: _deviceService.getDeviceSensorData(widget.device.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(theme, 'Error loading sensor data');
        }

        final sensorData = snapshot.data;
        if (sensorData == null) {
          return _buildNoDataState(theme);
        }

        return _buildSensorDataView(sensorData.toSensorData(), theme);
      },
    );
  }

  Widget _buildSensorDataView(SensorData sensorData, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by the stream
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildStatusHeader(sensorData, theme),
            
            const SizedBox(height: 24),
            
            // Main Metrics Grid
            _buildMetricsGrid(sensorData, theme),
            
            const SizedBox(height: 24),
            
            // Air Quality Index
            _buildAirQualityCard(sensorData, theme),
            
            const SizedBox(height: 24),
            
            // Alerts Section
            if (sensorData.hasAlerts) _buildAlertsSection(sensorData, theme),
            
            const SizedBox(height: 16),
            
            // Last Updated
            _buildLastUpdated(sensorData, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(SensorData sensorData, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.device.status == device_models.DeviceStatus.active
                  ? Colors.green
                  : Colors.red,
              radius: 24,
              child: Icon(
                widget.device.status == device_models.DeviceStatus.active
                    ? Icons.sensors
                    : Icons.sensors_off,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.device.location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sensorData.airQualityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sensorData.airQualityLevel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: sensorData.airQualityColor,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildMetricsGrid(SensorData sensorData, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Temperature',
          '${sensorData.temperature.toStringAsFixed(1)}°C',
          Icons.thermostat,
          _getTemperatureColor(sensorData.temperature),
          theme,
        ),
        _buildMetricCard(
          'Humidity',
          '${sensorData.humidity.toStringAsFixed(1)}%',
          Icons.water_drop,
          _getHumidityColor(sensorData.humidity),
          theme,
        ),
        _buildMetricCard(
          'PM2.5',
          '${sensorData.pm25.toStringAsFixed(1)} μg/m³',
          Icons.air,
          _getPM25Color(sensorData.pm25),
          theme,
        ),
        _buildMetricCard(
          'PM10',
          '${sensorData.pm10.toStringAsFixed(1)} μg/m³',
          Icons.cloud,
          _getPM10Color(sensorData.pm10),
          theme,
        ),
        _buildMetricCard(
          'CO2',
          '${sensorData.co2.toStringAsFixed(0)} ppm',
          Icons.co2,
          _getCO2Color(sensorData.co2),
          theme,
        ),
        _buildMetricCard(
          'VOC',
          '${sensorData.voc.toStringAsFixed(0)} ppb',
          Icons.science,
          _getVOCColor(sensorData.voc),
          theme,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityCard(SensorData sensorData, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Air Quality Index',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorData.aqi.toString(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: sensorData.airQualityColor,
                        ),
                      ),
                      Text(
                        sensorData.airQualityLevel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: sensorData.airQualityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: sensorData.aqi / 500,
                  backgroundColor: theme.colorScheme.outline,
                  valueColor: AlwaysStoppedAnimation<Color>(sensorData.airQualityColor),
                  strokeWidth: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(SensorData sensorData, ThemeData theme) {
    final activeAlerts = sensorData.alerts.entries
        .where((entry) => entry.value)
        .toList();

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Alerts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activeAlerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${_getAlertMessage(alert.key)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(SensorData sensorData, ThemeData theme) {
    return Center(
      child: Text(
        'Last updated: ${_formatTimestamp(sensorData.timestamp)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return const Center(
      child: Text('History view coming soon'),
    );
  }

  Widget _buildAlertsTab(ThemeData theme) {
    return StreamBuilder<List<DeviceAlert>>(
      stream: _deviceService.getDeviceAlerts(widget.device.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return const Center(
            child: Text('No alerts'),
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
    );
  }

  Widget _buildAlertCard(DeviceAlert alert, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAlertSeverityColor(alert.severity),
          child: Icon(
            _getAlertIcon(alert.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(alert.message),
        subtitle: Text(_formatTimestamp(alert.timestamp)),
        trailing: alert.isRead ? null : Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Device is not sending data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeviceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device settings coming soon')),
    );
  }

  void _showDeviceMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device menu coming soon')),
    );
  }

  // Helper methods for colors
  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.orange;
    if (humidity < 70) return Colors.green;
    return Colors.blue;
  }

  Color _getPM25Color(double pm25) {
    if (pm25 < 12) return Colors.green;
    if (pm25 < 35) return Colors.yellow;
    if (pm25 < 55) return Colors.orange;
    return Colors.red;
  }

  Color _getPM10Color(double pm10) {
    if (pm10 < 20) return Colors.green;
    if (pm10 < 50) return Colors.yellow;
    if (pm10 < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getCO2Color(double co2) {
    if (co2 < 400) return Colors.green;
    if (co2 < 1000) return Colors.yellow;
    if (co2 < 2000) return Colors.orange;
    return Colors.red;
  }

  Color _getVOCColor(double voc) {
    if (voc < 100) return Colors.green;
    if (voc < 300) return Colors.yellow;
    if (voc < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getAlertSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.highTemperature:
      case AlertType.lowTemperature:
        return Icons.thermostat;
      case AlertType.highHumidity:
      case AlertType.lowHumidity:
        return Icons.water_drop;
      case AlertType.highPM25:
      case AlertType.highPM10:
        return Icons.air;
      case AlertType.highCO2:
        return Icons.co2;
      case AlertType.highVOC:
        return Icons.science;
      case AlertType.deviceOffline:
        return Icons.wifi_off;
      case AlertType.deviceError:
        return Icons.error;
      case AlertType.batteryLow:
        return Icons.battery_alert;
      case AlertType.other:
        return Icons.warning;
    }
  }

  String _getAlertMessage(String alertKey) {
    switch (alertKey) {
      case 'highTemperature':
        return 'High temperature detected';
      case 'lowTemperature':
        return 'Low temperature detected';
      case 'highHumidity':
        return 'High humidity detected';
      case 'lowHumidity':
        return 'Low humidity detected';
      case 'highPM25':
        return 'High PM2.5 levels detected';
      case 'highPM10':
        return 'High PM10 levels detected';
      case 'highCO2':
        return 'High CO2 levels detected';
      case 'highVOC':
        return 'High VOC levels detected';
      default:
        return 'Alert: $alertKey';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
