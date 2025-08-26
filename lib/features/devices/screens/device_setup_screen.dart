import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/esp32_wifi_service.dart';
import '../services/device_pairing_service.dart';
import '../../user/services/user_service.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final ESP32WiFiService _wifiService = ESP32WiFiService();
  final DevicePairingService _pairingService = DevicePairingService();
  final UserService _userService = UserService();
  
  final PageController _pageController = PageController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedESP32Network;
  String? _selectedWiFiNetwork;
  String? _userKey;
  List<String> _esp32Networks = [];
  List<Map<String, dynamic>> _wifiNetworks = [];

  @override
  void initState() {
    super.initState();
    _startSetupProcess();
  }

  @override
  void dispose() {
    _wifiPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startSetupProcess() async {
    // Get user key from user profile instead of generating new one
    try {
      if (kDebugMode) {
        print('🔑 Getting userKey from user profile...');
      }
      
      final userProfile = await _userService.getCurrentUserProfile();
      if (userProfile != null && userProfile.userKey.isNotEmpty) {
        _userKey = userProfile.userKey;
        if (kDebugMode) {
          print('✅ Using existing userKey: ${_userKey!.substring(0, 8)}***');
        }
      } else {
        // Fallback: generate new userKey if not found
        _userKey = _pairingService.generateUserKey();
        if (kDebugMode) {
          print('⚠️ Generated new userKey as fallback: ${_userKey!.substring(0, 8)}***');
        }
      }
      
      _scanForESP32Networks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: User not authenticated. Please login first.';
        });
      }
    }
  }

  Future<void> _scanForESP32Networks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Use real WiFi scanning instead of mock data
      final detailedNetworks = await _wifiService.getAvailableESP32Networks();
      final networks = detailedNetworks.map((n) => n['ssid'] as String).toList();
      
      if (mounted) {
        setState(() {
          _esp32Networks = networks;
          _isLoading = false;
        });
      }
      
      if (networks.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'No ESP32 setup networks found. Make sure your ESP32 device is powered on and in setup mode.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to scan for ESP32 networks: $e\n\nTip: Make sure WiFi location permission is granted and location services are enabled.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connectToESP32Network(String networkName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedESP32Network = networkName;
    });

    try {
      // Attempt to connect to ESP32 WiFi
      final success = await _wifiService.connectToESP32WiFi(networkName);
      
      if (success) {
        // Successfully connected, scan for available WiFi networks
        await _scanWiFiNetworks();
        _nextStep();
      } else {
        // Connection failed, show manual instructions
        setState(() {
          _isLoading = false;
        });
        _showManualConnectionDialog(networkName);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to ESP32: $e';
        _isLoading = false;
      });
      
      // Still show manual instructions as fallback
      _showManualConnectionDialog(networkName);
    }
  }

  void _showManualConnectionDialog(String networkName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings_applications, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Manual WiFi Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please connect to your ESP32 device manually:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📡 Network Name:', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  Text(networkName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('🔐 Password:', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  const Text('12345678', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Steps to connect:'),
            const SizedBox(height: 8),
            const Text('1. 📱 Open your phone\'s WiFi settings'),
            const Text('2. 🔍 Find and tap on the ESP32 network above'),
            const Text('3. 🔑 Enter password "12345678"'),
            const Text('4. ✅ Wait for connection to complete'),
            const Text('5. 🔄 Return to this app and tap "Continue"'),
            const SizedBox(height: 16),
            
            // CRITICAL WARNING about Android auto-switching
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'QUAN TRỌNG!',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Android sẽ TỰ ĐỘNG CHUYỂN sang 4G/WiFi khác khi ESP32 không có internet!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '✅ Để tránh lỗi "connection abort":\n'
                    '• TẮT dữ liệu di động (4G/5G) tạm thời\n'
                    '• TẮT "Tự động chuyển mạng" trong WiFi settings\n'
                    '• Giữ kết nối với ESP32 trong suốt quá trình cấu hình',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'If you don\'t see the network, make sure the ESP32 is powered on and showing "SETUP MODE" on its display.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              // Check connection with retry logic
              bool isConnected = false;
              for (int i = 0; i < 5; i++) {
                isConnected = await _wifiService.isConnectedToESP32AP();
                if (isConnected) break;
                await Future.delayed(const Duration(seconds: 1));
              }
              
              if (isConnected) {
                await _scanWiFiNetworks();
                _nextStep();
              } else {
                setState(() {
                  _errorMessage = 'Still not connected to ESP32. Please make sure you\'re connected to "$networkName" and try again.';
                  _isLoading = false;
                });
              }
            },
            child: const Text('I\'m Connected - Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanWiFiNetworks() async {
    try {
      final networks = await _wifiService.scanWiFiNetworks();
      setState(() {
        _wifiNetworks = networks;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to scan WiFi networks: $e';
      });
    }
  }

  Future<void> _configureDevice() async {
    if (_selectedWiFiNetwork == null || _wifiPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a WiFi network and enter the password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Auto fetch userKey if not generated yet
      _userKey ??= _pairingService.generateUserKey();

      // Get current user UID for Firebase authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please login first.');
      }
      
      final userUID = currentUser.uid;
      
      if (kDebugMode) {
        print('🔑 Using UserKey: ${_userKey!.substring(0, 8)}***');
        print('👤 Using UserUID: ${userUID.substring(0, 8)}***');
      }

      // Run end-to-end setup without browser
      final ok = await _wifiService.setupDeviceEndToEnd(
        esp32Ssid: _selectedESP32Network!,
        homeSsid: _selectedWiFiNetwork!,
        homePassword: _wifiPasswordController.text,
        userKey: _userKey!,
        userUID: userUID,
      );

      if (ok) {
        _nextStep(); // Waiting screen
        _startDeviceDiscovery();
      } else {
        setState(() {
          _errorMessage = 'Failed to configure device. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Enhanced error handling for connection abort issues
      String errorMessage;
      
      if (e.toString().contains('Software caused connection abort') ||
          e.toString().contains('Android keeps switching to mobile data')) {
        errorMessage = '''
🚨 ANDROID TỰ ĐỘNG CHUYỂN MẠNG!

❌ Vấn đề: Android tự động chuyển sang 4G khi ESP32 không có internet

✅ GIẢI PHÁP NGAY:
1. 🔴 TẮT dữ liệu di động (Mobile Data)
2. 🔄 Kết nối lại WiFi ESP32-Setup-XXXXXX  
3. ✋ TẮT "Switch to mobile data" trong WiFi settings
4. 🔄 Nhấn "Configure Device" để thử lại

⚠️ Quan trọng: Giữ Mobile Data TẮT trong suốt quá trình setup!
        ''';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = '''
⏰ TIMEOUT - ESP32 KHÔNG PHẢN HỒI

💡 Nguyên nhân có thể:
• ESP32 đang khởi động lại
• Mất kết nối WiFi ESP32
• ESP32 đang busy xử lý request khác

✅ Giải pháp:
1. Chờ 10-15 giây
2. Kiểm tra kết nối WiFi ESP32-Setup-XXXXXX
3. Thử lại
        ''';
      } else if (e.toString().contains('Not connected to ESP32 AP')) {
        errorMessage = '''
📡 MẤT KẾT NỐI ESP32

❌ Không còn kết nối với mạng ESP32

✅ Cách khắc phục:
1. Mở Settings → WiFi
2. Tìm và kết nối "ESP32-Setup-XXXXXX"
3. Mật khẩu: 12345678
4. Tắt Mobile Data
5. Quay lại app và thử lại
        ''';
      } else {
        errorMessage = 'Error configuring device: $e';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  void _startDeviceDiscovery() {
    if (_userKey == null) return;

    // Listen for the device to appear in pendingDevices
    _pairingService.listenForPendingDevice(_userKey!).listen(
      (deviceData) {
        if (deviceData != null) {
          _onDeviceDiscovered(deviceData);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error discovering device: $error';
            _isLoading = false;
          });
        }
      },
    );

    // Set timeout for device discovery
    Future.delayed(const Duration(minutes: 3), () {
      if (mounted && _currentStep == 2) {
        setState(() {
          _errorMessage = 'Device discovery timeout. Please try again.';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _onDeviceDiscovered(Map<String, dynamic> deviceData) async {
    if (kDebugMode) {
      print('🎉 Device discovered: $deviceData');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Pair the device
      final success = await _pairingService.pairDevice(
        deviceId: deviceData['deviceId'],
        deviceData: deviceData,
        customDeviceName: 'ESP32 Air Monitor - ${deviceData['deviceId'].substring(6)}',
      );

      if (success) {
        _nextStep(); // Go to success screen
      } else {
        setState(() {
          _errorMessage = 'Failed to pair device. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error pairing device: $e';
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
      _isLoading = false;
      _errorMessage = null;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
        leading: _currentStep > 0 && _currentStep < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading ? null : _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildESP32ScanStep(),
                _buildWiFiConfigStep(),
                _buildWaitingStep(),
                _buildSuccessStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildESP32ScanStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Connect to ESP32',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Make sure your ESP32 device is powered on and in setup mode. Look for WiFi networks starting with "ESP32-Setup-".',
          ),
          const SizedBox(height: 24),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[600]))),
                ],
              ),
            ),
          
          if (_errorMessage != null) const SizedBox(height: 16),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_esp32Networks.isEmpty)
            Column(
        children: [
                const Text('No ESP32 networks found.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _scanForESP32Networks,
                  child: const Text('Scan Again'),
                ),
              ],
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _esp32Networks.length,
                itemBuilder: (context, index) {
                  final network = _esp32Networks[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.wifi),
                      title: Text(network),
                      subtitle: const Text('ESP32 Setup Network'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => _connectToESP32Network(network),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWiFiConfigStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Configure WiFi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Connected to: $_selectedESP32Network'),
          const SizedBox(height: 24),
          
          const Text('Select your home WiFi network:'),
          const SizedBox(height: 8),
          
          if (_wifiNetworks.isEmpty)
            const CircularProgressIndicator()
          else
            DropdownButtonFormField<String>(
              value: _selectedWiFiNetwork,
              decoration: const InputDecoration(
                labelText: 'WiFi Network',
                border: OutlineInputBorder(),
              ),
              items: _wifiNetworks.map((network) {
                final ssid = network['ssid'] as String;
                final rssi = network['rssi'] as int;
                return DropdownMenuItem(
                  value: ssid,
                  child: Text('$ssid (${rssi}dBm)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWiFiNetwork = value;
                });
              },
            ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _wifiPasswordController,
            decoration: const InputDecoration(
            labelText: 'WiFi Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          
          const SizedBox(height: 24),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[600]))),
                ],
              ),
            ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _configureDevice,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Configure Device'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Step 3: Connecting Device',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          
          const Text(
            'Please wait while the device connects to your WiFi network and registers with the system...',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          if (_userKey != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  const Text('Pairing Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_userKey!, style: const TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red[600])),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green[600],
            ),
            const SizedBox(height: 24),
          
          const Text(
            'Device Added Successfully!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          
          const Text(
            'Your ESP32 device has been successfully added to your account. You can now monitor air quality data in real-time.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // Return success
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}