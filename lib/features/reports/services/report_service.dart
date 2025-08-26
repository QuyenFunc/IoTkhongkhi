import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../shared/models/device_model.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Generate PDF report for device data
  Future<File> generatePDFReport({
    required DeviceModel device,
    required DateTime startDate,
    required DateTime endDate,
    required List<SensorDataPoint> data,
  }) async {
    final pdf = pw.Document();

    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildReportHeader(device, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildSummarySection(data),
            pw.SizedBox(height: 20),
            _buildDataTable(data),
            pw.SizedBox(height: 20),
            _buildStatisticsSection(data),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'air_quality_report_${device.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    
    if (kDebugMode) {
      print('✅ PDF report generated: ${file.path}');
    }
    
    return file;
  }

  /// Generate CSV report for device data
  Future<File> generateCSVReport({
    required DeviceModel device,
    required DateTime startDate,
    required DateTime endDate,
    required List<SensorDataPoint> data,
  }) async {
    final List<List<dynamic>> csvData = [
      // Header row
      [
        'Timestamp',
        'Temperature (°C)',
        'Humidity (%)',
        'PM2.5 (μg/m³)',
        'PM10 (μg/m³)',
        'CO2 (ppm)',
        'VOC (ppb)',
        'AQI',
      ],
    ];

    // Data rows
    for (final point in data) {
      csvData.add([
        point.timestamp.toIso8601String(),
        point.temperature,
        point.humidity,
        point.pm25,
        point.pm10,
        point.co2,
        point.voc,
        point.aqi,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'air_quality_data_${device.name}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvString);
    
    if (kDebugMode) {
      print('✅ CSV report generated: ${file.path}');
    }
    
    return file;
  }

  /// Share report file
  Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Báo cáo chất lượng không khí từ AirQuality',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sharing report: $e');
      }
      rethrow;
    }
  }

  /// Get sensor data for date range
  Future<List<SensorDataPoint>> getSensorData({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _database
          .ref('devices')
          .child(deviceId)
          .child('history')
          .orderByChild('timestamp')
          .startAt(startDate.toIso8601String())
          .endAt(endDate.toIso8601String())
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final dataPoints = <SensorDataPoint>[];
      data.forEach((key, value) {
        try {
          final pointData = Map<String, dynamic>.from(value);
          dataPoints.add(SensorDataPoint.fromJson(pointData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing data point: $e');
          }
        }
      });

      // Sort by timestamp
      dataPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return dataPoints;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting sensor data: $e');
      }
      return [];
    }
  }

  /// Build PDF report header
  pw.Widget _buildReportHeader(DeviceModel device, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Báo cáo chất lượng không khí',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Thiết bị: ${device.name}'),
        pw.Text('Vị trí: ${device.location}'),
        pw.Text('Từ ngày: ${_formatDate(startDate)}'),
        pw.Text('Đến ngày: ${_formatDate(endDate)}'),
        pw.Text('Tạo lúc: ${_formatDateTime(DateTime.now())}'),
      ],
    );
  }

  /// Build summary section
  pw.Widget _buildSummarySection(List<SensorDataPoint> data) {
    if (data.isEmpty) {
      return pw.Text('Không có dữ liệu trong khoảng thời gian này');
    }

    final stats = _calculateStatistics(data);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tóm tắt',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Thông số')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Trung bình')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tối thiểu')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tối đa')),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Nhiệt độ (°C)')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.avgTemperature.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.minTemperature.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.maxTemperature.toStringAsFixed(1))),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Độ ẩm (%)')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.avgHumidity.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.minHumidity.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.maxHumidity.toStringAsFixed(1))),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('PM2.5 (μg/m³)')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.avgPM25.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.minPM25.toStringAsFixed(1))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(stats.maxPM25.toStringAsFixed(1))),
            ]),
          ],
        ),
      ],
    );
  }

  /// Build data table
  pw.Widget _buildDataTable(List<SensorDataPoint> data) {
    if (data.isEmpty) return pw.Container();

    // Show only first 50 data points to avoid huge PDFs
    final displayData = data.take(50).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dữ liệu chi tiết (${displayData.length} điểm đầu tiên)',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Thời gian', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nhiệt độ', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Độ ẩm', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PM2.5', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('AQI', style: pw.TextStyle(fontSize: 8))),
            ]),
            ...displayData.map((point) => pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatDateTime(point.timestamp), style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${point.temperature.toStringAsFixed(1)}°C', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${point.humidity.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(point.pm25.toStringAsFixed(1), style: pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(point.aqi.toString(), style: pw.TextStyle(fontSize: 8))),
            ])),
          ],
        ),
      ],
    );
  }

  /// Build statistics section
  pw.Widget _buildStatisticsSection(List<SensorDataPoint> data) {
    if (data.isEmpty) return pw.Container();

    final stats = _calculateStatistics(data);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Thống kê',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Tổng số điểm dữ liệu: ${data.length}'),
        pw.Text('AQI trung bình: ${stats.avgAQI.toStringAsFixed(0)}'),
        pw.Text('Chất lượng không khí: ${_getAQIDescription(stats.avgAQI)}'),
      ],
    );
  }

  /// Calculate statistics from data
  DataStatistics _calculateStatistics(List<SensorDataPoint> data) {
    if (data.isEmpty) return DataStatistics.empty();

    double sumTemp = 0, sumHumidity = 0, sumPM25 = 0, sumAQI = 0;
    double minTemp = data.first.temperature, maxTemp = data.first.temperature;
    double minHumidity = data.first.humidity, maxHumidity = data.first.humidity;
    double minPM25 = data.first.pm25, maxPM25 = data.first.pm25;

    for (final point in data) {
      sumTemp += point.temperature;
      sumHumidity += point.humidity;
      sumPM25 += point.pm25;
      sumAQI += point.aqi;

      if (point.temperature < minTemp) minTemp = point.temperature;
      if (point.temperature > maxTemp) maxTemp = point.temperature;
      if (point.humidity < minHumidity) minHumidity = point.humidity;
      if (point.humidity > maxHumidity) maxHumidity = point.humidity;
      if (point.pm25 < minPM25) minPM25 = point.pm25;
      if (point.pm25 > maxPM25) maxPM25 = point.pm25;
    }

    return DataStatistics(
      avgTemperature: sumTemp / data.length,
      minTemperature: minTemp,
      maxTemperature: maxTemp,
      avgHumidity: sumHumidity / data.length,
      minHumidity: minHumidity,
      maxHumidity: maxHumidity,
      avgPM25: sumPM25 / data.length,
      minPM25: minPM25,
      maxPM25: maxPM25,
      avgAQI: sumAQI / data.length,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getAQIDescription(double aqi) {
    if (aqi <= 50) return 'Tốt';
    if (aqi <= 100) return 'Trung bình';
    if (aqi <= 150) return 'Không tốt cho nhóm nhạy cảm';
    if (aqi <= 200) return 'Không tốt';
    if (aqi <= 300) return 'Rất không tốt';
    return 'Nguy hiểm';
  }

  /// Delete old report files
  Future<void> cleanupOldReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && (file.path.contains('air_quality_report_') || file.path.contains('air_quality_data_'))) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          // Delete files older than 30 days
          if (age.inDays > 30) {
            await file.delete();
            if (kDebugMode) {
              print('🗑️ Deleted old report: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up old reports: $e');
      }
    }
  }
}

/// Sensor data point model
class SensorDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final double co2;
  final double voc;
  final int aqi;

  const SensorDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.pm10,
    required this.co2,
    required this.voc,
    required this.aqi,
  });

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      pm25: (json['pm25'] ?? 0.0).toDouble(),
      pm10: (json['pm10'] ?? 0.0).toDouble(),
      co2: (json['co2'] ?? 0.0).toDouble(),
      voc: (json['voc'] ?? 0.0).toDouble(),
      aqi: (json['aqi'] ?? 0).toInt(),
    );
  }
}

/// Data statistics model
class DataStatistics {
  final double avgTemperature;
  final double minTemperature;
  final double maxTemperature;
  final double avgHumidity;
  final double minHumidity;
  final double maxHumidity;
  final double avgPM25;
  final double minPM25;
  final double maxPM25;
  final double avgAQI;

  const DataStatistics({
    required this.avgTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.avgHumidity,
    required this.minHumidity,
    required this.maxHumidity,
    required this.avgPM25,
    required this.minPM25,
    required this.maxPM25,
    required this.avgAQI,
  });

  factory DataStatistics.empty() {
    return const DataStatistics(
      avgTemperature: 0,
      minTemperature: 0,
      maxTemperature: 0,
      avgHumidity: 0,
      minHumidity: 0,
      maxHumidity: 0,
      avgPM25: 0,
      minPM25: 0,
      maxPM25: 0,
      avgAQI: 0,
    );
  }
}
