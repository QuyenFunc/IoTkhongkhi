import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/device_pairing_service.dart';

class DeviceSensorDataWidget extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  
  const DeviceSensorDataWidget({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<DeviceSensorDataWidget> createState() => _DeviceSensorDataWidgetState();
}

class _DeviceSensorDataWidgetState extends State<DeviceSensorDataWidget> {
  final DevicePairingService _pairingService = DevicePairingService();
  Map<String, dynamic>? _sensorData;
  bool _isOnline = false;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _listenToSensorData();
  }

  void _listenToSensorData() {
    _pairingService.listenToDeviceData(widget.deviceId).listen(
      (data) {
        if (mounted) {
          setState(() {
            _sensorData = data;
            _isOnline = data != null && data['status'] == 'online';
            if (data != null && data['timestamp'] != null) {
              try {
                final timestamp = int.tryParse(data['timestamp'].toString());
                if (timestamp != null) {
                  _lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing timestamp: $e');
                }
              }
            }
          });
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to sensor data: $error');
        }
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
        }
      },
    );
  }

  Color _getAirQualityColor(double value) {
    if (value <= 50) return Colors.green;
    if (value <= 100) return Colors.yellow[700]!;
    if (value <= 150) return Colors.orange;
    return Colors.red;
  }

  String _getAirQualityStatus(double value) {
    if (value <= 50) return 'Good';
    if (value <= 100) return 'Moderate';
    if (value <= 150) return 'Unhealthy for Sensitive Groups';
    return 'Unhealthy';
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? status,
  }) {
    return Card(
      elevation: 4,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device header
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.deviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOnline ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_lastUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last update: ${_formatLastUpdate(_lastUpdate!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Sensor data
            if (_sensorData == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading sensor data...'),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          title: 'Temperature',
                          value: _sensorData!['temperature']?.toStringAsFixed(1) ?? '--',
                          unit: '°C',
                          icon: Icons.thermostat,
                          color: _getTemperatureColor(_sensorData!['temperature']?.toDouble() ?? 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSensorCard(
                          title: 'Humidity',
                          value: _sensorData!['humidity']?.toString() ?? '--',
                          unit: '%',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSensorCard(
                    title: 'Air Quality (PM2.5)',
                    value: _sensorData!['airQuality']?.toStringAsFixed(1) ?? '--',
                    unit: 'μg/m³',
                    icon: Icons.air,
                    color: _getAirQualityColor(_sensorData!['airQuality']?.toDouble() ?? 0),
                    status: _getAirQualityStatus(_sensorData!['airQuality']?.toDouble() ?? 0),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 18) return Colors.blue;
    if (temperature < 25) return Colors.green;
    if (temperature < 30) return Colors.orange;
    return Colors.red;
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
