import 'package:flutter/material.dart';
import '../../services/device_service.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatefulWidget {
  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final DeviceService _deviceService = DeviceService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _deviceService.getUserDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final device = snapshot.data![index];
              return DeviceCard(device: device);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Devices Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first air monitor device to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // This will be handled by the FAB in HomeScreen
            },
            icon: Icon(Icons.add),
            label: Text('Add Device'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final DeviceService _deviceService = DeviceService();

  DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    String status = device['status'] ?? 'unknown';
    bool isOnline = status == 'online';
    DateTime? lastSeen = device['lastSeen'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(device['lastSeen'] * 1000)
        : null;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDeviceDetail(context),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.device_hub,
                    size: 32,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device['deviceName'] ?? 'Unknown Device',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          device['deviceId'] ?? 'Unknown ID',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              SizedBox(height: 12),
              if (device['location'] != null && device['location'].isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      device['location'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (lastSeen != null)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Last seen: ${_formatDateTime(lastSeen)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (isOnline && device['ipAddress'] != null)
                Row(
                  children: [
                    Icon(Icons.wifi, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${device['wifiSSID']} - ${device['ipAddress']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              SizedBox(height: 12),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'online':
        color = Colors.green;
        label = 'Online';
        break;
      case 'offline':
        color = Colors.red;
        label = 'Offline';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.restart_alt,
          label: 'Restart',
          onTap: () => _sendCommand(context, 'restart', true),
        ),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit',
          onTap: () => _editDevice(context),
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: () => _deleteDevice(context),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDeviceDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailScreen(device: device),
      ),
    );
  }

  void _sendCommand(BuildContext context, String command, dynamic value) async {
    try {
      await _deviceService.sendDeviceCommand(device['deviceId'], command, value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send command: $e')),
      );
    }
  }

  void _editDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditDeviceDialog(device: device),
    );
  }

  void _deleteDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device['deviceName']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _deviceService.deleteDevice(device['deviceId']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Device deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete device: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class EditDeviceDialog extends StatefulWidget {
  final Map<String, dynamic> device;

  EditDeviceDialog({required this.device});

  @override
  _EditDeviceDialogState createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final DeviceService _deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.device['deviceName'] ?? '';
    _locationController.text = widget.device['location'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Device'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter device name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: Text('Save'),
        ),
      ],
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _deviceService.updateDeviceInfo(
          widget.device['deviceId'],
          _nameController.text.trim(),
          _locationController.text.trim(),
        );
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update device: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

