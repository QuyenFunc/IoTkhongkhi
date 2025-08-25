import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/wifi_network_model.dart';
import '../services/wifi_scanner_service.dart';

/// WiFi network selector widget with scanning capability
class WiFiNetworkSelector extends StatefulWidget {
  final String? selectedSSID;
  final Function(String ssid, bool isSecured) onNetworkSelected;
  final VoidCallback? onManualEntry;

  const WiFiNetworkSelector({
    super.key,
    this.selectedSSID,
    required this.onNetworkSelected,
    this.onManualEntry,
  });

  @override
  State<WiFiNetworkSelector> createState() => _WiFiNetworkSelectorState();
}

class _WiFiNetworkSelectorState extends State<WiFiNetworkSelector> {
  final WiFiScannerService _wifiScanner = WiFiScannerService();
  WiFiScanResult _scanResult = WiFiScanResult.idle();
  String? _selectedSSID;

  @override
  void initState() {
    super.initState();
    _selectedSSID = widget.selectedSSID;
    
    // Listen to scan results
    _wifiScanner.scanResultStream.listen((result) {
      if (kDebugMode) {
        print('📡 WiFi scan result received: ${result.state}, networks: ${result.networks.length}');
      }
      if (mounted) {
        setState(() {
          _scanResult = result;
        });
      }
    });

    // Start initial scan
    _startScan();
  }

  Future<void> _startScan() async {
    if (kDebugMode) {
      print('🔍 Starting WiFi scan...');
    }

    // Try real WiFi scan first, fallback to mock if not supported
    final isSupported = await _wifiScanner.isWiFiScanSupported();

    if (isSupported) {
      if (kDebugMode) {
        print('📡 Using real WiFi scan');
      }
      await _wifiScanner.startScan();
    } else {
      if (kDebugMode) {
        print('📡 WiFi scan not supported, using mock data');
      }
      await _wifiScanner.startMockScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildScanStatus(theme),
            const SizedBox(height: 16),
            _buildNetworkList(theme),
            const SizedBox(height: 16),
            _buildManualEntryOption(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.wifi,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Select WiFi Network',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _scanResult.isScanning ? null : _startScan,
          icon: _scanResult.isScanning 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Refresh Networks',
        ),
      ],
    );
  }

  Widget _buildScanStatus(ThemeData theme) {
    switch (_scanResult.state) {
      case WiFiScanState.scanning:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Scanning for networks...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
              ),
            ),
          ],
        );
      
      case WiFiScanState.completed:
        return Text(
          'Found ${_scanResult.networks.length} networks',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
          ),
        );
      
      case WiFiScanState.error:
      case WiFiScanState.permissionDenied:
      case WiFiScanState.notSupported:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _scanResult.errorMessage ?? 'Scan failed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      
      case WiFiScanState.idle:
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNetworkList(ThemeData theme) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildNetworkContent(theme),
    );
  }

  Widget _buildNetworkContent(ThemeData theme) {
    if (_scanResult.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for networks...'),
          ],
        ),
      );
    }

    if (_scanResult.networks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No networks found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _scanResult.networks.length,
      itemBuilder: (context, index) {
        final network = _scanResult.networks[index];
        return _buildNetworkTile(network, theme);
      },
    );
  }

  Widget _buildNetworkTile(WiFiNetworkInfo network, ThemeData theme) {
    final isSelected = _selectedSSID == network.ssid;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSignalIcon(network.signalStrength),
              if (network.isSecured)
                Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
        title: Text(
          network.ssid,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${network.securityType} • ${network.frequencyBand} • ${network.signalText}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 20,
              )
            : null,
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedSSID = network.ssid;
            });
            widget.onNetworkSelected(network.ssid, network.isSecured);
          }
        },
      ),
    );
  }

  Widget _buildSignalIcon(int signalStrength) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Icon(
          Icons.signal_wifi_4_bar,
          color: Colors.grey[300],
          size: 20,
        ),
        ClipRect(
          child: Align(
            alignment: Alignment.bottomLeft,
            heightFactor: (signalStrength + 1) / 5, // 0.2 to 1.0
            child: Icon(
              Icons.signal_wifi_4_bar,
              color: _getSignalColor(signalStrength),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Color _getSignalColor(int signalStrength) {
    switch (signalStrength) {
      case 4:
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 1:
      case 0:
      default:
        return Colors.red;
    }
  }

  Widget _buildManualEntryOption(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: widget.onManualEntry,
      icon: const Icon(Icons.edit),
      label: const Text('Enter network manually'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
