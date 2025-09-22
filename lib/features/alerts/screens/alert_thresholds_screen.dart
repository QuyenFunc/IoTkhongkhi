import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_threshold_model.dart';
import '../services/alert_service.dart';
import '../../../shared/models/device_model.dart';

class AlertThresholdsScreen extends ConsumerStatefulWidget {
  final DeviceModel device;

  const AlertThresholdsScreen({
    super.key,
    required this.device,
  });

  @override
  ConsumerState<AlertThresholdsScreen> createState() => _AlertThresholdsScreenState();
}

class _AlertThresholdsScreenState extends ConsumerState<AlertThresholdsScreen> {
  final AlertService _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cảnh báo - ${widget.device.name}'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddThresholdDialog(),
            tooltip: 'Thêm ngưỡng cảnh báo',
          ),
        ],
      ),
      body: StreamBuilder<List<AlertThreshold>>(
        stream: _alertService.getDeviceThresholds(widget.device.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final thresholds = snapshot.data ?? [];

          if (thresholds.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: thresholds.length,
            itemBuilder: (context, index) {
              final threshold = thresholds[index];
              return _buildThresholdCard(threshold);
            },
          );
        },
      ),
    );
  }

  Widget _buildThresholdCard(AlertThreshold threshold) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIconForType(threshold.type),
                  color: _getColorForType(threshold.type),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        threshold.type.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Đơn vị: ${threshold.type.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: threshold.enabled,
                  onChanged: (value) => _toggleThreshold(threshold, value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Threshold values
            Row(
              children: [
                Expanded(
                  child: _buildValueCard(
                    'Giá trị tối thiểu',
                    '${threshold.minValue.toStringAsFixed(1)}${threshold.type.unit}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueCard(
                    'Giá trị tối đa',
                    '${threshold.maxValue.toStringAsFixed(1)}${threshold.type.unit}',
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _editThreshold(threshold),
                  child: const Text('Chỉnh sửa'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _deleteThreshold(threshold),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có ngưỡng cảnh báo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thiết lập ngưỡng cảnh báo để nhận thông báo khi các giá trị cảm biến vượt quá giới hạn an toàn',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddThresholdDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm ngưỡng cảnh báo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
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
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(AlertType type) {
    switch (type) {
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.humidity:
        return Icons.water_drop;
      case AlertType.airQuality:
      case AlertType.pm25:
      case AlertType.pm10:
        return Icons.air;
      case AlertType.co2:
        return Icons.cloud;
    }
  }

  Color _getColorForType(AlertType type) {
    switch (type) {
      case AlertType.temperature:
        return Colors.orange;
      case AlertType.humidity:
        return Colors.blue;
      case AlertType.airQuality:
      case AlertType.pm25:
      case AlertType.pm10:
        return Colors.green;
      case AlertType.co2:
        return Colors.purple;
    }
  }

  Future<void> _toggleThreshold(AlertThreshold threshold, bool enabled) async {
    try {
      final updatedThreshold = threshold.copyWith(
        enabled: enabled,
        updatedAt: DateTime.now(),
      );
      
      await _alertService.saveThreshold(updatedThreshold);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Đã bật cảnh báo' : 'Đã tắt cảnh báo',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editThreshold(AlertThreshold threshold) async {
    final result = await showDialog<AlertThreshold>(
      context: context,
      builder: (context) => _ThresholdEditDialog(threshold: threshold),
    );

    if (result != null) {
      try {
        await _alertService.saveThreshold(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ngưỡng cảnh báo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteThreshold(AlertThreshold threshold) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ngưỡng cảnh báo ${threshold.type.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _alertService.deleteThreshold(threshold.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ngưỡng cảnh báo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddThresholdDialog() async {
    final result = await showDialog<AlertThreshold>(
      context: context,
      builder: (context) => _ThresholdEditDialog(
        threshold: null,
        deviceId: widget.device.id,
      ),
    );

    if (result != null) {
      try {
        await _alertService.saveThreshold(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm ngưỡng cảnh báo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ThresholdEditDialog extends StatefulWidget {
  final AlertThreshold? threshold;
  final String? deviceId;

  const _ThresholdEditDialog({
    this.threshold,
    this.deviceId,
  });

  @override
  State<_ThresholdEditDialog> createState() => _ThresholdEditDialogState();
}

class _ThresholdEditDialogState extends State<_ThresholdEditDialog> {
  late AlertType _selectedType;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late bool _enabled;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    if (widget.threshold != null) {
      // Edit mode
      _selectedType = widget.threshold!.type;
      _minController = TextEditingController(
        text: widget.threshold!.minValue.toString(),
      );
      _maxController = TextEditingController(
        text: widget.threshold!.maxValue.toString(),
      );
      _enabled = widget.threshold!.enabled;
    } else {
      // Add mode
      _selectedType = AlertType.temperature;
      _minController = TextEditingController(
        text: _selectedType.defaultMin.toString(),
      );
      _maxController = TextEditingController(
        text: _selectedType.defaultMax.toString(),
      );
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.threshold != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Chỉnh sửa ngưỡng' : 'Thêm ngưỡng cảnh báo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type selector (only for new thresholds)
              if (!isEdit) ...[
                DropdownButtonFormField<AlertType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại cảm biến',
                    border: OutlineInputBorder(),
                  ),
                  items: AlertType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text('${type.displayName} (${type.unit})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        _minController.text = value.defaultMin.toString();
                        _maxController.text = value.defaultMax.toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Min value
              TextFormField(
                controller: _minController,
                decoration: InputDecoration(
                  labelText: 'Giá trị tối thiểu (${_selectedType.unit})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập giá trị tối thiểu';
                  }
                  final num = double.tryParse(value!);
                  if (num == null) {
                    return 'Giá trị không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Max value
              TextFormField(
                controller: _maxController,
                decoration: InputDecoration(
                  labelText: 'Giá trị tối đa (${_selectedType.unit})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập giá trị tối đa';
                  }
                  final num = double.tryParse(value!);
                  if (num == null) {
                    return 'Giá trị không hợp lệ';
                  }
                  final min = double.tryParse(_minController.text);
                  if (min != null && num <= min) {
                    return 'Giá trị tối đa phải lớn hơn giá trị tối thiểu';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Enabled switch
              SwitchListTile(
                title: const Text('Kích hoạt cảnh báo'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saveThreshold,
          child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }

  void _saveThreshold() {
    if (!_formKey.currentState!.validate()) return;

    final minValue = double.parse(_minController.text);
    final maxValue = double.parse(_maxController.text);

    final threshold = AlertThreshold(
      id: widget.threshold?.id ?? const Uuid().v4(),
      deviceId: widget.threshold?.deviceId ?? widget.deviceId!,
      userId: widget.threshold?.userId ?? '',
      type: _selectedType,
      minValue: minValue,
      maxValue: maxValue,
      enabled: _enabled,
      createdAt: widget.threshold?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, threshold);
  }
}
