import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Widget hướng dẫn người dùng giữ kết nối WiFi không có internet
/// Giống như cách các camera WiFi hướng dẫn người dùng
class WiFiConnectionGuide extends StatelessWidget {
  final VoidCallback onContinue;
  final String esp32SSID;
  
  const WiFiConnectionGuide({
    super.key,
    required this.onContinue,
    required this.esp32SSID,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = Platform.isAndroid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối với thiết bị'),
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quan trọng: Vui lòng làm theo hướng dẫn để giữ kết nối',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Network info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Đang kết nối với:',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    esp32SSID,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Step 1: Turn off mobile data
            _buildStep(
              context,
              stepNumber: '1',
              title: 'Tắt dữ liệu di động (Mobile Data)',
              description: isAndroid
                  ? 'Kéo thanh thông báo xuống và tắt "Mobile Data" hoặc "4G/5G"'
                  : 'Vào Cài đặt > Dữ liệu di động > Tắt "Dữ liệu di động"',
              icon: Icons.signal_cellular_off,
              color: Colors.red,
            ),
            
            const SizedBox(height: 20),
            
            // Step 2: Android specific - Developer options
            if (isAndroid) ...[
              _buildStep(
                context,
                stepNumber: '2',
                title: 'Cho phép WiFi không có Internet (Tùy chọn)',
                description: 'Một số điện thoại Android:\n'
                    '• Vào Cài đặt > WiFi > Cài đặt nâng cao\n'
                    '• Tắt "Chuyển sang dữ liệu di động"\n'
                    '• Tắt "Tự động kết nối lại"',
                icon: Icons.wifi_lock,
                color: Colors.orange,
                isOptional: true,
              ),
              const SizedBox(height: 20),
            ],
            
            // Step 3: Keep app in foreground
            _buildStep(
              context,
              stepNumber: isAndroid ? '3' : '2',
              title: 'Giữ ứng dụng mở',
              description: 'Không chuyển sang ứng dụng khác trong quá trình cấu hình',
              icon: Icons.phone_android,
              color: Colors.green,
            ),
            
            const SizedBox(height: 32),
            
            // Additional tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 12),
                  _buildTip(
                    '• Quá trình cấu hình chỉ mất 1-2 phút',
                  ),
                  _buildTip(
                    '• Sau khi cấu hình xong, bạn có thể bật lại Mobile Data',
                  ),
                  _buildTip(
                    '• Thiết bị sẽ tự động kết nối với WiFi nhà bạn',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Có thể thêm logic kiểm tra kết nối ở đây
                  HapticFeedback.mediumImpact();
                  onContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tôi đã làm theo hướng dẫn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Skip button (not recommended)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cảnh báo'),
                    content: const Text(
                      'Nếu bỏ qua các bước này, điện thoại có thể tự động '
                      'ngắt kết nối với thiết bị ESP32 và quá trình cấu hình '
                      'sẽ thất bại.\n\nBạn có chắc chắn muốn tiếp tục?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onContinue();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Tiếp tục'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Bỏ qua (không khuyến khích)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOptional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tùy chọn',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade700,
          height: 1.4,
        ),
      ),
    );
  }
}
