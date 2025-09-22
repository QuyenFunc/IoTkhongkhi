import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/threshold_viewmodel.dart';

class ThresholdSettingsScreen extends StatefulWidget {
  const ThresholdSettingsScreen({super.key});

  @override
  State<ThresholdSettingsScreen> createState() => _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends State<ThresholdSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt Ngưỡng Cảnh Báo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ThresholdViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThresholdCard(
                title: 'Nhiệt Độ',
                icon: Icons.thermostat,
                color: Colors.orange,
                unit: '°C',
                minValue: viewModel.temperatureMin,
                maxValue: viewModel.temperatureMax,
                enabled: viewModel.temperatureEnabled,
                onMinChanged: (value) => viewModel.setTemperatureMin(value),
                onMaxChanged: (value) => viewModel.setTemperatureMax(value),
                onEnabledChanged: (value) => viewModel.setTemperatureEnabled(value),
              ),
              const SizedBox(height: 16),
              _buildThresholdCard(
                title: 'Độ Ẩm',
                icon: Icons.water_drop,
                color: Colors.blue,
                unit: '%',
                minValue: viewModel.humidityMin,
                maxValue: viewModel.humidityMax,
                enabled: viewModel.humidityEnabled,
                onMinChanged: (value) => viewModel.setHumidityMin(value),
                onMaxChanged: (value) => viewModel.setHumidityMax(value),
                onEnabledChanged: (value) => viewModel.setHumidityEnabled(value),
              ),
              const SizedBox(height: 16),
              _buildThresholdCard(
                title: 'Bụi PM2.5',
                icon: Icons.air,
                color: Colors.grey,
                unit: 'μg/m³',
                minValue: viewModel.pm25Min,
                maxValue: viewModel.pm25Max,
                enabled: viewModel.pm25Enabled,
                onMinChanged: (value) => viewModel.setPm25Min(value),
                onMaxChanged: (value) => viewModel.setPm25Max(value),
                onEnabledChanged: (value) => viewModel.setPm25Enabled(value),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: viewModel.isSaving ? null : () => _saveThresholds(viewModel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: viewModel.isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Lưu Cài Đặt', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThresholdCard({
    required String title,
    required IconData icon,
    required Color color,
    required String unit,
    required double minValue,
    required double maxValue,
    required bool enabled,
    required ValueChanged<double> onMinChanged,
    required ValueChanged<double> onMaxChanged,
    required ValueChanged<bool> onEnabledChanged,
  }) {
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
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tối thiểu: ${minValue.toStringAsFixed(1)} $unit'),
                      Slider(
                        value: minValue,
                        min: title == 'Nhiệt Độ' ? -10 : 0,
                        max: title == 'Nhiệt Độ' ? 50 : (title == 'Bụi PM2.5' ? 500 : 100),
                        divisions: 50,
                        onChanged: enabled ? onMinChanged : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tối đa: ${maxValue.toStringAsFixed(1)} $unit'),
                      Slider(
                        value: maxValue,
                        min: title == 'Nhiệt Độ' ? -10 : 0,
                        max: title == 'Nhiệt Độ' ? 50 : (title == 'Bụi PM2.5' ? 500 : 100),
                        divisions: 50,
                        onChanged: enabled ? onMaxChanged : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveThresholds(ThresholdViewModel viewModel) async {
    final success = await viewModel.saveThresholds();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cài đặt ngưỡng cảnh báo')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu cài đặt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
