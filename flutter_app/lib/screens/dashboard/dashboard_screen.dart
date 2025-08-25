import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/device_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/sensor_data.dart';
import '../../models/device_model.dart';
import '../../theme/app_theme.dart';
import '../devices/device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeCard(),
                  SizedBox(height: 16),
                  _buildOverviewCards(),
                  SizedBox(height: 16),
                  _buildQuickActions(),
                  SizedBox(height: 16),
                  _buildDevicesList(),
                  SizedBox(height: 16),
                  _buildAirQualityTrend(),
                  SizedBox(height: 100), // Extra space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'IoT Air Monitor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryDarkColor,
              ],
            ),
          ),
        ),
      ),
      actions: [
        Consumer<NotificationService>(
          builder: (context, notificationService, child) {
            return Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/alerts');
                  },
                ),
                if (notificationService.unreadAlertsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
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
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildWelcomeCard() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        String userName = authService.currentUser?.displayName ?? 'Người dùng';
        String greeting = _getGreeting();
        
        return AnimationConfiguration.staggeredList(
          position: 0,
          duration: Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration(context).copyWith(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.primaryDarkColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hôm nay chất lượng không khí như thế nào?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.air,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOverviewCards() {
    return Consumer<DeviceService>(
      builder: (context, deviceService, child) {
        Map<String, double> averageValues = deviceService.averageValues;
        String overallStatus = deviceService.overallAirQualityStatus;
        
        return AnimationConfiguration.staggeredList(
          position: 1,
          duration: Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Row(
                children: [
                  Expanded(
                    child: _buildOverviewCard(
                      'Nhiệt độ',
                      '${averageValues['temperature']?.toStringAsFixed(1) ?? '--'}°C',
                      Icons.thermostat,
                      AppTheme.temperatureColor,
                      _getTemperatureStatus(averageValues['temperature']),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'Độ ẩm',
                      '${averageValues['humidity']?.toStringAsFixed(1) ?? '--'}%',
                      Icons.water_drop,
                      AppTheme.humidityColor,
                      _getHumidityStatus(averageValues['humidity']),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewCard(
                      'PM2.5',
                      '${averageValues['dustPM25']?.toStringAsFixed(1) ?? '--'}',
                      Icons.air,
                      AppTheme.dustColor,
                      _getAirQualityStatus(overallStatus),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, String status) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: AppStyles.sensorCardDecoration(color),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return AnimationConfiguration.staggeredList(
      position: 2,
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thao tác nhanh',
                  style: AppStyles.heading2(context),
                ),
                SizedBox(height: 16),
                Consumer<DeviceService>(
                  builder: (context, deviceService, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Kiểm tra chất lượng KK',
                            Icons.search,
                            AppTheme.infoColor,
                            () => _checkAirQuality(deviceService),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Cảnh báo tự động',
                            Icons.notifications_active,
                            AppTheme.warningColor,
                            () => _toggleAutoWarning(deviceService),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDevicesList() {
    return Consumer<DeviceService>(
      builder: (context, deviceService, child) {
        List<DeviceModel> devices = deviceService.devices.values.toList();
        
        if (devices.isEmpty) {
          return _buildEmptyDevicesCard();
        }
        
        return AnimationConfiguration.staggeredList(
          position: 3,
          duration: Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thiết bị của tôi',
                          style: AppStyles.heading2(context),
                        ),
                        Text(
                          '${devices.length} thiết bị',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...devices.take(3).map((device) => _buildDeviceItem(device, deviceService)),
                    if (devices.length > 3)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () {
                            // Navigate to devices screen
                            DefaultTabController.of(context)?.animateTo(1);
                          },
                          child: Text('Xem tất cả ${devices.length} thiết bị'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDeviceItem(DeviceModel device, DeviceService deviceService) {
    SensorData? latestData = deviceService.getLatestSensorData(device.id!);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isOnline ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(device: device),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: device.isOnline ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (device.location != null)
                    Text(
                      device.location!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (latestData != null) ...[
              _buildMiniSensorValue('${latestData.temperature?.toStringAsFixed(1) ?? '--'}°C', AppTheme.temperatureColor),
              SizedBox(width: 8),
              _buildMiniSensorValue('${latestData.humidity?.toStringAsFixed(1) ?? '--'}%', AppTheme.humidityColor),
              SizedBox(width: 8),
              _buildMiniSensorValue('${latestData.dustPM25?.toStringAsFixed(1) ?? '--'}', AppTheme.dustColor),
            ],
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiniSensorValue(String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildEmptyDevicesCard() {
    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: AppStyles.cardDecoration(context),
            child: Column(
              children: [
                Icon(
                  Icons.devices_other,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có thiết bị nào',
                  style: AppStyles.heading2(context).copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Thêm thiết bị đầu tiên để bắt đầu giám sát chất lượng không khí',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // This will be handled by the FAB in HomeScreen
                  },
                  icon: Icon(Icons.add),
                  label: Text('Thêm thiết bị'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAirQualityTrend() {
    return AnimationConfiguration.staggeredList(
      position: 4,
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xu hướng chất lượng không khí',
                  style: AppStyles.heading2(context),
                ),
                SizedBox(height: 16),
                // Placeholder for chart - you can implement with fl_chart
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 8),
                        Text(
                          'Biểu đồ xu hướng',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Sẽ được hiển thị khi có dữ liệu',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper methods
  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
  
  String _getTemperatureStatus(double? temp) {
    if (temp == null) return 'Không có dữ liệu';
    if (temp < 18) return 'Lạnh';
    if (temp > 28) return 'Nóng';
    return 'Bình thường';
  }
  
  String _getHumidityStatus(double? humidity) {
    if (humidity == null) return 'Không có dữ liệu';
    if (humidity < 40) return 'Khô';
    if (humidity > 70) return 'Ẩm';
    return 'Bình thường';
  }
  
  String _getAirQualityStatus(String status) {
    switch (status) {
      case 'good': return 'Tốt';
      case 'moderate': return 'Trung bình';
      case 'unhealthy_sensitive': return 'Kém';
      case 'unhealthy': return 'Xấu';
      case 'hazardous': return 'Nguy hiểm';
      default: return 'Không rõ';
    }
  }
  
  // Action handlers (equivalent to Blynk virtual pins)
  void _checkAirQuality(DeviceService deviceService) async {
    List<DeviceModel> onlineDevices = deviceService.onlineDevices;
    
    if (onlineDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không có thiết bị nào đang online'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Send check command to all online devices (equivalent to Blynk V3)
    bool anySuccess = false;
    for (DeviceModel device in onlineDevices) {
      bool success = await deviceService.checkAirQuality(device.id!);
      if (success) anySuccess = true;
    }
    
    if (anySuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lệnh kiểm tra chất lượng không khí'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi lệnh kiểm tra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _toggleAutoWarning(DeviceService deviceService) async {
    List<DeviceModel> onlineDevices = deviceService.onlineDevices;
    
    if (onlineDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không có thiết bị nào đang online'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Toggle auto warning for all devices (equivalent to Blynk V4)
    bool newState = !onlineDevices.first.settings!.autoWarning;
    bool anySuccess = false;
    
    for (DeviceModel device in onlineDevices) {
      bool success = await deviceService.toggleAutoWarning(device.id!, newState);
      if (success) anySuccess = true;
    }
    
    if (anySuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? 'Đã bật cảnh báo tự động' : 'Đã tắt cảnh báo tự động'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thay đổi cài đặt cảnh báo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _refreshData() async {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    await deviceService.loadUserDevices();
  }
}


