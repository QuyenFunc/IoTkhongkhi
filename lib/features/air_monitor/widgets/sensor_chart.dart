import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data_model.dart';

class SensorChart extends StatelessWidget {
  final String title;
  final List<SensorData> data;
  final Color color;
  final String unit;

  const SensorChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Không có dữ liệu để hiển thị',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                _buildLineChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = _getChartSpots();
    
    return LineChartData(
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: _getMinY(),
      maxY: _getMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          preventCurveOverShooting: true,
          dotData: const FlDotData(
            show: false, // Bỏ dots để nhìn đẹp hơn
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (data.length / 5).ceil().toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                final dateTime = data[index].dateTime;
                return Text(
                  '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getGridInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => color.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index >= 0 && index < data.length) {
                final sensorData = data[index];
                final value = _getValue(sensorData);
                final time = sensorData.dateTime;
                
                return LineTooltipItem(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}\n'
                  '${value.toStringAsFixed(1)}$unit',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
        touchSpotThreshold: 50,
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final sensorData = entry.value;
      final value = _getValue(sensorData);
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  double _getValue(SensorData sensorData) {
    if (title.contains('Nhiệt')) {
      return sensorData.temperature;
    } else if (title.contains('Độ Ẩm')) {
      return sensorData.humidity;
    } else if (title.contains('PM2.5')) {
      return sensorData.pm25;
    }
    return 0.0;
  }

  double _getMinY() {
    if (data.isEmpty) return 0;
    
    final values = data.map(_getValue).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below
    final padding = (values.reduce((a, b) => a > b ? a : b) - minValue) * 0.1;
    return (minValue - padding).clamp(0, double.infinity);
  }

  double _getMaxY() {
    if (data.isEmpty) return 100;
    
    final values = data.map(_getValue).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above
    final padding = (maxValue - values.reduce((a, b) => a < b ? a : b)) * 0.1;
    return maxValue + padding;
  }

  double _getGridInterval() {
    final range = _getMaxY() - _getMinY();
    if (range <= 0) return 1.0; // Fallback để tránh lỗi
    
    // Chia thành 5 khoảng đều
    double interval = range / 5;
    
    // Làm tròn interval để số đẹp hơn
    if (interval < 1) {
      interval = 0.5;
    } else if (interval < 5) {
      interval = 1.0;
    } else if (interval < 10) {
      interval = 5.0;
    } else if (interval < 25) {
      interval = 10.0;
    } else {
      interval = (interval / 10).ceil() * 10.0;
    }
    
    return interval;
  }
}

/// Widget hiển thị thống kê tổng quan
class StatisticsCard extends StatelessWidget {
  final List<SensorData> data;

  const StatisticsCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final stats = _calculateStatistics();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Thống Kê Tổng Quan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    '🌡️ Nhiệt Độ',
                    'TB: ${stats['tempAvg']!.toStringAsFixed(1)}°C',
                    'Min: ${stats['tempMin']!.toStringAsFixed(1)}°C',
                    'Max: ${stats['tempMax']!.toStringAsFixed(1)}°C',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    '💧 Độ Ẩm',
                    'TB: ${stats['humAvg']!.toStringAsFixed(1)}%',
                    'Min: ${stats['humMin']!.toStringAsFixed(1)}%',
                    'Max: ${stats['humMax']!.toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    '🌪️ PM2.5',
                    'TB: ${stats['pm25Avg']!.toStringAsFixed(1)}',
                    'Min: ${stats['pm25Min']!.toStringAsFixed(1)}',
                    'Max: ${stats['pm25Max']!.toStringAsFixed(1)}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dataset, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số điểm dữ liệu: ${data.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
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

  Widget _buildStatColumn(String title, String avg, String min, String max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          avg,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          min,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          max,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Map<String, double> _calculateStatistics() {
    final temps = data.map((e) => e.temperature).toList();
    final hums = data.map((e) => e.humidity).toList();
    final pm25s = data.map((e) => e.pm25).toList();

    return {
      'tempMin': temps.reduce((a, b) => a < b ? a : b),
      'tempMax': temps.reduce((a, b) => a > b ? a : b),
      'tempAvg': temps.reduce((a, b) => a + b) / temps.length,
      
      'humMin': hums.reduce((a, b) => a < b ? a : b),
      'humMax': hums.reduce((a, b) => a > b ? a : b),
      'humAvg': hums.reduce((a, b) => a + b) / hums.length,
      
      'pm25Min': pm25s.reduce((a, b) => a < b ? a : b),
      'pm25Max': pm25s.reduce((a, b) => a > b ? a : b),
      'pm25Avg': pm25s.reduce((a, b) => a + b) / pm25s.length,
    };
  }
}
