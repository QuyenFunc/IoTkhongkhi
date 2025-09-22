# 🔧 ESP32 Debug Guide - Sửa lỗi WiFi Connection

## ❌ **Vấn đề đã phát hiện:**

**ESP32 không kết nối được WiFi vì EEPROM trống/corrupt dẫn tới SSID và Password bị xóa!**

### 🔍 **Root Cause Analysis:**

1. **EEPROM trống/chưa được init** → `readEEPROM()` đọc toàn giá trị `0` hoặc `255`
2. **`readEEPROM()` set lại:** `Essid = ""`, `Epass = ""` (xóa values từ `data_config.h`)
3. **Validation fail:** `Essid.length() == 0` → invalid WiFi config  
4. **Bug:** Code chỉ print warning nhưng vẫn tiếp tục với SSID rỗng
5. **`connectSTA()` fail:** WiFi.begin("", "") → không kết nối được
6. **Enter setup mode:** Thay vì dùng defaults

## ✅ **Giải pháp đã implement:**

### **1. 🔧 Fixed setup() function:**
```cpp
// Trong setup(), sau readEEPROM():
if (!validWiFiConfig) {
    Serial.println("⚠️ WiFi configuration invalid, restoring defaults from data_config.h...");
    
    // Restore defaults from data_config.h when EEPROM is empty/invalid
    if (Essid.length() == 0 || Essid == "BLK") {
      Essid = "ADMIN-PC 9549";  // From data_config.h
      Serial.println("🔧 Restored default SSID: " + Essid);
    }
    if (Epass.length() == 0) {
      Epass = "12345678";  // From data_config.h
      Serial.println("🔧 Restored default Password");
    }
    
    // Write restored defaults to EEPROM for future use
    Serial.println("💾 Saving restored defaults to EEPROM...");
    writeEEPROM();
}
```

### **2. 🆔 Enhanced Device ID generation:**
```cpp
// Generate device ID với debug logs
deviceId = WiFi.macAddress();
deviceId.replace(":", "");
deviceId = "ESP32-" + deviceId;
Serial.println("🆔 Generated Device ID: " + deviceId);
```

### **3. 👤 Fixed UserUID assignment:**
```cpp
if (EuserUID.length() == 0) {
    EuserUID = "MUnksHfJxlWeWCT9ogPktWRIQu83"; // From data_config.h
    Serial.println("🔧 Restored default UserUID: " + EuserUID);
}
```

### **4. 🛠️ Added Debug Commands:**
```cpp
// Trong loop(), ESP32 lắng nghe Serial commands:
if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    
    // Commands available:
    // CLEAR_EEPROM     - Clear all EEPROM data
    // DEBUG_CONFIG     - Show current config  
    // DEBUG_EEPROM     - Show raw EEPROM data
    // WRITE_DEFAULTS   - Write default values to EEPROM
    // RESTART          - Restart ESP32
}
```

## 🔧 **Debug Steps:**

### **Step 1: Upload code và monitor Serial**
```bash
# Arduino IDE:
Tools → Serial Monitor (115200 baud)

# hoặc Platform.io:
pio device monitor

# hoặc command line:
screen /dev/ttyUSB0 115200
```

### **Step 2: Check boot log**
Sau khi restart, bạn sẽ thấy:
```
📖 Reading EEPROM configuration...
📊 EEPROM Read Results:
   📶 SSID: '' (0 chars)          ← EEPROM trống!
   🔒 Pass: 0 chars
   🔥 Host: 0 chars
   🗝️  Auth: 0 chars

⚠️ WiFi configuration invalid, restoring defaults from data_config.h...
🔧 Restored default SSID: ADMIN-PC 9549
🔧 Restored default Password
💾 Saving restored defaults to EEPROM...

✅ Using configuration (auto or stored):
📡 WiFi SSID: ADMIN-PC 9549       ← Restored!
🔥 Firebase Host: iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app
👤 UserUID: MUnksHfJxlWeWCT9ogPktWRIQu83
```

### **Step 3: WiFi Connection**
```
╔══════════════════════════════════════╗
║           CONNECTING TO WiFi         ║
╚══════════════════════════════════════╝
📡 SSID: ADMIN-PC 9549
🔐 Password: [HIDDEN 8 chars]
🔄 WiFi connection attempt 1/2
📶 Connecting to WiFi: ADMIN-PC 9549
⏱️  Waiting for connection... (timeout: 30s)
✅ WiFi connected successfully!
📡 IP address: 192.168.1.100
📶 Signal strength: -45 dBm
```

### **Step 4: Firebase Connection**
```
🔥 Configuring Firebase...
🔥 Firebase Host: iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app
🗝️  Firebase API Key: [HIDDEN]
✅ Firebase ready!
```

### **Step 5: Data Sending**
```
📊 Reading sensors...
🌡️ Temperature: 25.5°C
💧 Humidity: 65.2%
🌫️ Air Quality: 45.8 μg/m³
📤 Sending sensor data to Firebase...
✅ Device info sent to user path: MUnksHfJxlWeWCT9ogPktWRIQu83
✅ Sensor data sent to user path: MUnksHfJxlWeWCT9ogPktWRIQu83
✅ Device info sent to global path
✅ Sensor data sent to global path
📊 Historical data saved to both paths
```

## 🆘 **Troubleshooting Commands:**

### **Nếu EEPROM bị corrupt:**
```
CLEAR_EEPROM        ← Clear toàn bộ EEPROM và restart
```

### **Nếu muốn force write defaults:**
```
WRITE_DEFAULTS      ← Write default WiFi credentials
RESTART             ← Restart để apply changes
```

### **Debug current state:**
```
DEBUG_CONFIG        ← Xem config hiện tại
DEBUG_EEPROM        ← Xem raw EEPROM data
```

## 📊 **Expected Results:**

### **1. Serial Log sẽ thấy:**
- ✅ EEPROM restored với defaults
- ✅ WiFi connected tới "ADMIN-PC 9549"  
- ✅ Firebase connected
- ✅ Device ID generated (ESP32-XXXXXXXXXXXX)
- ✅ Sensor data sending every 10 seconds
- ✅ Historical data saving every 30 seconds

### **2. Firebase Database sẽ có:**
```json
{
  "devices": {
    "ESP32-XXXXXXXXXXXX": {
      "deviceId": "ESP32-XXXXXXXXXXXX",
      "deviceName": "Air Quality Monitor",
      "status": "online",
      "current": {
        "temperature": 25.5,
        "humidity": 65.2,
        "airQuality": 45.8
      }
    }
  },
  "sensorData": {
    "ESP32-XXXXXXXXXXXX": {
      "latest": {
        "temperature": 25.5,
        "humidity": 65.2,
        "airQuality": 45.8,
        "timestamp": "1640995200000"
      }
    }
  }
}
```

### **3. Android App sẽ hiển thị:**
- 📱 Device list với ESP32
- 📊 Real-time sensor data
- 📈 Historical charts 
- 🔔 Alerts (nếu có)

## 🎯 **Success Indicators:**

### **✅ WiFi Connected:**
```
✅ WiFi connected successfully!
📡 IP address: 192.168.1.xxx
```

### **✅ Firebase Ready:**
```
✅ Firebase ready!
```

### **✅ Data Flowing:**
```
✅ Latest sensor data sent to Firebase for user: MUnksHfJxlWeWCT9ogPktWRIQu83
✅ Device info sent to global path
✅ Sensor data sent to global path
```

**ESP32 bây giờ sẽ tự động restore WiFi defaults và connect thành công!** 🎉

## 🚨 **Emergency Recovery:**

Nếu mọi thứ vẫn không work:

1. **Power cycle:** Tắt nguồn ESP32 30 giây, bật lại
2. **Clear EEPROM:** Send `CLEAR_EEPROM` qua Serial Monitor
3. **Re-flash firmware:** Upload lại code hoàn toàn mới
4. **Check hardware:** WiFi antenna, power supply
5. **Check network:** Đảm bảo "ADMIN-PC 9549" network tồn tại và accessible
