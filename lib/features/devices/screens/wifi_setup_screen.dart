import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wifi_setup_service.dart';
import '../models/wifi_setup_models.dart';

class WiFiSetupScreen extends StatefulWidget {
  const WiFiSetupScreen({super.key});

  @override
  State<WiFiSetupScreen> createState() => _WiFiSetupScreenState();
}

class _WiFiSetupScreenState extends State<WiFiSetupScreen> {
  final WiFiSetupService _wifiService = WiFiSetupService();
  
  List<ESP32Hotspot> _discoveredHotspots = [];
  WiFiSetupProgress? _currentProgress;
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔵 WiFiSetupScreen initState - starting WiFi scan');
    }
    _startWiFiScan();
  }

  @override
  void dispose() {
    _wifiService.dispose();
    super.dispose();
  }

  Future<void> _startWiFiScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _discoveredHotspots.clear();
      _currentProgress = WiFiSetupProgress.scanning();
    });

    try {
      if (kDebugMode) {
        print('🔍 Starting WiFi scan from UI...');
      }

      final hotspots = await _wifiService.scanForESP32Hotspots();

      if (kDebugMode) {
        print('🔍 Scan completed. Found ${hotspots.length} ESP32 hotspots');
        for (final hotspot in hotspots) {
          print('  📱 ${hotspot.ssid} (${hotspot.level}dBm)');
        }
      }

      if (mounted) {
        setState(() {
          _discoveredHotspots = hotspots;
          _isScanning = false;
          _currentProgress = null;

          if (hotspots.isEmpty) {
            _errorMessage = 'No ESP32 devices found. Make sure your device is in setup mode and WiFi is enabled.';
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WiFi scan error: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'WiFi scan failed: ${e.toString()}';
          _isScanning = false;
          _currentProgress = null;
        });
      }
    }
  }

  Future<void> _connectToHotspot(ESP32Hotspot hotspot) async {
    setState(() {
      _currentProgress = WiFiSetupProgress.connecting(ESP32DeviceInfo(
        deviceId: hotspot.deviceId,
        deviceName: 'ESP32-AirMonitor-${hotspot.deviceId}',
        firmwareVersion: '1.0.0',
        state: 'setup',
        apSSID: hotspot.ssid,
        apPassword: '12345678',
      ));
    });

    try {
      if (kDebugMode) {
        print('🔵 Attempting to connect to: ${hotspot.ssid}');
      }

      // Show manual connection dialog
      final shouldProceed = await _showManualConnectionDialog(hotspot);
      if (!shouldProceed) {
        setState(() {
          _currentProgress = null;
        });
        return;
      }

      // Wait for user to connect and verify
      final connected = await _wifiService.connectToESP32Hotspot(hotspot);
      
      if (connected && _wifiService.currentDevice != null) {
        setState(() {
          _currentProgress = WiFiSetupProgress.connected(_wifiService.currentDevice!);
        });

        // Open web interface
        await _openWebInterface();
      } else {
        throw Exception('Failed to connect to ESP32 hotspot');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection error: $e');
      }
      setState(() {
        _currentProgress = WiFiSetupProgress.error(e.toString());
      });
    }
  }

  Future<bool> _showManualConnectionDialog(ESP32Hotspot hotspot) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.blue),
            SizedBox(width: 8),
            Text('Connect to ESP32'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please connect to the ESP32 WiFi hotspot manually:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Network: ${hotspot.ssid}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Password: 12345678',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Steps:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('1. Open WiFi settings on your phone'),
            const Text('2. Connect to the network above'),
            const Text('3. Enter the password: 12345678'),
            const Text('4. Return to this app'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your phone will temporarily disconnect from your current WiFi.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I\'ve Connected'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _openWebInterface() async {
    try {
      const url = 'http://192.168.4.1/setup';
      
      if (kDebugMode) {
        print('🔵 Opening web interface: $url');
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // Show completion dialog
        _showCompletionDialog();
      } else {
        throw Exception('Cannot open web interface');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening web interface: $e');
      }
      _showError('Failed to open configuration page: ${e.toString()}');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Setup in Progress'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The device configuration page should now be open in your browser.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Please:'),
            SizedBox(height: 8),
            Text('1. Configure your WiFi network'),
            Text('2. Wait for the device to connect'),
            Text('3. Return to this app when done'),
            SizedBox(height: 16),
            Text(
              'The device will appear in your device list once setup is complete.',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to device discovery
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _testWiFiPermissions() async {
    try {
      if (kDebugMode) {
        print('🔵 Testing WiFi permissions...');
      }

      final hasPermissions = await _wifiService.requestWiFiPermissions();

      if (hasPermissions) {
        _showError('✅ WiFi permissions granted successfully!');
        setState(() {
          _errorMessage = null;
        });
      } else {
        _showError('❌ WiFi permissions denied. Please grant permissions in Settings.');
      }
    } catch (e) {
      _showError('Permission test failed: ${e.toString()}');
    }
  }

  Future<void> _testWiFiScan() async {
    try {
      if (kDebugMode) {
        print('🔵 Testing WiFi scan...');
      }

      setState(() {
        _errorMessage = 'Testing WiFi scan...';
      });

      final hotspots = await _wifiService.scanForESP32Hotspots();

      if (hotspots.isNotEmpty) {
        setState(() {
          _errorMessage = '✅ Found ${hotspots.length} ESP32 hotspots!';
          _discoveredHotspots = hotspots;
        });
      } else {
        setState(() {
          _errorMessage = '⚠️ No ESP32 hotspots found. Make sure ESP32 is powered on.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'WiFi scan test failed: ${e.toString()}';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Device Setup'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _startWiFiScan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh scan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_find,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESP32 Device Setup',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect to ESP32 WiFi hotspot for configuration',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress indicator
            if (_currentProgress != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _currentProgress!.isInProgress ? null : _currentProgress!.progress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentProgress!.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentProgress!.progress,
                      backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ],
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testWiFiPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('Test Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _testWiFiScan,
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Test WiFi Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Scanning indicator
            if (_isScanning)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning for ESP32 devices...'),
                  ],
                ),
              ),

            // Device list
            if (!_isScanning && _discoveredHotspots.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ESP32 Devices (${_discoveredHotspots.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _discoveredHotspots.length,
                        itemBuilder: (context, index) {
                          final hotspot = _discoveredHotspots[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.router,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                'ESP32-AirMonitor-${hotspot.deviceId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Network: ${hotspot.ssid}'),
                                  Text('Signal: ${hotspot.signalStrength} (${hotspot.level}dBm)'),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: _currentProgress?.isInProgress == true 
                                    ? null 
                                    : () => _connectToHotspot(hotspot),
                                child: const Text('Connect'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Empty state
            if (!_isScanning && _discoveredHotspots.isEmpty && _errorMessage == null)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No ESP32 devices found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make sure your ESP32 device is powered on\nand in setup mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
