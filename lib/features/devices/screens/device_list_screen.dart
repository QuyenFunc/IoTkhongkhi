import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/device_model.dart' as device_models;
import '../services/device_service.dart';
import 'device_detail_screen.dart';
import 'device_setup_screen.dart';
// import 'test_qr_screen.dart'; // Removed for production

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final DeviceService _deviceService = DeviceService();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddDevice(),
            tooltip: 'Add Device',
          ),
        ],
      ),
      body: StreamBuilder<List<device_models.DeviceModel>>(
        stream: _deviceService.getUserDevices()
            .distinct((prev, next) => prev.length == next.length &&
                prev.every((device) => next.any((d) => d.id == device.id && d.updatedAt == device.updatedAt))),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (kDebugMode) {
              print('Device list error: ${snapshot.error}');
              print('Stack trace: ${snapshot.stackTrace}');
            }
            return _buildErrorState(theme, snapshot.error.toString());
          }

          final devices = snapshot.data ?? [];
          
          if (devices.isEmpty) {
            return _buildEmptyState(theme);
          }

          return _buildDeviceGrid(devices, theme);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDevice,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceGrid(List<device_models.DeviceModel> devices, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return _buildDeviceCard(device, theme);
        },
      ),
    );
  }

  Widget _buildDeviceCard(device_models.DeviceModel device, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDeviceDetail(device),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(device.status),
                    radius: 20,
                    child: Icon(
                      _getDeviceIcon(device.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          device.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(device.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(device.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(device.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(device.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Last Seen
              Text(
                'Last seen: ${_formatLastSeen(device.lastSeenAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              const Spacer(),
              
              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () => _showDeviceSettings(device),
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showDeviceMenu(device),
                    tooltip: 'More options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Devices Yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first air quality monitor to start monitoring your environment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddDevice,
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Devices',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddDevice() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceSetupScreen(),
      ),
    );
    
    // If device was added successfully, refresh the list
    if (result == true && mounted) {
      setState(() {
        // Trigger rebuild to refresh device list
      });
    }
  }

  void _navigateToDeviceDetail(device_models.DeviceModel device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailScreen(device: device),
      ),
    );
  }

  void _showDeviceSettings(device_models.DeviceModel device) {
    // TODO: Implement device settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings for ${device.name}')),
    );
  }

  void _showDeviceMenu(device_models.DeviceModel device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildDeviceMenuSheet(device),
    );
  }

  Widget _buildDeviceMenuSheet(device_models.DeviceModel device) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Device'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(device);
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Change Location'),
            onTap: () {
              Navigator.pop(context);
              _showLocationDialog(device);
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Restart Device'),
            onTap: () {
              Navigator.pop(context);
              _restartDevice(device);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Device', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(device);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(device_models.DeviceModel device) {
    // TODO: Implement rename dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rename feature coming soon')),
    );
  }

  void _showLocationDialog(device_models.DeviceModel device) {
    // TODO: Implement location change dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location change feature coming soon')),
    );
  }

  void _restartDevice(device_models.DeviceModel device) {
    // TODO: Implement device restart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restart command sent')),
    );
  }

  void _showDeleteDialog(device_models.DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDevice(device);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice(device_models.DeviceModel device) async {
    try {
      await _deviceService.deleteDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name} removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing device: $e')),
        );
      }
    }
  }

  Color _getStatusColor(device_models.DeviceStatus status) {
    switch (status) {
      case device_models.DeviceStatus.active:
        return Colors.green;
      case device_models.DeviceStatus.inactive:
        return Colors.red;
      case device_models.DeviceStatus.maintenance:
        return Colors.orange;
      case device_models.DeviceStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(device_models.DeviceStatus status) {
    switch (status) {
      case device_models.DeviceStatus.active:
        return 'Online';
      case device_models.DeviceStatus.inactive:
        return 'Offline';
      case device_models.DeviceStatus.maintenance:
        return 'Maintenance';
      case device_models.DeviceStatus.error:
        return 'Error';
    }
  }

  IconData _getDeviceIcon(device_models.DeviceType type) {
    switch (type) {
      case device_models.DeviceType.esp32:
        return Icons.sensors;
      case device_models.DeviceType.arduino:
        return Icons.memory;
      case device_models.DeviceType.raspberryPi:
        return Icons.computer;
      case device_models.DeviceType.airQuality:
        return Icons.air;
      case device_models.DeviceType.custom:
        return Icons.device_unknown;
      case device_models.DeviceType.other:
        return Icons.device_unknown;
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
