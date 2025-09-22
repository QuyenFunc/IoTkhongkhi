import 'package:flutter/material.dart';
import '../models/device_status_model.dart';

/// Widget hiển thị trạng thái thiết bị
class DeviceStatusCard extends StatelessWidget {
  final DeviceStatus deviceStatus;

  const DeviceStatusCard({
    super.key,
    required this.deviceStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(int.parse(
      deviceStatus.statusColor.substring(1), 
      radix: 16,
    ) + 0xFF000000);
    
    final isOnline = deviceStatus.isReallyOnline;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.05),
              statusColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status icon với animation
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline ? Icons.router : Icons.router_outlined,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '🔗 ESP32 Monitor',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Animated status dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: isOnline ? [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deviceStatus.statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (deviceStatus.lastSeen > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cập nhật: ${deviceStatus.timeSinceLastSeen}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Device info if available
              if (deviceStatus.deviceInfo != null) ...[
                const SizedBox(height: 16),
                _DeviceInfoSection(deviceInfo: deviceStatus.deviceInfo!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị thông tin chi tiết thiết bị
class _DeviceInfoSection extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const _DeviceInfoSection({
    required this.deviceInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông Tin Thiết Bị',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        // Device ID
        _InfoRow(
          icon: Icons.memory,
          label: 'Device ID',
          value: deviceInfo.deviceId,
        ),
        
        // IP Address
        if (deviceInfo.ipAddress.isNotEmpty)
          _InfoRow(
            icon: Icons.router,
            label: 'IP Address',
            value: deviceInfo.ipAddress,
          ),
        
        // WiFi SSID
        if (deviceInfo.wifiSsid.isNotEmpty)
          _InfoRow(
            icon: Icons.wifi,
            label: 'WiFi',
            value: deviceInfo.wifiSsid,
            subtitle: deviceInfo.rssi != null 
                ? '${deviceInfo.signalStrengthText} (${deviceInfo.rssi}dBm)'
                : null,
          ),
        
        // Firmware Version
        if (deviceInfo.firmwareVersion.isNotEmpty)
          _InfoRow(
            icon: Icons.system_update,
            label: 'Firmware',
            value: deviceInfo.firmwareVersion,
          ),
      ],
    );
  }
}

/// Widget hiển thị một dòng thông tin
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
