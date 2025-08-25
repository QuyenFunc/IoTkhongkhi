# IoT Air Quality Monitor System

Hệ thống giám sát chất lượng không khí IoT tích hợp ESP32, Firebase và Flutter App.

## 🏗️ Kiến Trúc Hệ Thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Firebase      │◄──►│     ESP32       │
│                 │    │   Database      │    │   Air Monitor   │
│ • User Login    │    │                 │    │                 │
│ • Device Mgmt   │    │ • User Data     │    │ • WiFi Setup    │
│ • Real-time     │    │ • Device Info   │    │ • Sensor Data   │
│   Monitoring    │    │ • Sensor Data   │    │ • Commands      │
│ • Alerts        │    │ • Security      │    │ • Status        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Tính Năng

### ESP32 Features
- ✅ WiFi Hotspot Setup (Captive Portal)
- ✅ Firebase Integration
- ✅ Real-time Sensor Data Transmission
- ✅ Remote Command Handling
- ✅ OLED Display Status
- ✅ Device Registration & Authentication
- ✅ Automatic Reconnection
- ✅ OTA Updates Ready

### Flutter App Features
- 🔐 Firebase Authentication
- 📱 Device Registration & Management
- 📊 Real-time Data Visualization
- 🔔 Push Notifications & Alerts
- ⚙️ Remote Device Control
- 👤 User Profile Management
- 📈 Historical Data Charts

### Firebase Features
- 🔒 Security Rules
- 📡 Realtime Database
- 🔐 Authentication
- 📱 Cloud Messaging
- 🔍 Analytics Ready

## 🚀 Quick Start

### 1. Firebase Setup

1. Tạo Firebase Project tại [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication với Email/Password
3. Enable Realtime Database
4. Import database structure:
   ```bash
   # Upload file firebase/database-structure.json
   ```
5. Cấu hình Security Rules:
   ```bash
   # Upload file firebase/database-rules.json
   ```

### 2. ESP32 Setup

1. **Hardware Requirements:**
   - ESP32 DevKit
   - SSD1306 OLED Display (0x3C)
   - Sensors (DHT22, MQ-135, etc.)
   
2. **Library Dependencies:**
   ```cpp
   // Required libraries trong Arduino IDE:
   - WiFi
   - WebServer  
   - DNSServer
   - ArduinoJson
   - Preferences
   - SSD1306Wire
   - Wire
   - HTTPClient
   - WiFiClientSecure
   ```

3. **Upload Code:**
   ```bash
   # Mở file esp32/ESP32_WiFi_Hotspot_Setup.ino trong Arduino IDE
   # Chọn board: ESP32 Dev Module
   # Upload code
   ```

### 3. Flutter App Setup

1. **Install Dependencies:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Firebase Configuration:**
   ```bash
   # Thêm google-services.json (Android)
   # Thêm GoogleService-Info.plist (iOS)
   # Cấu hình firebase_options.dart
   ```

3. **Run App:**
   ```bash
   flutter run
   ```

## 📖 Hướng Dẫn Sử Dụng

### Đăng Ký Thiết Bị Mới

1. **Kết nối ESP32 lần đầu:**
   - ESP32 tạo WiFi hotspot: `ESP32-Setup-XXXXXX`
   - Password: `12345678`
   - Truy cập: `http://192.168.4.1`

2. **Cấu hình WiFi:**
   - Chọn WiFi mạng gia đình
   - Nhập mật khẩu
   - ESP32 sẽ kết nối internet

3. **Đăng ký qua App:**
   - Mở Flutter app
   - Đăng nhập tài khoản
   - Thêm thiết bị mới
   - Quét QR code hoặc nhập Device ID

4. **Hoàn tất:**
   - ESP32 tự động đăng ký với Firebase
   - Bắt đầu gửi dữ liệu sensor
   - Hiển thị real-time trong app

### Monitoring & Control

1. **Xem dữ liệu real-time:**
   - Temperature, Humidity, Air Quality
   - Charts và graphs
   - Historical data

2. **Điều khiển thiết bị:**
   - Restart device
   - Update settings
   - Change location
   - Reset configuration

3. **Alerts & Notifications:**
   - Ngưỡng cảnh báo tự động
   - Push notifications
   - Email alerts (tuỳ chọn)

## 🔧 Database Structure

```json
{
  "users": {
    "{userUID}": {
      "profile": { "email", "displayName", "createdAt" },
      "devices": {
        "{deviceId}": {
          "deviceInfo": "...",
          "commands": { "restart", "location", "updateInterval" }
        }
      }
    }
  },
  "sensorData": {
    "{deviceId}": {
      "{timestamp}": {
        "temperature": 25.5,
        "humidity": 65.2,
        "airQuality": 45.8
      }
    }
  },
  "deviceRegistry": {
    "{deviceId}": {
      "ownerUID": "{userUID}",
      "status": "online"
    }
  }
}
```

## 🔒 Security Features

- Firebase Security Rules
- Device Token Authentication  
- User UID Validation
- HTTPS/WSS Communication
- Input Validation & Sanitization

## 📊 API Endpoints

### ESP32 REST API
```
GET  /api/info          - Device information
GET  /api/scan          - WiFi networks scan
POST /api/configure     - WiFi configuration
GET  /api/status        - Connection status
POST /api/device/register - Device registration
GET  /api/device/info   - Device details
POST /api/device/reset  - Factory reset
```

### Firebase Realtime Database
```
/users/{uid}/devices/{deviceId}     - Device management
/sensorData/{deviceId}/{timestamp}  - Sensor readings
/deviceRegistry/{deviceId}          - Global device registry
/alerts/{uid}/{alertId}             - User alerts
```

## 🛠️ Development

### ESP32 Development
```cpp
// Thêm sensor mới
void readSensors() {
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();
  airQuality = analogRead(MQ135_PIN);
}

// Thêm command mới
if (doc.containsKey("newCommand")) {
  String value = doc["newCommand"];
  // Process command
  clearCommand("newCommand");
}
```

### Flutter Development
```dart
// Thêm screen mới
class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Data>(
      stream: deviceService.getNewData(),
      builder: (context, snapshot) {
        // Build UI
      },
    );
  }
}
```

## 🔧 Troubleshooting

### ESP32 Issues
- **WiFi connection failed:** Check credentials, signal strength
- **Firebase registration failed:** Verify token, user UID  
- **Sensor readings incorrect:** Check wiring, calibration
- **OLED display issues:** Verify I2C address (0x3C/0x3D)

### Flutter App Issues
- **Login failed:** Check Firebase Auth configuration
- **No devices showing:** Verify database rules, user permissions
- **Real-time updates not working:** Check internet connection, Firebase config

### Firebase Issues
- **Permission denied:** Review security rules
- **Data not syncing:** Check database structure, indexes
- **Authentication errors:** Verify API keys, project settings

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📞 Support

- 📧 Email: support@iotairmonitor.com
- 📱 Telegram: @iotairsupport
- 🐛 Issues: GitHub Issues
- 📖 Documentation: Wiki

---

**Made with ❤️ for IoT enthusiasts**