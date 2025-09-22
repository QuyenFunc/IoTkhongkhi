import 'package:flutter/material.dart';
import '../services/persistent_esp32_connection.dart';
import '../services/esp32_wifi_service.dart';
import '../widgets/wifi_connection_guide.dart';

/// Màn hình cấu hình WiFi một bước - giữ kết nối liên tục
/// Giải quyết vấn đề mất kết nối giữa các bước
class OneStepWiFiSetupScreen extends StatefulWidget {
  final String? esp32SSID;
  
  const OneStepWiFiSetupScreen({
    super.key,
    this.esp32SSID,
  });

  @override
  State<OneStepWiFiSetupScreen> createState() => _OneStepWiFiSetupScreenState();
}

class _OneStepWiFiSetupScreenState extends State<OneStepWiFiSetupScreen> {
  final PersistentESP32Connection _persistentConnection = PersistentESP32Connection();
  final ESP32WiFiService _esp32Service = ESP32WiFiService();
  
  // Controllers
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isConfiguring = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _availableNetworks = [];
  bool _showPassword = false;
  
  @override
  void initState() {
    super.initState();
    // Set default WiFi credentials
    _ssidController.text = 'ADMIN-PC 9549';
    _passwordController.text = '12345678';
    _initializeConnection();
  }
  
  @override
  void dispose() {
    _persistentConnection.stopPersistentConnection();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeConnection() async {
    // Check if already connected to ESP32
    final isConnected = await _esp32Service.isConnectedToESP32AP();
    
    if (!isConnected) {
      // Show connection guide
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WiFiConnectionGuide(
              esp32SSID: widget.esp32SSID ?? 'ESP32-Setup-XXXX',
              onContinue: () => Navigator.pop(context),
            ),
          ),
        );
      }
    }
    
    // Start persistent connection
    _startPersistentConnection();
  }
  
  Future<void> _startPersistentConnection() async {
    setState(() {
      _statusMessage = 'Đang thiết lập kết nối liên tục...';
    });
    
    // Set reconnect callback
    _persistentConnection.setReconnectCallback((message) {
      if (mounted) {
        setState(() {
          _statusMessage = message;
        });
        
        // Hiển thị dialog nếu cần reconnect
        if (message.contains('bị ngắt')) {
          _showReconnectDialog(message);
        }
      }
    });
    
    final connected = await _persistentConnection.startPersistentConnection();
    
    if (connected) {
      setState(() {
        _statusMessage = 'Đã kết nối với ESP32. Đang quét mạng WiFi...';
      });
      
      // Scan networks
      await _scanNetworks();
    } else {
      setState(() {
        _statusMessage = 'Không thể kết nối với ESP32. Vui lòng thử lại.';
      });
    }
  }
  
  Future<void> _scanNetworks() async {
    try {
      setState(() {
        _statusMessage = 'Đang quét mạng WiFi...';
      });
      
      final networks = await _persistentConnection.executeRequest<List<dynamic>>(
        request: (client) async {
          final networks = await _esp32Service.scanWiFiNetworks();
          return networks;
        },
        maxRetries: 2, // Giảm số lần retry cho scan
        timeout: const Duration(seconds: 8), // Timeout ngắn hơn cho scan
      );
      
      if (networks != null && mounted) {
        setState(() {
          _availableNetworks = networks.cast<Map<String, dynamic>>();
          _statusMessage = 'Tìm thấy ${networks.length} mạng WiFi. Sẵn sàng cấu hình!';
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Không thể quét WiFi. Bạn vẫn có thể nhập thủ công.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Lỗi quét WiFi: ${e.toString()}. Vui lòng thử lại hoặc nhập thủ công.';
        });
      }
    }
  }
  
  Future<void> _configureWiFi() async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin WiFi');
      return;
    }
    
    setState(() {
      _isConfiguring = true;
    });
    
    try {
      final success = await _persistentConnection.configureESP32InOneSession(
        ssid: _ssidController.text,
        password: _passwordController.text,
        deviceId: 'ESP32-${DateTime.now().millisecondsSinceEpoch}',
        additionalConfig: {
          'firebase': {
            'url': 'https://iotkhongkhi-default-rtdb.asia-southeast1.firebasedatabase.app',
            'auth': 'your-firebase-auth-token',
          },
        },
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
            });
          }
        },
      );
      
      if (success && mounted) {
        _showSuccess();
      } else {
        _showError('Cấu hình thất bại. Vui lòng thử lại.');
      }
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isConfiguring = false;
        });
      }
    }
  }
  
  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Thành công!'),
        content: const Text(
          'ESP32 đã được cấu hình thành công.\n'
          'Thiết bị sẽ kết nối với WiFi và xuất hiện trong danh sách thiết bị.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to device list
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showReconnectDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wifi_off, color: Colors.orange, size: 48),
        title: const Text('Kết nối bị ngắt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hướng dẫn kết nối lại:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Mở WiFi Settings'),
                  Text('2. Kết nối với ESP32-Setup-xxx'),
                  Text('3. Nhấn "Đã kết nối" khi xong'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Quay lại màn hình trước
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Thử lại kết nối
              setState(() {
                _statusMessage = 'Đang kiểm tra kết nối...';
              });
            },
            child: const Text('Đã kết nối'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình WiFi một bước'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _persistentConnection.isActive 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _persistentConnection.isActive 
                      ? Colors.green.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _persistentConnection.isActive 
                        ? Icons.wifi 
                        : Icons.wifi_off,
                    color: _persistentConnection.isActive 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _persistentConnection.isActive 
                              ? 'Kết nối liên tục đang hoạt động' 
                              : 'Đang thiết lập kết nối...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _persistentConnection.isActive 
                                ? Colors.green.shade700 
                                : Colors.orange.shade700,
                          ),
                        ),
                        if (_statusMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // WiFi selection
            Text(
              'Chọn mạng WiFi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Network dropdown or text field
            if (_availableNetworks.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _ssidController.text.isEmpty ? null : _ssidController.text,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.wifi),
                  hintText: 'Chọn mạng WiFi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _availableNetworks.map((network) {
                  final ssid = network['ssid'] as String;
                  final rssi = network['rssi'] as int? ?? -100;
                  final secure = network['secure'] as bool? ?? false;
                  
                  return DropdownMenuItem(
                    value: ssid,
                    child: Row(
                      children: [
                        Expanded(child: Text(ssid)),
                        if (secure) 
                          const Icon(Icons.lock, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        _buildSignalIcon(rssi),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _ssidController.text = value;
                  }
                },
              ),
            ] else ...[
              TextFormField(
                controller: _ssidController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.wifi),
                  hintText: 'Nhập tên WiFi (SSID)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                hintText: 'Mật khẩu WiFi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Configure button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConfiguring || !_persistentConnection.isActive 
                    ? null 
                    : _configureWiFi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConfiguring
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Đang cấu hình...'),
                        ],
                      )
                    : const Text(
                        'Cấu hình WiFi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info card
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
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Kết nối liên tục',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Kết nối được duy trì trong suốt quá trình\n'
                    '• Tự động kết nối lại nếu bị ngắt\n'
                    '• Không cần kết nối lại giữa các bước',
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
  
  Widget _buildSignalIcon(int rssi) {
    IconData icon;
    Color color;
    
    if (rssi >= -50) {
      icon = Icons.signal_wifi_4_bar;
      color = Colors.green;
    } else if (rssi >= -60) {
      icon = Icons.signal_wifi_4_bar;
      color = Colors.green.shade600;
    } else if (rssi >= -70) {
      icon = Icons.network_wifi_3_bar;
      color = Colors.orange;
    } else if (rssi >= -80) {
      icon = Icons.network_wifi_2_bar;
      color = Colors.orange.shade700;
    } else {
      icon = Icons.network_wifi_1_bar;
      color = Colors.red;
    }
    
    return Icon(icon, size: 20, color: color);
  }
}
