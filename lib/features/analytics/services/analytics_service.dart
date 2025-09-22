import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/historical_data_model.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get historical sensor data for charts
  Future<List<HistoricalDataPoint>> getHistoricalData({
    required String deviceId,
    required TimeRange timeRange,
    int? maxPoints,
  }) async {
    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(timeRange.duration);

      final query = _database
          .ref('sensorData/$deviceId/history')
          .orderByChild('timestamp')
          .startAt(startTime.millisecondsSinceEpoch)
          .endAt(endTime.millisecondsSinceEpoch);

      final snapshot = await query.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final points = <HistoricalDataPoint>[];

      for (final entry in data.entries) {
        try {
          final pointData = Map<String, dynamic>.from(entry.value as Map);
          points.add(HistoricalDataPoint.fromFirebase(pointData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing data point: $e');
          }
          continue;
        }
      }

      // Sort by timestamp
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Limit points if specified
      if (maxPoints != null && points.length > maxPoints) {
        // Take evenly distributed points
        final step = points.length / maxPoints;
        final filtered = <HistoricalDataPoint>[];
        
        for (int i = 0; i < maxPoints; i++) {
          final index = (i * step).round();
          if (index < points.length) {
            filtered.add(points[index]);
          }
        }
        
        return filtered;
      }

      return points;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting historical data: $e');
      }
      return [];
    }
  }

  /// Get aggregated statistics for a time period
  Future<Map<String, double>> getStatistics({
    required String deviceId,
    required TimeRange timeRange,
  }) async {
    try {
      final data = await getHistoricalData(
        deviceId: deviceId,
        timeRange: timeRange,
      );

      if (data.isEmpty) {
        return {};
      }

      // Calculate statistics
      final temperatures = data.map((e) => e.temperature).toList();
      final humidities = data.map((e) => e.humidity).toList();
      final airQualities = data.map((e) => e.airQuality).toList();

      return {
        'temperature_avg': _calculateAverage(temperatures),
        'temperature_min': temperatures.reduce((a, b) => a < b ? a : b),
        'temperature_max': temperatures.reduce((a, b) => a > b ? a : b),
        'humidity_avg': _calculateAverage(humidities),
        'humidity_min': humidities.reduce((a, b) => a < b ? a : b),
        'humidity_max': humidities.reduce((a, b) => a > b ? a : b),
        'airQuality_avg': _calculateAverage(airQualities),
        'airQuality_min': airQualities.reduce((a, b) => a < b ? a : b),
        'airQuality_max': airQualities.reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating statistics: $e');
      }
      return {};
    }
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Get latest sensor reading
  Future<HistoricalDataPoint?> getLatestReading(String deviceId) async {
    try {
      final snapshot = await _database
          .ref('sensorData/$deviceId/latest')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return HistoricalDataPoint.fromFirebase(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting latest reading: $e');
      }
      return null;
    }
  }

  /// Export data to CSV format
  Future<String> exportToCSV({
    required String deviceId,
    required TimeRange timeRange,
  }) async {
    final data = await getHistoricalData(
      deviceId: deviceId,
      timeRange: timeRange,
    );

    if (data.isEmpty) {
      return 'No data available for the selected time range';
    }

    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Timestamp,Temperature(°C),Humidity(%),Air Quality(μg/m³),Status');
    
    // CSV Data
    for (final point in data) {
      buffer.writeln(
        '${point.timestamp.toIso8601String()},${point.temperature},${point.humidity},${point.airQuality},${point.status}'
      );
    }

    return buffer.toString();
  }
}
