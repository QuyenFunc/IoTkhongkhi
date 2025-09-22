import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

/// Widget hiển thị dữ liệu cảm biến
class SensorDataCard extends StatelessWidget {
  final SensorData sensorData;

  const SensorDataCard({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sensors,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dữ Liệu Cảm Biến',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (sensorData.timestamp > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cập nhật: ' + _formatTime(sensorData.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!sensorData.isValid)
              const _NoDataWidget()
            else
              Column(
                children: [
                  // Temperature
                  _SensorValueRow(
                    icon: Icons.thermostat,
                    label: 'Nhiệt Độ',
                    value: '${sensorData.temperature.toStringAsFixed(1)}°C',
                    color: _getTemperatureColor(sensorData.temperature),
                  ),
                  const SizedBox(height: 12),
                  
                  // Humidity
                  _SensorValueRow(
                    icon: Icons.water_drop,
                    label: 'Độ Ẩm',
                    value: '${sensorData.humidity.toStringAsFixed(1)}%',
                    color: _getHumidityColor(sensorData.humidity),
                  ),
                  const SizedBox(height: 12),
                  
                  // Air Quality (PM2.5)
                  _SensorValueRow(
                    icon: Icons.air,
                    label: 'Chất Lượng KK (PM2.5)',
                    value: '${sensorData.pm25.toStringAsFixed(1)} μg/m³',
                    color: Color(int.parse(sensorData.airQualityColor.substring(1), radix: 16) + 0xFF000000),
                    subtitle: sensorData.airQualityLevel,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    var diff = now.difference(dateTime);
    
    // Nếu thời gian ở tương lai do lệch NTP, hiển thị "Vừa xong"
    if (diff.isNegative) {
      return 'Vừa xong';
    }

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s trước';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}p trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h trước';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.orange;
    if (humidity < 60) return Colors.green;
    if (humidity < 80) return Colors.blue;
    return Colors.red;
  }
}

/// Widget hiển thị một dòng giá trị cảm biến
class _SensorValueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _SensorValueRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
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
    );
  }
}

/// Widget hiển thị khi không có dữ liệu
class _NoDataWidget extends StatelessWidget {
  const _NoDataWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.sensors_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ESP32 chưa gửi dữ liệu',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
        ],
      ),
    );
  }
}
