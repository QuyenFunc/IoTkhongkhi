import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:async';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Map<String, dynamic>? _globalDevices;
  Map<String, dynamic>? _userDevices;
  Map<String, dynamic>? _sensorData;
  bool _isLoading = true;
  String _status = 'Checking Firebase structure...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseStructure();
  }

  Future<void> _checkFirebaseStructure() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firebase structure...';
    });

    try {
      // Check global devices path
      setState(() => _status = 'Checking /devices path...');
      final devicesSnapshot = await _database.ref('devices').get();
      if (devicesSnapshot.exists) {
        _globalDevices = Map<String, dynamic>.from(devicesSnapshot.value as Map);
        print('📱 Global devices found: ${_globalDevices?.keys.length} devices');
      } else {
        print('❌ No global devices found at /devices');
      }

      // Check user-specific devices path
      const userUID = 'MUnksHfJxlWeWCT9ogPktWRIQu83';
      setState(() => _status = 'Checking /users/$userUID/devices path...');
      final userDevicesSnapshot = await _database.ref('users/$userUID/devices').get();
      if (userDevicesSnapshot.exists) {
        _userDevices = Map<String, dynamic>.from(userDevicesSnapshot.value as Map);
        print('👤 User devices found: ${_userDevices?.keys.length} devices');
      } else {
        print('❌ No user devices found at /users/$userUID/devices');
      }

      // Check sensor data path
      setState(() => _status = 'Checking /sensorData path...');
      final sensorSnapshot = await _database.ref('sensorData').get();
      if (sensorSnapshot.exists) {
        _sensorData = Map<String, dynamic>.from(sensorSnapshot.value as Map);
        print('📊 Sensor data found for ${_sensorData?.keys.length} devices');
      } else {
        print('❌ No sensor data found at /sensorData');
      }

      setState(() {
        _isLoading = false;
        _status = 'Firebase structure check completed';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error checking Firebase: $e';
      });
      print('❌ Error checking Firebase structure: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkFirebaseStructure,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_status),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  color: _hasData() ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _hasData() ? Icons.check_circle : Icons.error,
                          color: _hasData() ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _hasData() 
                              ? 'Firebase data found! ESP32 is sending data.'
                              : 'No data found. Check ESP32 connection.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _hasData() ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Global Devices Section
                _buildSection(
                  'Global Devices (/devices)',
                  _globalDevices,
                  'ESP32 should send device info here for compatibility',
                ),

                const SizedBox(height: 16),

                // User Devices Section  
                _buildSection(
                  'User Devices (/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices)',
                  _userDevices,
                  'ESP32 should send device info here for user-specific access',
                ),

                const SizedBox(height: 16),

                // Sensor Data Section
                _buildSection(
                  'Sensor Data (/sensorData)',
                  _sensorData,
                  'ESP32 should send real-time sensor readings here',
                ),

                const SizedBox(height: 24),

                // Test Live Data Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _testLiveData,
                    icon: const Icon(Icons.sensors),
                    label: const Text('Test Live Data Stream'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  bool _hasData() {
    return _globalDevices != null || _userDevices != null || _sensorData != null;
  }

  Widget _buildSection(String title, Map<String, dynamic>? data, String description) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  data != null ? Icons.check_circle : Icons.error,
                  color: data != null ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            if (data != null) ...[
              Text(
                'Found ${data.keys.length} entries:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'No data found at this path',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _testLiveData() {
    if (_globalDevices?.isNotEmpty == true) {
      final deviceId = _globalDevices!.keys.first;
      _showLiveDataDialog(deviceId);
    } else if (_sensorData?.isNotEmpty == true) {
      final deviceId = _sensorData!.keys.first;
      _showLiveDataDialog(deviceId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No devices found to test'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLiveDataDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (context) => _LiveDataDialog(deviceId: deviceId),
    );
  }
}

class _LiveDataDialog extends StatefulWidget {
  final String deviceId;

  const _LiveDataDialog({required this.deviceId});

  @override
  State<_LiveDataDialog> createState() => _LiveDataDialogState();
}

class _LiveDataDialogState extends State<_LiveDataDialog> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Map<String, dynamic>? _latestData;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription = _database
        .ref('sensorData/${widget.deviceId}/latest')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _latestData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Live Data - ${widget.deviceId.substring(0, 12)}...'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: _latestData != null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataTile('🌡️ Temperature', '${_latestData!['temperature']}°C'),
                    _buildDataTile('💧 Humidity', '${_latestData!['humidity']}%'),
                    _buildDataTile('🌫️ Air Quality', '${_latestData!['airQuality']} μg/m³'),
                    if (_latestData!['pm25'] != null)
                      _buildDataTile('🔬 PM2.5', '${_latestData!['pm25']} μg/m³'),
                    if (_latestData!['rssi'] != null)
                      _buildDataTile('📶 WiFi Signal', '${_latestData!['rssi']} dBm'),
                    const SizedBox(height: 16),
                    const Text('Raw Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(_latestData!),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Waiting for live data...'),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDataTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
