import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../analytics/models/historical_data_model.dart';
import '../../analytics/services/analytics_service.dart';
import '../../../shared/models/device_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();

  /// Export sensor data to CSV format
  Future<String> exportToCSV({
    required DeviceModel device,
    required TimeRange timeRange,
    List<SensorType>? sensorTypes,
  }) async {
    try {
      // Get historical data
      final data = await _analyticsService.getHistoricalData(
        deviceId: device.id,
        timeRange: timeRange,
      );

      if (data.isEmpty) {
        throw Exception('Không có dữ liệu để xuất');
      }

      // Prepare CSV data
      final List<List<dynamic>> csvData = [];
      
      // Header row
      final headers = ['Thời gian'];
      final selectedTypes = sensorTypes ?? SensorType.values;
      
      for (final type in selectedTypes) {
        headers.add('${type.label} (${type.unit})');
      }
      headers.add('Trạng thái');
      csvData.add(headers);

      // Data rows
      for (final point in data) {
        final row = <dynamic>[
          _formatDateTime(point.timestamp),
        ];
        
        for (final type in selectedTypes) {
          switch (type) {
            case SensorType.temperature:
              row.add(point.temperature.toStringAsFixed(1));
              break;
            case SensorType.humidity:
              row.add(point.humidity.toStringAsFixed(1));
              break;
            case SensorType.airQuality:
              row.add(point.airQuality.toStringAsFixed(1));
              break;
            case SensorType.pm25:
              row.add(point.pm25?.toStringAsFixed(1) ?? 'N/A');
              break;
            case SensorType.pm10:
              row.add(point.pm10?.toStringAsFixed(1) ?? 'N/A');
              break;
            case SensorType.co2:
              row.add(point.co2?.toStringAsFixed(1) ?? 'N/A');
              break;
          }
        }
        
        row.add(point.status);
        csvData.add(row);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Add BOM for proper UTF-8 encoding in Excel
      final bom = '\uFEFF';
      return bom + csvString;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting to CSV: $e');
      }
      rethrow;
    }
  }

  /// Export sensor data to PDF format
  Future<Uint8List> exportToPDF({
    required DeviceModel device,
    required TimeRange timeRange,
    List<SensorType>? sensorTypes,
  }) async {
    try {
      // Get historical data
      final data = await _analyticsService.getHistoricalData(
        deviceId: device.id,
        timeRange: timeRange,
      );

      // Get statistics
      final statistics = await _analyticsService.getStatistics(
        deviceId: device.id,
        timeRange: timeRange,
      );

      if (data.isEmpty) {
        throw Exception('Không có dữ liệu để xuất');
      }

      final pdf = pw.Document();
      final selectedTypes = sensorTypes ?? [
        SensorType.temperature,
        SensorType.humidity,
        SensorType.airQuality,
      ];

      // Add pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              _buildPDFHeader(device, timeRange),
              pw.SizedBox(height: 20),
              
              // Summary statistics
              _buildPDFSummary(statistics, selectedTypes),
              pw.SizedBox(height: 20),
              
              // Data table
              _buildPDFDataTable(data, selectedTypes),
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting to PDF: $e');
      }
      rethrow;
    }
  }

  /// Save and share CSV file
  Future<void> saveAndShareCSV({
    required DeviceModel device,
    required TimeRange timeRange,
    List<SensorType>? sensorTypes,
  }) async {
    try {
      final csvContent = await exportToCSV(
        device: device,
        timeRange: timeRange,
        sensorTypes: sensorTypes,
      );

      final fileName = _generateFileName(device, timeRange, 'csv');
      
      if (kIsWeb) {
        // For web platform, trigger download
        await _downloadFileWeb(csvContent, fileName, 'text/csv');
      } else {
        // For mobile platforms, save and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent, encoding: utf8);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Dữ liệu cảm biến - ${device.name}',
          text: 'Báo cáo dữ liệu cảm biến cho khoảng thời gian ${timeRange.label}',
        );
      }

      if (kDebugMode) {
        print('CSV exported successfully: $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving/sharing CSV: $e');
      }
      rethrow;
    }
  }

  /// Save and share PDF file
  Future<void> saveAndSharePDF({
    required DeviceModel device,
    required TimeRange timeRange,
    List<SensorType>? sensorTypes,
  }) async {
    try {
      final pdfBytes = await exportToPDF(
        device: device,
        timeRange: timeRange,
        sensorTypes: sensorTypes,
      );

      final fileName = _generateFileName(device, timeRange, 'pdf');
      
      if (kIsWeb) {
        // For web platform, trigger download
        await _downloadFileWeb(
          String.fromCharCodes(pdfBytes),
          fileName,
          'application/pdf',
        );
      } else {
        // For mobile platforms, save and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Báo cáo dữ liệu cảm biến - ${device.name}',
          text: 'Báo cáo PDF dữ liệu cảm biến cho khoảng thời gian ${timeRange.label}',
        );
      }

      if (kDebugMode) {
        print('PDF exported successfully: $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving/sharing PDF: $e');
      }
      rethrow;
    }
  }

  /// Print PDF report
  Future<void> printPDF({
    required DeviceModel device,
    required TimeRange timeRange,
    List<SensorType>? sensorTypes,
  }) async {
    try {
      final pdfBytes = await exportToPDF(
        device: device,
        timeRange: timeRange,
        sensorTypes: sensorTypes,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Báo cáo cảm biến - ${device.name}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error printing PDF: $e');
      }
      rethrow;
    }
  }

  // PDF Building Methods
  pw.Widget _buildPDFHeader(DeviceModel device, TimeRange timeRange) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BÁO CÁO DỮ LIỆU CẢM BIẾN',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thiết bị: ${device.name}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Vị trí: ${device.location}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Khoảng thời gian: ${timeRange.label}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Ngày xuất: ${_formatDateTime(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPDFSummary(
    Map<String, double> statistics,
    List<SensorType> sensorTypes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'THỐNG KÊ TỔNG QUAN',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header row
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Cảm biến', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Trung bình', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Thấp nhất', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Cao nhất', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Data rows
            ...sensorTypes.map((type) {
              final key = type.name;
              final avg = statistics['${key}_avg'] ?? 0;
              final min = statistics['${key}_min'] ?? 0;
              final max = statistics['${key}_max'] ?? 0;
              
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${type.label} (${type.unit})'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(avg.toStringAsFixed(1)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(min.toStringAsFixed(1)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(max.toStringAsFixed(1)),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFDataTable(
    List<HistoricalDataPoint> data,
    List<SensorType> sensorTypes,
  ) {
    // Limit data to first 100 points for PDF
    final limitedData = data.take(100).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DỮ LIỆU CHI TIẾT (${limitedData.length} điểm đầu)',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FixedColumnWidth(80),
            ...Map.fromIterables(
              List.generate(sensorTypes.length, (i) => i + 1),
              List.generate(sensorTypes.length, (i) => const pw.FlexColumnWidth()),
            ),
          },
          children: [
            // Header row
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    'Thời gian',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                ...sensorTypes.map((type) => pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    type.label,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                )),
              ],
            ),
            // Data rows
            ...limitedData.map((point) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    _formatTimeOnly(point.timestamp),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                ...sensorTypes.map((type) {
                  double value;
                  switch (type) {
                    case SensorType.temperature:
                      value = point.temperature;
                      break;
                    case SensorType.humidity:
                      value = point.humidity;
                      break;
                    case SensorType.airQuality:
                      value = point.airQuality;
                      break;
                    case SensorType.pm25:
                      value = point.pm25 ?? 0;
                      break;
                    case SensorType.pm10:
                      value = point.pm10 ?? 0;
                      break;
                    case SensorType.co2:
                      value = point.co2 ?? 0;
                      break;
                  }
                  
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      value.toStringAsFixed(1),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  );
                }),
              ],
            )),
          ],
        ),
        if (data.length > 100) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Ghi chú: Chỉ hiển thị 100 điểm dữ liệu đầu tiên. Tổng cộng có ${data.length} điểm.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ],
    );
  }

  // Utility Methods
  String _generateFileName(DeviceModel device, TimeRange timeRange, String extension) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final deviceName = device.name.replaceAll(RegExp(r'[^\w\-_]'), '_');
    final timeRangeStr = timeRange.label.replaceAll(' ', '_');
    
    return '${deviceName}_${timeRangeStr}_$dateStr.$extension';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadFileWeb(String content, String fileName, String mimeType) async {
    // For web platform - this would need additional implementation
    // Using dart:html or similar web-specific APIs
    if (kDebugMode) {
      print('Web download not implemented: $fileName');
    }
    throw UnimplementedError('Web download not implemented yet');
  }
}
