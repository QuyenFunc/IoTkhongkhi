import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/device_setup_service.dart';
import '../services/bluetooth_setup_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

class DeviceSetupScreen extends StatefulWidget {
  final SetupDevice? setupDevice;

  const DeviceSetupScreen({
    super.key,
    this.setupDevice,
  });

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final DeviceSetupService _setupService = DeviceSetupService();
  final BluetoothSetupService _bluetoothService = BluetoothSetupService();
  final PageController _pageController = PageController();
  
  // Form controllers
  final _wifiSSIDController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();
  
  // State
  int _currentStep = 0;
  bool _isLoading = false;
  DeviceSetupInfo? _deviceInfo;
  String? _errorMessage;

  final List<String> _stepTitles = [
    'Connect to Device',
    'Device Information',
    'WiFi Configuration',
    'Device Settings',
    'Complete Setup',
  ];

  @override
  void initState() {
    super.initState();
    _initializeSetup();
  }

  @override
  void dispose() {
    _wifiSSIDController.dispose();
    _wifiPasswordController.dispose();
    _deviceNameController.dispose();
    _locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeSetup() async {
    if (widget.setupDevice != null) {
      _deviceNameController.text = widget.setupDevice!.displayName;
    }

    // Check if already connected to setup hotspot
    final isConnected = await _setupService.isConnectedToSetupHotspot();
    if (isConnected) {
      setState(() {
        _currentStep = 1;
      });
      _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      await _getDeviceInfo();
    }
  }

  Future<void> _getDeviceInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceInfo = await _setupService.getDeviceSetupInfo();
      if (deviceInfo != null) {
        setState(() {
          _deviceInfo = deviceInfo;
          _deviceNameController.text = 'Air Monitor ${deviceInfo.deviceId}';
        });
      } else {
        setState(() {
          _errorMessage = 'Could not connect to device setup interface';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting device information: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < _stepTitles.length - 1) {
      switch (_currentStep) {
        case 0:
          await _handleConnectStep();
          break;
        case 1:
          await _handleDeviceInfoStep();
          break;
        case 2:
          await _handleWiFiConfigStep();
          break;
        case 3:
          await _handleDeviceSettingsStep();
          break;
        case 4:
          await _handleCompleteSetup();
          break;
      }
    }
  }

  Future<void> _handleConnectStep() async {
    // Guide user to connect to WiFi hotspot
    _goToNextStep();
  }

  Future<void> _handleDeviceInfoStep() async {
    if (_deviceInfo == null) {
      await _getDeviceInfo();
      if (_deviceInfo == null) return;
    }
    _goToNextStep();
  }

  Future<void> _handleWiFiConfigStep() async {
    if (!_validateWiFiForm()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = DeviceWiFiConfig(
        ssid: _wifiSSIDController.text.trim(),
        password: _wifiPasswordController.text,
      );

      final success = await _setupService.configureDeviceWiFi(config);
      if (success) {
        _goToNextStep();
      } else {
        setState(() {
          _errorMessage = 'Failed to configure WiFi. Please check credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error configuring WiFi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeviceSettingsStep() async {
    if (!_validateDeviceSettingsForm()) return;
    _goToNextStep();
  }

  Future<void> _handleCompleteSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Configure Firebase
      final firebaseConfig = DeviceFirebaseConfig(
        projectId: 'iotsmart-7a145',
        databaseURL: 'https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app',
        apiKey: 'your-api-key', // You'll need to get this from Firebase console
      );

      final firebaseSuccess = await _setupService.configureDeviceFirebase(firebaseConfig);
      if (!firebaseSuccess) {
        throw Exception('Failed to configure Firebase');
      }

      // Complete setup
      final completeConfig = CompleteSetupConfig(
        deviceId: _deviceInfo?.deviceId ?? widget.setupDevice?.deviceId ?? 'unknown',
        deviceName: _deviceNameController.text.trim(),
        location: _locationController.text.trim(),
        ownerId: user.uid,
      );

      final success = await _setupService.completeDeviceSetup(completeConfig);
      if (success) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = 'Failed to complete setup. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Setup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateWiFiForm() {
    if (_wifiSSIDController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter WiFi network name';
      });
      return false;
    }
    return true;
  }

  bool _validateDeviceSettingsForm() {
    if (_deviceNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter device name';
      });
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter device location';
      });
      return false;
    }
    return true;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Setup Complete!'),
        content: const Text(
          'Your air quality monitor has been successfully configured and added to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close setup screen
              Navigator.of(context).pop(); // Close discovery screen
            },
            child: const Text('Done'),
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
        title: Text(_stepTitles[_currentStep]),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goToPreviousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildConnectStep(theme),
                _buildDeviceInfoStep(theme),
                _buildWiFiConfigStep(theme),
                _buildDeviceSettingsStep(theme),
                _buildCompleteSetupStep(theme),
              ],
            ),
          ),
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _stepTitles.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? theme.primaryColor
                    : theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConnectStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi,
            size: 80,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Connect to Device',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.setupDevice != null) ...[
            Text(
              'Please connect to the WiFi network:',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.setupDevice!.ssid,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '1. Go to WiFi settings\n'
              '2. Connect to the network above\n'
              '3. Return to this app',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'Please connect to your ESP32 device\'s WiFi hotspot:\n\n'
              'Network name starts with:\n'
              '"ESP32-AirMonitor-Setup"',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfoStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (_isLoading) ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting device information...'),
                  ],
                ),
              ),
            ),
          ] else if (_deviceInfo != null) ...[
            Icon(
              Icons.sensors,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Device Found!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildInfoCard('Device ID', _deviceInfo!.deviceId, theme),
            _buildInfoCard('MAC Address', _deviceInfo!.macAddress, theme),
            _buildInfoCard('Firmware', _deviceInfo!.firmwareVersion, theme),
            _buildInfoCard('Hardware', _deviceInfo!.hardwareVersion, theme),
            _buildInfoCard('Chip Model', _deviceInfo!.chipModel, theme),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capabilities',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _deviceInfo!.capabilities.map((capability) {
                        return Chip(
                          label: Text(capability),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Could not connect to device'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWiFiConfigStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.wifi_outlined,
            size: 80,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'WiFi Configuration',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your home WiFi credentials to connect the device to your network.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _wifiSSIDController,
            labelText: 'WiFi Network Name (SSID)',
            prefixIcon: Icons.wifi,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _wifiPasswordController,
            labelText: 'WiFi Password',
            prefixIcon: Icons.lock,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceSettingsStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.settings,
            size: 80,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Device Settings',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Give your device a name and specify its location.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _deviceNameController,
            labelText: 'Device Name',
            prefixIcon: Icons.label,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _locationController,
            labelText: 'Location',
            prefixIcon: Icons.location_on,
            textInputAction: TextInputAction.done,
            hintText: 'e.g., Living Room, Bedroom, Kitchen',
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteSetupStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Completing setup...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'This may take a few moments while the device connects to your WiFi and registers with the cloud.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to Complete',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Review your settings and complete the setup.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Device Name', _deviceNameController.text, theme),
                    _buildSummaryRow('Location', _locationController.text, theme),
                    _buildSummaryRow('WiFi Network', _wifiSSIDController.text, theme),
                    if (_deviceInfo != null)
                      _buildSummaryRow('Device ID', _deviceInfo!.deviceId, theme),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _goToPreviousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == _stepTitles.length - 1 ? 'Complete Setup' : 'Next',
              onPressed: _isLoading ? null : _nextStep,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
