import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ble_config_service.dart';
import 'one_step_wifi_setup_screen.dart';

/// Screen hiển thị các tùy chọn cấu hình thiết bị ESP32
/// Cho phép người dùng chọn giữa BLE hoặc WiFi configuration
class DeviceSetupOptionsScreen extends StatefulWidget {
  const DeviceSetupOptionsScreen({super.key});

  @override
  State<DeviceSetupOptionsScreen> createState() => _DeviceSetupOptionsScreenState();
}

class _DeviceSetupOptionsScreenState extends State<DeviceSetupOptionsScreen> {
  final BLEConfigService _bleService = BLEConfigService();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thiết bị mới'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    Icons.devices,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn phương thức kết nối',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chọn cách kết nối phù hợp với thiết bị của bạn',
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
            
            const SizedBox(height: 32),
            
            // Option 1: BLE Configuration (Recommended)
            _buildSetupOption(
              context,
              icon: Icons.bluetooth,
              iconColor: Colors.blue,
              title: 'Bluetooth (Khuyến nghị)',
              description: 'Cấu hình qua Bluetooth Low Energy\n'
                  '• Không cần chuyển đổi mạng WiFi\n'
                  '• Nhanh chóng và tiện lợi\n'
                  '• Không bị gián đoạn kết nối',
              isRecommended: true,
              onTap: () => _startBLESetup(context),
            ),
            
            const SizedBox(height: 16),
            
            // Option 2: WiFi Configuration
            _buildSetupOption(
              context,
              icon: Icons.wifi_protected_setup,
              iconColor: Colors.green,
              title: 'WiFi Configuration',
              description: 'Cấu hình WiFi với kết nối liên tục\n'
                  '• Chỉ cần kết nối ESP32 một lần\n'
                  '• Tự động duy trì kết nối\n'
                  '• Không bị ngắt giữa các bước',
              isRecommended: true,
              onTap: () => _startWiFiSetup(context),
            ),
            
            const SizedBox(height: 16),
            
            // Option 3: QR Code (if available)
            _buildSetupOption(
              context,
              icon: Icons.qr_code,
              iconColor: Colors.orange,
              title: 'QR Code',
              description: 'Quét mã QR để cấu hình\n'
                  '• Cần thiết bị hỗ trợ QR\n'
                  '• Cấu hình nhanh chóng\n'
                  '• Phù hợp cho nhiều thiết bị',
              isComingSoon: true,
              onTap: () => _showComingSoon(context),
            ),
            
            const SizedBox(height: 32),
            
            // Tips section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, 
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mẹo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Đảm bảo thiết bị ESP32 đang ở chế độ cấu hình (đèn LED nhấp nháy)\n'
                    '• Đứng gần thiết bị để có tín hiệu tốt nhất\n'
                    '• Chuẩn bị sẵn thông tin WiFi nhà bạn (tên mạng và mật khẩu)',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSetupOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isRecommended = false,
    bool isComingSoon = false,
    bool isNew = false,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isComingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecommended 
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : Colors.grey.shade200,
              width: isRecommended ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Khuyến nghị',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Mới',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (isComingSoon)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Sắp ra mắt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isComingSoon)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _startBLESetup(BuildContext context) async {
    try {
      // Initialize BLE service
      await _bleService.initialize();
      
      // TODO: Navigate to BLE setup screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BLE Setup - Coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BLE Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _startWiFiSetup(BuildContext context) async {
    // Navigate to one-step WiFi setup screen
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OneStepWiFiSetupScreen(),
      ),
    );
  }
  
  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng QR Code sẽ sớm ra mắt!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
