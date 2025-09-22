# 🔥 Firebase Structure with User UID: MUnksHfJxlWeWCT9ogPktWRIQu83

## 📊 **Cấu trúc Firebase mới với UID**

```json
{
  "users": {
    "MUnksHfJxlWeWCT9ogPktWRIQu83": {
      "profile": {
        "displayName": "Admin User",
        "email": "admin@example.com",
        "createdAt": "timestamp"
      },
      "devices": {
        "ESP32-AABBCCDDEEFF": {
          "deviceId": "ESP32-AABBCCDDEEFF",
          "deviceName": "Air Quality Monitor",
          "location": "Auto Location", 
          "macAddress": "AA:BB:CC:DD:EE:FF",
          "ipAddress": "192.168.1.100",
          "wifiSSID": "ADMIN-PC 9549",
          "status": "online",
          "lastSeen": "timestamp",
          "firmware": "1.0.0",
          "createdAt": "timestamp",
          
          "sensorData": {
            "latest": {
              "timestamp": "timestamp",
              "deviceId": "ESP32-AABBCCDDEEFF",
              "temperature": 25.5,
              "humidity": 65.2,
              "airQuality": 45.8,
              "pm25": 12.3,
              "pm10": 23.4,
              "co2": 400.5,
              "status": "online",
              "battery": 100,
              "rssi": -45
            },
            "history": {
              "1640995200000": {
                "timestamp": "1640995200000",
                "temperature": 25.5,
                "humidity": 65.2,
                "airQuality": 45.8,
                "pm25": 12.3,
                "pm10": 23.4,
                "co2": 400.5
              }
            }
          },
          
          "commands": {
            "restart": {
              "command": "restart",
              "value": true,
              "timestamp": "timestamp",
              "status": "pending"
            },
            "autoWarning": {
              "command": "autoWarning",
              "value": true,
              "timestamp": "timestamp", 
              "status": "completed"
            }
          },
          
          "alertThresholds": {
            "temperature": {
              "min": 15.0,
              "max": 35.0,
              "enabled": true
            },
            "humidity": {
              "min": 30.0,
              "max": 80.0,
              "enabled": true
            },
            "airQuality": {
              "min": 0.0,
              "max": 50.0,
              "enabled": true
            }
          },
          
          "alerts": {
            "alert_1640995200000": {
              "alertId": "alert_1640995200000",
              "deviceId": "ESP32-AABBCCDDEEFF",
              "type": "temperature",
              "message": "Temperature exceeded threshold: 37.2°C",
              "value": 37.2,
              "threshold": 35.0,
              "timestamp": "1640995200000",
              "acknowledged": false
            }
          }
        }
      }
    }
  }
}
```

## 🚀 **ESP32 Data Paths**

### **Device Registration:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}
Data: Device info, status, network details
```

### **Latest Sensor Data:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/latest
Data: Real-time sensor readings
```

### **Historical Data:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/history/{timestamp}
Data: Historical sensor readings for charts
```

### **Commands:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/commands/{commandName}
Data: Commands from Android app to ESP32
```

### **Alert Thresholds:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/alertThresholds
Data: Configurable alert thresholds
```

### **Alerts:**
```
Path: /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/alerts/{alertId}
Data: Generated alerts when thresholds exceeded
```

## 🔧 **ESP32 Configuration**

### **data_config.h:**
```cpp
String EuserUID = "MUnksHfJxlWeWCT9ogPktWRIQu83";
```

### **ESP32 Auto-sends data to:**
- ✅ `/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}` - Device status
- ✅ `/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/latest` - Real-time data  
- ✅ `/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/history` - Historical data
- ✅ `/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/alerts` - Alert events

### **ESP32 Checks commands from:**
- ✅ `/users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/commands` - Commands from app

## 📱 **Android App Paths**

### **Read device list:**
```dart
DatabaseReference ref = FirebaseDatabase.instance
    .ref('users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices');
```

### **Read real-time sensor data:**
```dart
DatabaseReference ref = FirebaseDatabase.instance
    .ref('users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/$deviceId/sensorData/latest');
```

### **Send commands:**
```dart
DatabaseReference ref = FirebaseDatabase.instance
    .ref('users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/$deviceId/commands');
```

## 🔐 **Firebase Security Rules**

```json
{
  "rules": {
    "users": {
      "MUnksHfJxlWeWCT9ogPktWRIQu83": {
        ".read": true,
        ".write": true,
        "devices": {
          "$deviceId": {
            ".indexOn": ["status", "lastSeen"],
            "sensorData": {
              "history": {
                ".indexOn": ["timestamp"]
              }
            },
            "alerts": {
              ".indexOn": ["timestamp", "acknowledged"]
            }
          }
        }
      }
    }
  }
}
```

## ✅ **Lỗi đã sửa:**

### **1. String concatenation với ternary operator:**
```cpp
// ❌ Lỗi:
message = "Temperature " + (value > threshold ? "exceeded" : "below") + " threshold";

// ✅ Đã sửa:
String status = (value > threshold) ? "exceeded" : "below";
message = "Temperature " + status + " threshold: " + String(value) + "°C";
```

### **2. UID Configuration:**
```cpp
// ✅ Updated data_config.h:
String EuserUID = "MUnksHfJxlWeWCT9ogPktWRIQu83";
```

### **3. Firebase paths với UID:**
```cpp
// ✅ All paths now include user UID:
String devicePath = "/users/" + userUID + "/devices/" + deviceId;
String latestPath = "/users/" + userUID + "/devices/" + deviceId + "/sensorData/latest";
String historyPath = "/users/" + userUID + "/devices/" + deviceId + "/sensorData/history/" + timestamp;
String commandPath = "/users/" + userUID + "/devices/" + deviceId + "/commands";
String thresholdPath = "/users/" + userUID + "/devices/" + deviceId + "/alertThresholds";
String alertPath = "/users/" + userUID + "/devices/" + deviceId + "/alerts/" + alertId;
```

## 🎯 **Data Flow với UID:**

```
ESP32 → Firebase (UID: MUnksHfJxlWeWCT9ogPktWRIQu83) → Android App

1. ESP32 startup → Auto connect WiFi
2. ESP32 → Send device status to /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}
3. ESP32 → Send sensor data to /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/latest
4. ESP32 → Save history to /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/sensorData/history
5. ESP32 → Check alerts thresholds, create alerts if needed
6. ESP32 → Check commands from /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/commands
7. Android App → Read all data từ /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices
8. Android App → Send commands to /users/MUnksHfJxlWeWCT9ogPktWRIQu83/devices/{deviceId}/commands
```

**ESP32 hiện sẽ gửi tất cả dữ liệu tới UID: `MUnksHfJxlWeWCT9ogPktWRIQu83`** 🎉
