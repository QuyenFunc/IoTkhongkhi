import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/report_service.dart';
import '../../devices/services/device_service.dart';
import '../../../shared/models/device_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final DeviceService _deviceService = DeviceService();
  
  DeviceModel? _selectedDevice;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device Selection
            _buildDeviceSelectionCard(theme),
            
            const SizedBox(height: 16),
            
            // Date Range Selection
            _buildDateRangeCard(theme),
            
            const SizedBox(height: 16),
            
            // Report Options
            _buildReportOptionsCard(theme),
            
            const SizedBox(height: 24),
            
            // Generate Buttons
            _buildGenerateButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelectionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn thiết bị',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<DeviceModel>>(
              stream: _deviceService.getUserDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}');
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return const Text('Không có thiết bị nào');
                }

                return DropdownButtonFormField<DeviceModel>(
                  value: _selectedDevice,
                  decoration: const InputDecoration(
                    labelText: 'Thiết bị',
                    border: OutlineInputBorder(),
                  ),
                  items: devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Text('${device.name} (${device.location})'),
                    );
                  }).toList(),
                  onChanged: (device) {
                    setState(() {
                      _selectedDevice = device;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khoảng thời gian',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Từ ngày',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Đến ngày',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('7 ngày qua'),
                  selected: _isDateRangeSelected(7),
                  onSelected: (selected) => _setDateRange(7),
                ),
                FilterChip(
                  label: const Text('30 ngày qua'),
                  selected: _isDateRangeSelected(30),
                  onSelected: (selected) => _setDateRange(30),
                ),
                FilterChip(
                  label: const Text('90 ngày qua'),
                  selected: _isDateRangeSelected(90),
                  onSelected: (selected) => _setDateRange(90),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOptionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tùy chọn báo cáo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Báo cáo sẽ bao gồm:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('• Tóm tắt thống kê'),
            const Text('• Biểu đồ xu hướng'),
            const Text('• Dữ liệu chi tiết'),
            const Text('• Phân tích chất lượng không khí'),
            const SizedBox(height: 16),
            if (_selectedDevice != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Báo cáo cho thiết bị "${_selectedDevice!.name}" từ ${_formatDate(_startDate)} đến ${_formatDate(_endDate)}',
                        style: const TextStyle(color: Colors.blue),
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

  Widget _buildGenerateButtons(ThemeData theme) {
    final canGenerate = _selectedDevice != null && !_isGenerating;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? () => _generateReport('pdf') : null,
            icon: _isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGenerating ? 'Đang tạo báo cáo...' : 'Tạo báo cáo PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: canGenerate ? () => _generateReport('csv') : null,
            icon: const Icon(Icons.table_chart),
            label: const Text('Xuất dữ liệu CSV'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _endDate,
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _setDateRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
    });
  }

  bool _isDateRangeSelected(int days) {
    final now = DateTime.now();
    final expectedStart = now.subtract(Duration(days: days));
    
    return _startDate.difference(expectedStart).inDays.abs() <= 1 &&
           _endDate.difference(now).inDays.abs() <= 1;
  }

  Future<void> _generateReport(String type) async {
    if (_selectedDevice == null) return;

    setState(() => _isGenerating = true);

    try {
      // Get sensor data
      final data = await _reportService.getSensorData(
        deviceId: _selectedDevice!.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có dữ liệu trong khoảng thời gian này'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generate report
      late final file;
      if (type == 'pdf') {
        file = await _reportService.generatePDFReport(
          device: _selectedDevice!,
          startDate: _startDate,
          endDate: _endDate,
          data: data,
        );
      } else {
        file = await _reportService.generateCSVReport(
          device: _selectedDevice!,
          startDate: _startDate,
          endDate: _endDate,
          data: data,
        );
      }

      // Share report
      await _reportService.shareReport(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo báo cáo ${type.toUpperCase()} thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating report: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
