import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_setup_service.dart';

class BluetoothSetupScreen extends StatefulWidget {
  const BluetoothSetupScreen({super.key});

  @override
  State<BluetoothSetupScreen> createState() => _BluetoothSetupScreenState();
}

class _BluetoothSetupScreenState extends State<BluetoothSetupScreen> {
  final BluetoothSetupService _bluetoothService = BluetoothSetupService();
  
  List<ESP32BluetoothDevice> _discoveredDevices = [];
  ESP32BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConfiguring = false;
  String? _errorMessage;
  
  // WiFi configuration
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🔵 BluetoothSetupScreen initState - starting Bluetooth check');
    }
    _checkBluetoothAndScan();
  }

  Future<void> _checkBluetoothAndScan() async {
    try {
      if (kDebugMode) {
        print('🔵 _checkBluetoothAndScan started');
      }

      // Check if Bluetooth is available first
      final isAvailable = await _bluetoothService.isBluetoothAvailable();
      if (kDebugMode) {
        print('🔵 Bluetooth available: $isAvailable');
      }

      if (!isAvailable) {
        if (kDebugMode) {
          print('🔵 Bluetooth not available, requesting enable...');
        }
        // Try to enable Bluetooth
        final isEnabled = await _bluetoothService.requestBluetoothEnable();
        if (kDebugMode) {
          print('🔵 Bluetooth enable result: $isEnabled');
        }
        if (!isEnabled) {
          setState(() {
            _errorMessage = 'Bluetooth is required for device setup. Please enable Bluetooth and try again.';
          });
          return;
        }
      }

      if (kDebugMode) {
        print('🔵 Bluetooth checks passed, starting scan...');
      }
      // Start scanning
      _startBluetoothScan();
    } catch (e) {
      if (kDebugMode) {
        print('❌ _checkBluetoothAndScan error: $e');
      }
      setState(() {
        _errorMessage = 'Failed to initialize Bluetooth: ${e.toString()}';
      });
    }
  }
  
  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startBluetoothScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _discoveredDevices.clear();
    });

    try {
      if (kDebugMode) {
        print('🔍 Starting Bluetooth scan from UI...');
      }

      final devices = await _bluetoothService.scanForDevices();

      if (kDebugMode) {
        print('🔍 Scan completed. Found ${devices.length} devices');
        for (final device in devices) {
          print('  📱 ${device.name} (${device.address})');
        }
      }

      if (mounted) {
        setState(() {
          _discoveredDevices = devices;
          _isScanning = false;

          if (devices.isEmpty) {
            _errorMessage = 'No ESP32 devices found. Make sure your device is in setup mode and Bluetooth is enabled.';
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Bluetooth scan error: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Bluetooth scan failed: ${e.toString()}';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(ESP32BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
      _errorMessage = null;
    });

    try {
      final success = await _bluetoothService.connectToDevice(device);
      if (success) {
        // Get device info
        final deviceInfo = await _bluetoothService.getDeviceInfo();
        if (kDebugMode) {
          print('Device info: $deviceInfo');
        }
        
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
          _showWiFiConfigDialog();
        }
      } else {
        throw Exception('Failed to connect to device');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isConnecting = false;
          _selectedDevice = null;
        });
      }
    }
  }

  void _showWiFiConfigDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configure WiFi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connected to: ${_selectedDevice?.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'WiFi Network (SSID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'WiFi Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bluetoothService.disconnect(_selectedDevice!);
              setState(() {
                _selectedDevice = null;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isConfiguring ? null : _configureWiFi,
            child: _isConfiguring 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Future<void> _configureWiFi() async {
    if (_ssidController.text.isEmpty) {
      _showError('Please enter WiFi network name');
      return;
    }

    setState(() {
      _isConfiguring = true;
    });

    try {
      final success = await _bluetoothService.configureWiFiViaBluetooth(
        device: _selectedDevice!,
        ssid: _ssidController.text,
        password: _passwordController.text,
        deviceId: _selectedDevice!.deviceId,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          _showSuccessDialog();
        }
      } else {
        throw Exception('WiFi configuration failed');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isConfiguring = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Setup Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Device ${_selectedDevice?.name} has been configured successfully!'),
            const SizedBox(height: 8),
            const Text('The device will now connect to your WiFi network.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final hasPermissions = await _bluetoothService.requestBluetoothPermissions();
      if (hasPermissions) {
        setState(() {
          _errorMessage = null;
        });
        _startBluetoothScan();
      } else {
        setState(() {
          _errorMessage = 'Bluetooth permissions are required. Please grant permissions in Settings.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request permissions: ${e.toString()}';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Setup'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _startBluetoothScan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'ESP32 Bluetooth Devices',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for ESP32-BLK-AirMonitor devices...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure Bluetooth is enabled and ESP32 is in setup mode.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                    Text('Scanning for Bluetooth devices...'),
                  ],
                ),
              ),
            
            // Error message
            if (_errorMessage != null)
              Container(
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
                          onPressed: _checkBluetoothAndScan,
                          icon: const Icon(Icons.bluetooth),
                          label: const Text('Enable Bluetooth'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _requestPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('Grant Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Device list
            if (!_isScanning && _discoveredDevices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    final isSelected = _selectedDevice?.address == device.address;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                        title: Text(device.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address: ${device.address}'),
                            Text('Signal: ${device.signalStrengthText} (${device.rssi} dBm)'),
                          ],
                        ),
                        trailing: _isConnecting && isSelected
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectToDevice(device),
                              child: const Text('Connect'),
                            ),
                        selected: isSelected,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
