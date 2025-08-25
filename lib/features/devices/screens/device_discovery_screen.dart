import 'package:flutter/material.dart';
import '../services/device_setup_service.dart';
import 'device_setup_screen.dart';
import 'bluetooth_setup_screen.dart';
import 'wifi_setup_screen.dart';
// QR Scanner temporarily disabled
// import 'qr_scanner_screen.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  final DeviceSetupService _setupService = DeviceSetupService();
  
  List<SetupDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _hasPermissions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      // Check if already connected to setup hotspot
      final isConnected = await _setupService.isConnectedToSetupHotspot();
      if (isConnected) {
        _navigateToSetup(null);
        return;
      }

      // Scan for devices
      await _scanForDevices();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  Future<void> _scanForDevices() async {
    try {
      final devices = await _setupService.scanForSetupDevices();
      
      if (mounted) {
        setState(() {
          _discoveredDevices = devices;
          _isScanning = false;
          _hasPermissions = true;
          
          if (devices.isEmpty) {
            _errorMessage = 'No setup devices found. Make sure your ESP32 is in setup mode.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isScanning = false;
        });
      }
    }
  }

  void _navigateToSetup(SetupDevice? device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceSetupScreen(setupDevice: device),
      ),
    );
  }

  // QR Scanner temporarily disabled
  // void _navigateToQRScanner() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const QRScannerScreen(),
  //     ),
  //   );
  // }

  void _startWiFiSetup() {
    // Navigate to WiFi setup screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WiFiSetupScreen(),
      ),
    );
  }

  void _startBluetoothSetup() {
    // Navigate to Bluetooth setup screen (legacy)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BluetoothSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // QR Scanner temporarily disabled
          // IconButton(
          //   icon: const Icon(Icons.qr_code_scanner),
          //   onPressed: _navigateToQRScanner,
          //   tooltip: 'Scan QR Code',
          // ),
          if (_hasPermissions)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isScanning ? null : _scanForDevices,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isScanning) {
      return _buildScanningState(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_discoveredDevices.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildDeviceList(theme);
  }

  Widget _buildScanningState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Scanning for devices...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Make sure your ESP32 Air Monitor is in setup mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Setup Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkPermissionsAndScan,
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _navigateToSetup(null),
              child: const Text('Manual Setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Devices Found',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure your ESP32 Air Monitor is:\n'
              '• Powered on\n'
              '• In setup mode (LED blinking)\n'
              '• Within WiFi range',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Primary connection methods
            ElevatedButton.icon(
              onPressed: _scanForDevices,
              icon: const Icon(Icons.wifi),
              label: const Text('Connect via WiFi Hotspot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startWiFiSetup,
              icon: const Icon(Icons.wifi),
              label: const Text('Connect via WiFi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startBluetoothSetup,
              icon: const Icon(Icons.bluetooth),
              label: const Text('Connect via Bluetooth (Legacy)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 24),
            // Alternative method
            OutlinedButton.icon(
              onPressed: () => _navigateToSetup(null),
              icon: const Icon(Icons.settings),
              label: const Text('Manual Setup'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            // Info card about QR code being disabled
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QR code scanning is temporarily disabled. Use WiFi hotspot or Bluetooth for device setup.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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

  Widget _buildDeviceList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Found ${_discoveredDevices.length} device(s) ready for setup',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _discoveredDevices.length,
            itemBuilder: (context, index) {
              final device = _discoveredDevices[index];
              return _buildDeviceCard(device, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(SetupDevice device, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor,
          child: const Icon(
            Icons.sensors,
            color: Colors.white,
          ),
        ),
        title: Text(device.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.deviceId}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  size: 16,
                  color: _getSignalColor(device.signalStrength),
                ),
                const SizedBox(width: 4),
                Text(
                  device.signalStrengthText,
                  style: TextStyle(
                    color: _getSignalColor(device.signalStrength),
                    fontSize: 12,
                  ),
                ),
                if (device.isSecured) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _navigateToSetup(device),
          child: const Text('Setup'),
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getSignalColor(int signalStrength) {
    if (signalStrength > -50) return Colors.green;
    if (signalStrength > -60) return Colors.orange;
    return Colors.red;
  }
}
