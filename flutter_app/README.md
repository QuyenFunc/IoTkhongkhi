# IoT Air Monitor - Flutter App

Flutter application thay thế hoàn toàn Blynk App cho hệ thống IoT Air Quality Monitor.

## 🚀 Tính Năng

### ✅ Đã Hoàn Thành
- **Firebase Authentication** - Đăng nhập/đăng ký với email & password
- **Real-time Dashboard** - Hiển thị dữ liệu sensor thời gian thực
- **Device Management** - Quản lý nhiều thiết bị ESP32
- **Push Notifications** - Thông báo cảnh báo chất lượng không khí
- **Responsive UI** - Giao diện đẹp và responsive
- **Dark/Light Theme** - Hỗ trợ theme sáng/tối

### 🔄 Thay Thế Blynk
| Blynk Feature | Flutter App Equivalent |
|---------------|----------------------|
| Virtual Pin V0 (Temperature) | Real-time Temperature Display |
| Virtual Pin V1 (Humidity) | Real-time Humidity Display |
| Virtual Pin V2 (Dust PM2.5) | Real-time Air Quality Display |
| Virtual Pin V3 (Check Button) | Quick Action: Check Air Quality |
| Virtual Pin V4 (Auto Warning) | Quick Action: Toggle Auto Warning |
| Blynk Notifications | Firebase Push Notifications |
| Blynk App | Custom Flutter App |

## 📋 Requirements

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Firebase Project
- Android Studio / VS Code

## 🛠️ Setup Instructions

### 1. Clone Repository
```bash
git clone <repository_url>
cd flutter_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### 3.1. Tạo Firebase Project
1. Truy cập [Firebase Console](https://console.firebase.google.com)
2. Tạo project mới: `iotkhongkhi`
3. Enable Authentication (Email/Password)
4. Enable Realtime Database
5. Enable Cloud Messaging

#### 3.2. Cấu hình Platform

**Android:**
1. Thêm Android app vào Firebase project
2. Package name: `com.example.iot_air_monitor`
3. Download `google-services.json`
4. Copy vào `android/app/`

**iOS:**
1. Thêm iOS app vào Firebase project
2. Bundle ID: `com.example.iotAirMonitor`
3. Download `GoogleService-Info.plist`
4. Copy vào `ios/Runner/`

#### 3.3. Cập nhật Firebase Options
Chỉnh sửa `lib/firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',           // Từ google-services.json
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'iotkhongkhi',
  databaseURL: 'https://iotkhongkhi-default-rtdb.asia-southeast1.firebasedatabase.app',
  storageBucket: 'iotkhongkhi.appspot.com',
);
```

### 4. Realtime Database Rules
Import rules từ `../firebase/database-rules.json`:
```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "sensorData": {
      "$deviceId": {
        ".read": "root.child('users').child(auth.uid).child('devices').child($deviceId).exists()",
        ".write": "root.child('users').child(auth.uid).child('devices').child($deviceId).exists()"
      }
    }
  }
}
```

### 5. Run App
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point
├── firebase_options.dart         # Firebase configuration
├── theme/
│   └── app_theme.dart           # App theme & styles
├── models/
│   ├── sensor_data.dart         # Sensor data model
│   ├── device_model.dart        # Device model
│   └── alert_model.dart         # Alert model
├── services/
│   ├── auth_service.dart        # Firebase Authentication
│   ├── device_service.dart      # Device management
│   ├── firebase_service.dart    # Firebase operations
│   └── notification_service.dart # Push notifications
└── screens/
    ├── auth/                    # Login/Register screens
    ├── dashboard/               # Dashboard screen
    ├── devices/                 # Device management
    ├── alerts/                  # Notifications & alerts
    └── profile/                 # User profile
```

## 🔧 Configuration

### Environment Variables
Tạo file `.env` (optional):
```
FIREBASE_PROJECT_ID=iotkhongkhi
FIREBASE_API_KEY=your_api_key
```

### Platform Specific

**Android (`android/app/build.gradle`):**
```gradle
android {
    compileSdkVersion 33
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>App cần quyền truy cập vị trí để xác định thiết bị gần nhất</string>
```

## 📊 Database Structure

```json
{
  "users": {
    "{userUID}": {
      "profile": {
        "email": "user@example.com",
        "displayName": "User Name",
        "fcmToken": "firebase_messaging_token"
      },
      "devices": {
        "{deviceId}": {
          "name": "Living Room Monitor",
          "location": "Living Room",
          "status": "online",
          "settings": {
            "autoWarning": true,
            "tempThreshold1": 18,
            "tempThreshold2": 28,
            "humiThreshold1": 40,
            "humiThreshold2": 70,
            "dustThreshold1": 35,
            "dustThreshold2": 100
          },
          "commands": {
            "checkAirQuality": false,
            "autoWarning": true,
            "restart": false
          }
        }
      }
    }
  },
  "sensorData": {
    "{deviceId}": {
      "{timestamp}": {
        "temperature": 25.5,
        "humidity": 65.2,
        "dustPM25": 45.8,
        "timestamp": 1234567890,
        "status": "online"
      }
    }
  },
  "alerts": {
    "{userUID}": {
      "{alertId}": {
        "deviceId": "ESP32_ABC123",
        "type": "temperature_high",
        "message": "Nhiệt độ cao: 32.5°C",
        "value": 32.5,
        "threshold": 30.0,
        "timestamp": 1234567890,
        "acknowledged": false
      }
    }
  }
}
```

## 🚀 Deployment

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release  # For Play Store
```

### iOS
```bash
flutter build ios --release
```

## 🔍 Troubleshooting

### Common Issues

**1. Firebase Connection Failed**
- Kiểm tra `google-services.json` / `GoogleService-Info.plist`
- Xác nhận package name / bundle ID
- Kiểm tra internet connection

**2. Authentication Error**
- Enable Email/Password authentication trong Firebase Console
- Kiểm tra Firebase Rules
- Verify API keys

**3. Database Permission Denied**
- Kiểm tra Database Rules
- Xác nhận user đã đăng nhập
- Verify database URL

**4. Push Notifications Not Working**
- Enable Cloud Messaging
- Kiểm tra FCM token
- Test với Firebase Console

### Debug Commands
```bash
# Check Firebase connection
flutter doctor

# Debug mode with logs
flutter run --debug

# Clear cache
flutter clean
flutter pub get
```

## 📱 Screenshots

### Login Screen
- Firebase Authentication
- Modern UI design
- Social login ready

### Dashboard
- Real-time sensor data
- Quick actions (V3, V4 equivalent)
- Device overview
- Air quality trends

### Device Management
- Add/remove devices
- Device settings
- Real-time status
- Command controls

### Notifications
- Real-time alerts
- Push notifications
- Alert history
- Custom thresholds

## 🔮 Future Enhancements

- [ ] QR Code device pairing
- [ ] Data export (CSV, PDF)
- [ ] Advanced charts & analytics
- [ ] Voice commands
- [ ] Apple Watch / Wear OS support
- [ ] Geofencing alerts
- [ ] Social sharing
- [ ] Multi-language support

## 📞 Support

- 📧 Email: support@iotairmonitor.com
- 🐛 Issues: GitHub Issues
- 📖 Documentation: Project Wiki

---

**Made with ❤️ by IoT Air Monitor Team**


