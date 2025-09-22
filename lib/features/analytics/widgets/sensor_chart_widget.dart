import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/historical_data_model.dart';

class SensorChartWidget extends StatelessWidget {
  final List<HistoricalDataPoint> data;
  final SensorType sensorType;
  final String title;
  final Color color;
  final double? minY;
  final double? maxY;

  const SensorChartWidget({
    super.key,
    required this.data,
    required this.sensorType,
    required this.title,
    required this.color,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildNoDataWidget(context);
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(),
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
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
                            '${value.toStringAsFixed(1)}${sensorType.unit}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calculateInterval(),
                        getTitlesWidget: (value, meta) {
                          return _getBottomTitle(value);
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
                    horizontalInterval: _calculateHorizontalInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dataPoint = data[spot.spotIndex];
                          return LineTooltipItem(
                            '${_getValue(dataPoint).toStringAsFixed(1)}${sensorType.unit}\n',
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: _formatTime(dataPoint.timestamp),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có dữ liệu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu ${title.toLowerCase()} cho khoảng thời gian này',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i.toDouble();
      final y = _getValue(point);
      spots.add(FlSpot(x, y));
    }
    
    return spots;
  }

  double _getValue(HistoricalDataPoint point) {
    switch (sensorType) {
      case SensorType.temperature:
        return point.temperature;
      case SensorType.humidity:
        return point.humidity;
      case SensorType.airQuality:
        return point.airQuality;
      case SensorType.pm25:
        return point.pm25 ?? 0;
      case SensorType.pm10:
        return point.pm10 ?? 0;
      case SensorType.co2:
        return point.co2 ?? 0;
    }
  }

  double _calculateInterval() {
    if (data.length <= 5) return 1;
    return (data.length / 5).ceilToDouble();
  }

  double _calculateHorizontalInterval() {
    if (data.isEmpty) return 1;
    
    final values = data.map(_getValue).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }

  Widget _getBottomTitle(double value) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const Text('');
    }
    
    final timestamp = data[index].timestamp;
    return Text(
      _formatAxisTime(timestamp),
      style: const TextStyle(fontSize: 10),
    );
  }

  String _formatAxisTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
