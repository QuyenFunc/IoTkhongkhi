import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../theme/app_theme.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DeviceModel device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.displayName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.device_hub, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Chi tiết thiết bị: ${device.displayName}',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Màn hình này sẽ được phát triển tiếp theo',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}


