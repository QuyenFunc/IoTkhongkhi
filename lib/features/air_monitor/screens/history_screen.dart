import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data_model.dart';
import '../widgets/sensor_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SensorData> historyData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('📊 Loading history data...');
      }

      final database = FirebaseDatabase.instance;
      final snapshot = await database.ref('/air_monitor/history').limitToLast(100).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        List<SensorData> tempList = [];

        if (kDebugMode) {
          print('📊 Raw Firebase data: ${data.length} items');
          // Print sample data for debugging
          var count = 0;
          for (final entry in data.entries) {
            if (count < 3) {
              print('📊 Sample[${count}]: ${entry.key} -> ${entry.value}');
              count++;
            }
          }
        }

        for (final entry in data.entries) {
          try {
            final itemData = Map<String, dynamic>.from(entry.value as Map);
            
            if (kDebugMode) {
              print('📊 Parsing item: $itemData');
            }
            
            // ESP32 gửi format: {temp: 33.3, hum: 66, pm25: 0, ts: 1834734936}
            final sensorData = SensorData(
              temperature: _parseDouble(itemData['temp']),
              humidity: _parseDouble(itemData['hum']),
              pm25: _parseDouble(itemData['pm25']),
              timestamp: _parseTimestamp(itemData['ts']),
            );
            
            if (kDebugMode) {
              print('📊 Parsed: ${sensorData.toString()}');
            }
            
            tempList.add(sensorData);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error parsing item ${entry.key}: $e');
            }
          }
        }

        // Sort by timestamp descending (newest first)
        tempList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        setState(() {
          historyData = tempList;
          isLoading = false;
        });

        if (kDebugMode) {
          print('✅ Loaded ${historyData.length} history records');
        }
      } else {
        setState(() {
          historyData = [];
          isLoading = false;
        });
        
        if (kDebugMode) {
          print('📊 No history data found');
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải dữ liệu: $e';
        isLoading = false;
      });
      
      if (kDebugMode) {
        print('❌ Error loading history: $e');
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    int ts = 0;
    
    if (value is int) {
      ts = value;
    } else if (value is double) {
      ts = value.toInt();
    } else if (value is String) {
      ts = int.tryParse(value) ?? 0;
    }
    
    // Convert seconds to milliseconds if needed
    if (ts < 2000000000) {
      ts = ts * 1000;
    }
    
    return ts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Lịch Sử & Biểu Đồ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryData,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Danh Sách'),
            Tab(icon: Icon(Icons.thermostat), text: 'Nhiệt Độ'),
            Tab(icon: Icon(Icons.water_drop), text: 'Độ Ẩm'),
            Tab(icon: Icon(Icons.air), text: 'PM2.5'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDataList(),
          _buildChartView('Nhiệt Độ (°C)', Colors.red, '°C'),
          _buildChartView('Độ Ẩm (%)', Colors.blue, '%'),
          _buildChartView('PM2.5 (μg/m³)', Colors.orange, 'μg/m³'),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistoryData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (historyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu lịch sử',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ESP32 sẽ gửi dữ liệu theo thời gian',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyData.length,
        itemBuilder: (context, index) {
          final data = historyData[index];
          return _buildHistoryItem(data, index);
        },
      ),
    );
  }

  Widget _buildChartView(String title, Color color, String unit) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu biểu đồ...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistoryData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (historyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có dữ liệu để vẽ biểu đồ',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Sort data by time for chart (oldest first)
    final sortedData = List<SensorData>.from(historyData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statistics card
            StatisticsCard(data: historyData),
            const SizedBox(height: 16),
            
            // Chart
            SensorChart(
              title: title,
              data: sortedData,
              color: color,
              unit: unit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(SensorData data, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(data.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn(
                    '🌡️ Nhiệt độ',
                    '${data.temperature.toStringAsFixed(1)}°C',
                    _getTemperatureColor(data.temperature),
                  ),
                ),
                Expanded(
                  child: _buildValueColumn(
                    '💧 Độ ẩm',
                    '${data.humidity.toStringAsFixed(1)}%',
                    _getHumidityColor(data.humidity),
                  ),
                ),
                Expanded(
                  child: _buildValueColumn(
                    '🌪️ PM2.5',
                    '${data.pm25.toStringAsFixed(1)}',
                    Color(int.parse(data.airQualityColor.substring(1), radix: 16) + 0xFF000000),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
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
