import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../devices/devices_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  final List<Widget> _screens = [
    DashboardScreen(),
    DevicesScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];
  
  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      activeIcon: Icon(Icons.dashboard),
      label: 'Tổng quan',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.devices),
      activeIcon: Icon(Icons.devices),
      label: 'Thiết bị',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications),
      activeIcon: Icon(Icons.notifications),
      label: 'Cảnh báo',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      activeIcon: Icon(Icons.person),
      label: 'Cá nhân',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController(initialPage: _currentIndex);
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize services
    _initializeServices();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
  
  void _initializeServices() async {
    // Initialize Firebase service
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    await firebaseService.initializeUserData();
    
    // Initialize Device service
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    await deviceService.initialize();
    
    // Initialize Notification service
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.initialize();
    
    // Show FAB animation
    _fabAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 8,
          items: _navItems.map((item) {
            // Add badge for alerts tab
            if (item.label == 'Cảnh báo' && notificationService.unreadAlertsCount > 0) {
              return BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    item.icon,
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationService.unreadAlertsCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                activeIcon: Stack(
                  children: [
                    item.activeIcon,
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationService.unreadAlertsCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                label: item.label,
              );
            }
            return item;
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildFloatingActionButton() {
    // Show FAB only on dashboard and devices screens
    if (_currentIndex != 0 && _currentIndex != 1) {
      return SizedBox.shrink();
    }
    
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: _currentIndex == 0 ? _refreshAllData : _addNewDevice,
        child: Icon(_currentIndex == 0 ? Icons.refresh : Icons.add),
        backgroundColor: AppTheme.primaryColor,
        heroTag: "mainFAB",
      ),
    );
  }
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _refreshAllData() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Đang cập nhật dữ liệu...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      // Refresh Firebase data
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.initializeUserData();
      
      // Refresh Device data
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      await deviceService.loadUserDevices();
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Dữ liệu đã được cập nhật'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 16),
              Text('Lỗi cập nhật dữ liệu'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _addNewDevice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDeviceBottomSheet(),
    );
  }
}

class AddDeviceBottomSheet extends StatefulWidget {
  @override
  _AddDeviceBottomSheetState createState() => _AddDeviceBottomSheetState();
}

class _AddDeviceBottomSheetState extends State<AddDeviceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Title
            Row(
              children: [
                Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Thêm thiết bị mới',
                  style: AppStyles.heading2(context),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Device ID
                    TextFormField(
                      controller: _deviceIdController,
                      decoration: InputDecoration(
                        labelText: 'Mã thiết bị (Device ID)',
                        prefixIcon: Icon(Icons.qr_code),
                        hintText: 'Ví dụ: ESP32_ABCD1234',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            // TODO: Implement QR code scanner
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tính năng quét QR sẽ được thêm sau'),
                              ),
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã thiết bị';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Device Name
                    TextFormField(
                      controller: _deviceNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên thiết bị',
                        prefixIcon: Icon(Icons.device_hub),
                        hintText: 'Ví dụ: Cảm biến phòng khách',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên thiết bị';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Vị trí',
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Ví dụ: Phòng khách, Phòng ngủ',
                      ),
                    ),
                    
                    Spacer(),
                    
                    // Add Button
                    Consumer<DeviceService>(
                      builder: (context, deviceService, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: deviceService.isLoading
                                ? null
                                : () => _handleAddDevice(deviceService),
                            child: deviceService.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Thêm thiết bị'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleAddDevice(DeviceService deviceService) async {
    if (_formKey.currentState!.validate()) {
      bool success = await deviceService.addDevice(
        _deviceIdController.text.trim(),
        _deviceNameController.text.trim(),
        _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
      );
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thiết bị đã được thêm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deviceService.errorMessage ?? 'Lỗi thêm thiết bị'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}