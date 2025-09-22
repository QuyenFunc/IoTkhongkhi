import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/historical_data_model.dart';
import '../services/analytics_service.dart';
import '../widgets/sensor_chart_widget.dart';
import '../../../shared/models/device_model.dart';
import '../../reports/services/export_service.dart';

class HistoricalChartsScreen extends ConsumerStatefulWidget {
  final DeviceModel device;

  const HistoricalChartsScreen({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<HistoricalChartsScreen> createState() => _HistoricalChartsScreenState();
}

class _HistoricalChartsScreenState extends ConsumerState<HistoricalChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimeRange _selectedTimeRange = TimeRange.oneDay;
  List<HistoricalDataPoint> _data = [];
  Map<String, double> _statistics = {};
  bool _isLoading = false;
  String? _error;

  final AnalyticsService _analyticsService = AnalyticsService();
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _analyticsService.getHistoricalData(
        deviceId: widget.device.id,
        timeRange: _selectedTimeRange,
        maxPoints: 100, // Limit points for performance
      );

      final statistics = await _analyticsService.getStatistics(
        deviceId: widget.device.id,
        timeRange: _selectedTimeRange,
      );

      setState(() {
        _data = data;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử - ${widget.device.name}'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Biểu đồ', icon: Icon(Icons.show_chart)),
            Tab(text: 'Thống kê', icon: Icon(Icons.analytics)),
            Tab(text: 'Xuất dữ liệu', icon: Icon(Icons.file_download)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Time Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Khoảng thời gian:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TimeRange.values.map((range) {
                        final isSelected = _selectedTimeRange == range;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(range.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTimeRange = range;
                                });
                                _loadData();
                              }
                            },
                            selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: theme.colorScheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartsTab(),
                _buildStatisticsTab(),
                _buildExportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SensorChartWidget(
            data: _data,
            sensorType: SensorType.temperature,
            title: 'Nhiệt độ theo thời gian',
            color: Colors.orange,
          ),
          SensorChartWidget(
            data: _data,
            sensorType: SensorType.humidity,
            title: 'Độ ẩm theo thời gian',
            color: Colors.blue,
            minY: 0,
            maxY: 100,
          ),
          SensorChartWidget(
            data: _data,
            sensorType: SensorType.airQuality,
            title: 'Chất lượng không khí theo thời gian',
            color: Colors.green,
            minY: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_statistics.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu thống kê'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê cho ${_selectedTimeRange.label.toLowerCase()}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildStatisticSection(
            'Nhiệt độ (°C)',
            Icons.thermostat,
            Colors.orange,
            _statistics['temperature_avg'] ?? 0,
            _statistics['temperature_min'] ?? 0,
            _statistics['temperature_max'] ?? 0,
          ),
          
          const SizedBox(height: 16),
          
          _buildStatisticSection(
            'Độ ẩm (%)',
            Icons.water_drop,
            Colors.blue,
            _statistics['humidity_avg'] ?? 0,
            _statistics['humidity_min'] ?? 0,
            _statistics['humidity_max'] ?? 0,
          ),
          
          const SizedBox(height: 16),
          
          _buildStatisticSection(
            'Chất lượng không khí (μg/m³)',
            Icons.air,
            Colors.green,
            _statistics['airQuality_avg'] ?? 0,
            _statistics['airQuality_min'] ?? 0,
            _statistics['airQuality_max'] ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticSection(
    String title,
    IconData icon,
    Color color,
    double avg,
    double min,
    double max,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatValue('Trung bình', avg.toStringAsFixed(1)),
                _buildStatValue('Thấp nhất', min.toStringAsFixed(1)),
                _buildStatValue('Cao nhất', max.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatValue(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xuất dữ liệu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Xuất dữ liệu cảm biến cho khoảng thời gian: ${_selectedTimeRange.label.toLowerCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          _buildExportOption(
            'Xuất file CSV',
            'Tệp dữ liệu có thể mở bằng Excel',
            Icons.table_chart,
            () => _exportData('csv'),
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            'Xuất file PDF',
            'Báo cáo định dạng PDF',
            Icons.picture_as_pdf,
            () => _exportData('pdf'),
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            'In báo cáo',
            'In trực tiếp hoặc lưu PDF',
            Icons.print,
            _printReport,
          ),
          
          const SizedBox(height: 24),
          
          if (_data.isNotEmpty) ...[
            Text(
              'Thông tin xuất:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text('• Số điểm dữ liệu: ${_data.length}'),
            Text('• Khoảng thời gian: ${_selectedTimeRange.label}'),
            Text('• Thiết bị: ${widget.device.name}'),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Đã xảy ra lỗi không xác định',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String format) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xuất dữ liệu...'),
            ],
          ),
        ),
      );

      if (format == 'csv') {
        await _exportService.saveAndShareCSV(
          device: widget.device,
          timeRange: _selectedTimeRange,
          sensorTypes: [
            SensorType.temperature,
            SensorType.humidity,
            SensorType.airQuality,
          ],
        );
        
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất CSV thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (format == 'pdf') {
        await _exportService.saveAndSharePDF(
          device: widget.device,
          timeRange: _selectedTimeRange,
          sensorTypes: [
            SensorType.temperature,
            SensorType.humidity,
            SensorType.airQuality,
          ],
        );
        
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xuất PDF thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printReport() async {
    try {
      await _exportService.printPDF(
        device: widget.device,
        timeRange: _selectedTimeRange,
        sensorTypes: [
          SensorType.temperature,
          SensorType.humidity,
          SensorType.airQuality,
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi in báo cáo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
