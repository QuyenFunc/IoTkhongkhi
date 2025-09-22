#include <WiFi.h>
#include <WiFiClient.h>
#include <Firebase_ESP_Client.h>
 #include <addons/TokenHelper.h>
 #include <addons/RTDBHelper.h>
#include "data_config.h"
#include <EEPROM.h>
#include <Arduino_JSON.h>
#include <time.h>
 
// Firebase configuration
#define DATABASE_URL "https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define API_KEY "AIzaSyDL1iwM9wuJzg2fw2mP-aIM69Y16fU6Kdg"

// WiFi configuration - Thay đổi thông tin WiFi của bạn ở đây
#define WIFI_SSID "Pixel_9315"        // Thay tên WiFi của bạn
#define WIFI_PASSWORD "0000000000"         // Thay mật khẩu WiFi của bạn


// Firebase objects
FirebaseData fbdo;
FirebaseData streamData;  // Dành cho stream
FirebaseAuth auth;
FirebaseConfig config;
bool firebaseConnected = false;
bool streamConnected = false;

// NTP Server settings
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 7 * 3600;  // GMT+7 for Vietnam
const int daylightOffset_sec = 0;

String deviceId;

// OLED 1.3" settings
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

#define i2c_Address 0x3C
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SH1106G oled = Adafruit_SH1106G(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Simple screen modes
typedef enum {
  SCREEN_INIT,
  SCREEN_SENSOR_DATA,
  SCREEN_WIFI_STATUS,
  SCREEN_FIREBASE_STATUS
} SCREEN_MODE;

SCREEN_MODE currentScreen = SCREEN_INIT;
unsigned long lastScreenUpdate = 0;
unsigned long lastDataSend = 0;
unsigned long lastSensorRead = 0;

// DHT11 sensor
#include "DHT.h"
#define DHT11_PIN 26
#define DHTTYPE DHT11
DHT dht(DHT11_PIN, DHTTYPE);
float tempValue = 30;
int humiValue = 60;
bool dht11ReadOK = true;

// Dust sensor
#include <GP2Y1010AU0F.h>
#define DUST_TRIG 23
#define DUST_ANALOG 36
GP2Y1010AU0F dustSensor(DUST_TRIG, DUST_ANALOG);
int dustValue = 10;

// GPIO pins
#define LED 33
#define BUZZER 2

// Simple thresholds (stored in EEPROM)
struct SimpleThresholds {
  float tempMin = 15.0;
  float tempMax = 35.0;
  float humMin = 30.0;
  float humMax = 80.0;
  float pm25Max = 100.0;
  uint32_t checksum;
};

SimpleThresholds thresholds;
bool alertActive = false;
unsigned long lastAlertTime = 0;

// Function declarations
void setup();
void loop();
void initWiFi();
void scanAvailableWiFi();
void initFirebase();
bool ensureTimeSynced(uint8_t maxRetries = 10);
void setupFirebaseListeners();
void handleFirebaseUpdates();
void onThresholdUpdate(FirebaseStream data);
void onStreamTimeout(bool timeout);
void displayThresholdChangeMessage();
void uploadCurrentThresholds();
void readSensors();
void updateOLED();
void sendDataToFirebase();
void checkThresholds();
void triggerAlert();
void loadThresholds();
void saveThresholds();
uint32_t calculateChecksum(const SimpleThresholds& data);
unsigned long getUnixTime();
void buzzerBeep(int times);
 
 void setup() {
   Serial.begin(115200);
  delay(1000);
  Serial.println("ESP32 Air Quality Monitor - Simplified Version");
  
  // Initialize GPIO
  pinMode(LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);
  digitalWrite(LED, LOW);
  
  // Initialize EEPROM
  if (!EEPROM.begin(256)) {
    Serial.println("EEPROM initialization failed!");
    ESP.restart();
  }
  
  // Load thresholds from EEPROM
  loadThresholds();
  
  // Initialize OLED
  if (!oled.begin(i2c_Address, true)) {
    Serial.println("OLED initialization failed!");
  } else {
    Serial.println("OLED initialized successfully");
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SH110X_WHITE);
    oled.setCursor(0, 0);
    oled.println("Starting...");
    oled.display();
  }
  
  // Initialize sensors
  dht.begin();
  dustSensor.begin();
  
  // Get device ID
  String macAddress = WiFi.macAddress();
  macAddress.replace(":", "");
  deviceId = "ESP32-" + macAddress;
  Serial.println("Device ID: " + deviceId);
  
  // Initialize WiFi
  initWiFi();
  
  // Initialize time FIRST and wait for sync, then init Firebase
  if (WiFi.status() == WL_CONNECTED) {
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    ensureTimeSynced(15);
    initFirebase();
    setupFirebaseListeners();
  }
   
  Serial.println("Setup completed!");
  buzzerBeep(2);
   
  currentScreen = SCREEN_SENSOR_DATA;
 }
 
 void loop() {
  unsigned long currentTime = millis();
  
  // Read sensors every 3 seconds
  if (currentTime - lastSensorRead >= 3000) {
    lastSensorRead = currentTime;
    readSensors();
    checkThresholds();
  }
  
  // Update OLED every 1 second
  if (currentTime - lastScreenUpdate >= 1000) {
    lastScreenUpdate = currentTime;
    updateOLED();
  }
  
  // Send data to Firebase every 10 seconds
  if (currentTime - lastDataSend >= 10000) {
    lastDataSend = currentTime;
    if (firebaseConnected && WiFi.status() == WL_CONNECTED) {
      sendDataToFirebase();
    }
  }
  
  // Handle Firebase stream updates
  if (streamConnected) {
    handleFirebaseUpdates();
  }
  
  // Check WiFi connection periodically (every 30 seconds)
  static unsigned long lastWiFiCheck = 0;
  if (currentTime - lastWiFiCheck >= 30000) {
    lastWiFiCheck = currentTime;
    
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("⚠️ WiFi disconnected, attempting reconnection...");
      initWiFi();
   } else {
      // WiFi OK, in thông tin định kỳ
      static unsigned long lastWiFiInfo = 0;
      if (currentTime - lastWiFiInfo >= 300000) { // Mỗi 5 phút
        lastWiFiInfo = currentTime;
        Serial.printf("📶 WiFi OK - SSID: %s, IP: %s, RSSI: %d dBm\n", 
                      WiFi.SSID().c_str(), 
                      WiFi.localIP().toString().c_str(), 
                      WiFi.RSSI());
      }
    }
  }
  
  delay(100);
}

void initWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true);
  delay(1000);
  
  // Thử kết nối WiFi chính
  Serial.println("=== WIFI CONNECTION ATTEMPT ===");
  Serial.printf("Trying to connect to: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  Serial.print("Connecting to primary WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 15) {
    delay(1000);
    Serial.print(".");
    attempts++;
    
    // In thông tin debug
    if (attempts % 5 == 0) {
      Serial.printf("\nAttempt %d/15, Status: %d\n", attempts, WiFi.status());
      Serial.print("Continuing");
    }
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.println("✅ Primary WiFi connected!");
    Serial.printf("SSID: %s\n", WiFi.SSID().c_str());
    Serial.printf("IP: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("RSSI: %d dBm\n", WiFi.RSSI());
    currentScreen = SCREEN_WIFI_STATUS;
    return;
  }
  
  // WiFi connection failed
  Serial.println();
  Serial.println("❌ WiFi connection failed!");
  Serial.println("Please check:");
  Serial.printf("1. WiFi name: '%s' exists and in range\n", WIFI_SSID);
  Serial.printf("2. WiFi password: '%s' is correct\n", WIFI_PASSWORD);
  Serial.println("3. ESP32 is close enough to WiFi router");
  Serial.println("4. WiFi router is working properly");
  
  // Scan các WiFi có sẵn để debug
  scanAvailableWiFi();
}

void setupFirebaseListeners() {
  if (!firebaseConnected) {
    Serial.println("⚠️ Firebase not connected, cannot setup listeners");
    return;
  }
  
  Serial.println("🔗 Setting up Firebase stream listeners...");
  
  // Setup stream cho thresholds
  if (Firebase.ready() && Firebase.RTDB.beginStream(&streamData, "/air_monitor/thresholds")) {
    Firebase.RTDB.setStreamCallback(&streamData, onThresholdUpdate, onStreamTimeout);
    streamConnected = true;
    Serial.println("✅ Firebase stream connected to /air_monitor/thresholds");
     } else {
    Serial.println("❌ Failed to setup Firebase stream: " + streamData.errorReason());
    streamConnected = false;
  }
}

void handleFirebaseUpdates() {
  // Kiểm tra stream có sẵn không
  if (Firebase.ready() && !Firebase.RTDB.readStream(&streamData)) {
    Serial.println("⚠️ Stream read error: " + streamData.errorReason());
    
    // Thử kết nối lại stream nếu bị lỗi
    if (streamData.httpCode() <= 0) {
      Serial.println("🔄 Attempting to reconnect stream...");
      setupFirebaseListeners();
    }
  }
  
  // Dữ liệu sẽ được xử lý trong callback onThresholdUpdate()
}

void onThresholdUpdate(FirebaseStream data) {
  Serial.println("🔥 Firebase stream data received!");
  Serial.println("📍 Path: " + data.dataPath());
  Serial.println("📊 Data Type: " + data.dataType());
  Serial.println("🎯 Event Type: " + data.eventType());
  
  if (data.dataType() == "json") {
    FirebaseJson json = data.jsonObject();
    
    // Backup old values để so sánh
    SimpleThresholds oldThresholds = thresholds;
    bool changed = false;
    
    // Parse JSON data
    FirebaseJsonData jsonData;
    
    // Support BOTH flat keys and nested keys like temperature/min
    // Temperature
    if (json.get(jsonData, "tempMin") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.tempMin) { thresholds.tempMin = newValue; changed = true; Serial.printf("🌡️ Temp Min updated: %.1f°C\n", newValue); }
    }
    if (json.get(jsonData, "tempMax") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.tempMax) { thresholds.tempMax = newValue; changed = true; Serial.printf("🌡️ Temp Max updated: %.1f°C\n", newValue); }
    }
    if (json.get(jsonData, "temperature/min") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.tempMin) { thresholds.tempMin = newValue; changed = true; Serial.printf("🌡️ Temp Min (nested) → %.1f°C\n", newValue); }
    }
    if (json.get(jsonData, "temperature/max") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.tempMax) { thresholds.tempMax = newValue; changed = true; Serial.printf("🌡️ Temp Max (nested) → %.1f°C\n", newValue); }
    }
    
    // Humidity
    if (json.get(jsonData, "humMin") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.humMin) { thresholds.humMin = newValue; changed = true; Serial.printf("💧 Humi Min updated: %.1f%%\n", newValue); }
    }
    if (json.get(jsonData, "humMax") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.humMax) { thresholds.humMax = newValue; changed = true; Serial.printf("💧 Humi Max updated: %.1f%%\n", newValue); }
    }
    if (json.get(jsonData, "humidity/min") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.humMin) { thresholds.humMin = newValue; changed = true; Serial.printf("💧 Humi Min (nested) → %.1f%%\n", newValue); }
    }
    if (json.get(jsonData, "humidity/max") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.humMax) { thresholds.humMax = newValue; changed = true; Serial.printf("💧 Humi Max (nested) → %.1f%%\n", newValue); }
    }
    
    // PM2.5 (we only use max in this simplified model)
    if (json.get(jsonData, "pm25Max") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.pm25Max) { thresholds.pm25Max = newValue; changed = true; Serial.printf("🌪️ PM2.5 Max updated: %.1f μg/m³\n", newValue); }
    }
    if (json.get(jsonData, "pm25/max") && (jsonData.type == "float" || jsonData.type == "int")) {
      float newValue = jsonData.type == "float" ? jsonData.floatValue : (float)jsonData.intValue;
      if (newValue != thresholds.pm25Max) { thresholds.pm25Max = newValue; changed = true; Serial.printf("🌪️ PM2.5 Max (nested) → %.1f μg/m³\n", newValue); }
    }
    
    if (changed) {
      Serial.println("🎉 THRESHOLDS UPDATED FROM FIREBASE!");
      saveThresholds();
      displayThresholdChangeMessage();
      buzzerBeep(3);
      Serial.println("📋 New thresholds:");
      Serial.printf("   Temp: %.1f - %.1f°C\n", thresholds.tempMin, thresholds.tempMax);
      Serial.printf("   Humi: %.1f - %.1f%%\n", thresholds.humMin, thresholds.humMax);
      Serial.printf("   PM2.5: <%.1f μg/m³\n", thresholds.pm25Max);
    }
  }
  else if (data.dataType() == "float" || data.dataType() == "int") {
    // Xử lý trường hợp update từng field riêng lẻ
    String path = data.dataPath();
    float newValue = data.dataType() == "float" ? data.floatData() : (float)data.intData();
    
    bool changed = false;
    if (path.indexOf("tempMin") >= 0 && newValue != thresholds.tempMin) {
      thresholds.tempMin = newValue;
      changed = true;
      Serial.printf("🌡️ Temp Min updated: %.1f°C\n", newValue);
    }
    else if (path.indexOf("tempMax") >= 0 && newValue != thresholds.tempMax) {
      thresholds.tempMax = newValue;
      changed = true;
      Serial.printf("🌡️ Temp Max updated: %.1f°C\n", newValue);
    }
    else if (path.indexOf("humMin") >= 0 && newValue != thresholds.humMin) {
      thresholds.humMin = newValue;
      changed = true;
      Serial.printf("💧 Humidity Min updated: %.1f%%\n", newValue);
    }
    else if (path.indexOf("humMax") >= 0 && newValue != thresholds.humMax) {
      thresholds.humMax = newValue;
      changed = true;
      Serial.printf("💧 Humidity Max updated: %.1f%%\n", newValue);
    }
    else if (path.indexOf("pm25Max") >= 0 && newValue != thresholds.pm25Max) {
      thresholds.pm25Max = newValue;
      changed = true;
      Serial.printf("🌪️ PM2.5 Max updated: %.1f μg/m³\n", newValue);
    }
    // Nested single-field paths
    else if (path.indexOf("temperature") >= 0 && path.indexOf("min") >= 0 && newValue != thresholds.tempMin) {
      thresholds.tempMin = newValue; changed = true; Serial.printf("🌡️ Temp Min (nested) → %.1f°C\n", newValue);
    }
    else if (path.indexOf("temperature") >= 0 && path.indexOf("max") >= 0 && newValue != thresholds.tempMax) {
      thresholds.tempMax = newValue; changed = true; Serial.printf("🌡️ Temp Max (nested) → %.1f°C\n", newValue);
    }
    else if (path.indexOf("humidity") >= 0 && path.indexOf("min") >= 0 && newValue != thresholds.humMin) {
      thresholds.humMin = newValue; changed = true; Serial.printf("💧 Humi Min (nested) → %.1f%%\n", newValue);
    }
    else if (path.indexOf("humidity") >= 0 && path.indexOf("max") >= 0 && newValue != thresholds.humMax) {
      thresholds.humMax = newValue; changed = true; Serial.printf("💧 Humi Max (nested) → %.1f%%\n", newValue);
    }
    else if (path.indexOf("pm25") >= 0 && path.indexOf("max") >= 0 && newValue != thresholds.pm25Max) {
      thresholds.pm25Max = newValue; changed = true; Serial.printf("🌪️ PM2.5 Max (nested) → %.1f μg/m³\n", newValue);
    }
    
    if (changed) {
      Serial.println("🎉 THRESHOLD UPDATED FROM FIREBASE!");
      saveThresholds();
      displayThresholdChangeMessage();
      buzzerBeep(2);
    }
  }
}

void onStreamTimeout(bool timeout) {
  if (timeout) {
    Serial.println("⏰ Firebase stream timeout!");
    streamConnected = false;
    
    // Thử kết nối lại sau 5 giây
    delay(5000);
    if (firebaseConnected) {
      Serial.println("🔄 Reconnecting Firebase stream...");
      setupFirebaseListeners();
    }
  }
}

void displayThresholdChangeMessage() {
  // Hiển thị thông báo thay đổi ngưỡng trên OLED
  oled.clearDisplay();
  oled.setTextSize(1);
  oled.setTextColor(SH110X_WHITE);
  oled.setCursor(0, 0);
  
  oled.println("THRESHOLD UPDATED!");
  oled.println("================");
  oled.printf("Temp: %.1f-%.1f C\n", thresholds.tempMin, thresholds.tempMax);
  oled.printf("Humi: %.1f-%.1f%%\n", thresholds.humMin, thresholds.humMax);
  oled.printf("PM2.5: <%.1f ug/m3\n", thresholds.pm25Max);
  oled.println("");
  oled.println("Updated from");
  oled.println("Firebase!");
  
  oled.display();
  
  // Hiển thị trong 5 giây
  delay(5000);
}

void uploadCurrentThresholds() {
  if (!firebaseConnected) {
    Serial.println("⚠️ Cannot upload thresholds - Firebase not connected");
    return;
  }
  
  Serial.println("📤 Uploading current thresholds to Firebase...");
  
  FirebaseJson json;
  json.add("tempMin", thresholds.tempMin);
  json.add("tempMax", thresholds.tempMax);
  json.add("humMin", thresholds.humMin);
  json.add("humMax", thresholds.humMax);
  json.add("pm25Max", thresholds.pm25Max);
  json.add("lastUpdated", getUnixTime());
  json.add("updatedBy", "ESP32");
  
  if (Firebase.RTDB.setJSON(&fbdo, "/air_monitor/thresholds", &json)) {
    Serial.println("✅ Thresholds uploaded to Firebase successfully");
    Serial.println("📋 Current thresholds on Firebase:");
    Serial.printf("   Temp: %.1f - %.1f°C\n", thresholds.tempMin, thresholds.tempMax);
    Serial.printf("   Humi: %.1f - %.1f%%\n", thresholds.humMin, thresholds.humMax);
    Serial.printf("   PM2.5: <%.1f μg/m³\n", thresholds.pm25Max);
           } else {
    Serial.println("❌ Failed to upload thresholds: " + fbdo.errorReason());
  }
}

void scanAvailableWiFi() {
  Serial.println("🔍 Scanning available WiFi networks...");
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  
  int networks = WiFi.scanNetworks();
  if (networks == 0) {
    Serial.println("No WiFi networks found!");
       } else {
    Serial.printf("Found %d WiFi networks:\n", networks);
    Serial.println("---------------------------");
    for (int i = 0; i < networks; i++) {
      Serial.printf("%d. SSID: %-20s | RSSI: %3d dBm | %s\n", 
                    i + 1, 
                    WiFi.SSID(i).c_str(), 
                    WiFi.RSSI(i),
                    (WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "Open" : "Encrypted");
      
      // Kiểm tra xem WiFi target có trong danh sách không
      if (WiFi.SSID(i) == WIFI_SSID) {
        Serial.printf("   ✅ Found target WiFi: %s (Signal: %d dBm)\n", WIFI_SSID, WiFi.RSSI(i));
      }
    }
    Serial.println("---------------------------");
  }
  WiFi.scanDelete();
}

void initFirebase() {
  Serial.println("Initializing Firebase...");
  
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Increase timeouts for reliability
  config.timeout.serverResponse = 15000;
  config.timeout.rtdbKeepAlive = 45000;
  config.timeout.rtdbStreamReconnect = 2000;
  config.timeout.rtdbStreamError = 3000;
  
  // Anonymous sign-in
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase anonymous sign-in OK");
  } else {
    Serial.printf("Firebase signUp failed: %s\n", config.signer.signupError.message.c_str());
  }
  
   Firebase.begin(&config, &auth);
   Firebase.reconnectWiFi(true);
  
  // Wait for Firebase to become ready
  int readyWait = 0;
  while (!Firebase.ready() && readyWait < 20) {
    delay(250);
    readyWait++;
  }
   
  // Test connection
  if (Firebase.ready() && Firebase.RTDB.setBool(&fbdo, "/air_monitor/status/is_online", true)) {
    Serial.println("Firebase connected successfully!");
    firebaseConnected = true;
    currentScreen = SCREEN_FIREBASE_STATUS;
    
    // Upload thresholds hiện tại lên Firebase
    uploadCurrentThresholds();
  } else {
    Serial.printf("Firebase connection failed: %s\n", fbdo.errorReason().c_str());
    firebaseConnected = false;
  }
}
 
void readSensors() {
  // Read DHT11
  int humi = dht.readHumidity();
  float temp = dht.readTemperature();
  
  if (isnan(humi) || isnan(temp)) {
    Serial.println("Failed to read from DHT sensor!");
    dht11ReadOK = false;
  } else if (humi <= 100 && temp < 100) {
    dht11ReadOK = true;
    humiValue = humi;
    tempValue = temp;
    
    Serial.printf("Temperature: %.1f°C, Humidity: %d%%\n", tempValue, humiValue);
  }
  
  // Read dust sensor
  int dustReading = dustSensor.read();
  dustReading = constrain(dustReading, 0, 500);
  dustValue = dustReading;
  
  Serial.printf("PM2.5: %d μg/m³\n", dustValue);
}

void updateOLED() {
  oled.clearDisplay();
  oled.setTextSize(1);
  oled.setTextColor(SH110X_WHITE);
  oled.setCursor(0, 0);
  
  switch (currentScreen) {
    case SCREEN_INIT:
      oled.println("Initializing...");
      break;
      
    case SCREEN_WIFI_STATUS:
      oled.println("WiFi Status:");
      if (WiFi.status() == WL_CONNECTED) {
        oled.println("Connected");
        oled.printf("SSID: %s\n", WiFi.SSID().c_str());
        oled.printf("IP: %s\n", WiFi.localIP().toString().c_str());
        oled.printf("RSSI: %d dBm\n", WiFi.RSSI());
      } else {
        oled.println("Disconnected");
        oled.println("Check WiFi:");
        oled.printf("'%s'\n", WIFI_SSID);
        oled.println("Password OK?");
      }
      break;
      
    case SCREEN_FIREBASE_STATUS:
      oled.println("Firebase Status:");
      if (firebaseConnected) {
        oled.println("Connected");
        if (streamConnected) {
          oled.println("Stream: Active");
          oled.println("Listening for");
          oled.println("threshold updates");
        } else {
          oled.println("Stream: Inactive");
        }
      } else {
        oled.println("Disconnected");
      }
      break;
      
    case SCREEN_SENSOR_DATA:
    default:
      oled.println("Air Quality Monitor");
      oled.println("==================");
      oled.printf("Temp: %.1f C\n", tempValue);
      oled.printf("Humidity: %d%%\n", humiValue);
      oled.printf("PM2.5: %d ug/m3\n", dustValue);
      oled.println("");
      
      // Show WiFi status
      if (WiFi.status() == WL_CONNECTED) {
        oled.print("WiFi: OK ");
  } else {
        oled.print("WiFi: -- ");
      }
      
      // Show Firebase status
      if (firebaseConnected) {
        oled.println("FB: OK");
   } else {
        oled.println("FB: --");
      }
      
      // Show alert status
      if (alertActive) {
        oled.println("ALERT ACTIVE!");
      }
      break;
  }
  
  oled.display();
  
  // Auto-rotate screens
  static unsigned long lastScreenChange = 0;
  if (millis() - lastScreenChange > 5000) {
    lastScreenChange = millis();
    if (currentScreen == SCREEN_SENSOR_DATA) {
      currentScreen = SCREEN_WIFI_STATUS;
    } else if (currentScreen == SCREEN_WIFI_STATUS) {
      currentScreen = SCREEN_FIREBASE_STATUS;
    } else {
      currentScreen = SCREEN_SENSOR_DATA;
    }
  }
}

void sendDataToFirebase() {
  if (!firebaseConnected || !dht11ReadOK) {
    return;
  }
  
  Serial.println("Sending data to Firebase...");
  
  FirebaseJson json;
  json.add("temperature", tempValue);
  json.add("humidity", humiValue);
  json.add("pm25", dustValue);
  json.add("timestamp", getUnixTime());
  json.add("device_id", deviceId);
  
  if (Firebase.RTDB.setJSON(&fbdo, "/air_monitor/latest_data", &json)) {
    Serial.println("Data sent successfully");
    digitalWrite(LED, HIGH);
    delay(100);
    digitalWrite(LED, LOW);
      } else {
    Serial.println("Failed to send data: " + fbdo.errorReason());
  }
  
  // Update device status
  FirebaseJson statusJson;
  statusJson.add("is_online", true);
  statusJson.add("last_seen", getUnixTime());
  statusJson.add("device_id", deviceId);
  statusJson.add("free_heap", ESP.getFreeHeap());
  
  Firebase.RTDB.setJSON(&fbdo, "/air_monitor/status", &statusJson);
 }
 
void checkThresholds() {
  bool shouldAlert = false;
  String alertReason = "";
  
  // Check temperature
  if (tempValue < thresholds.tempMin || tempValue > thresholds.tempMax) {
    shouldAlert = true;
    alertReason += "Temperature: " + String(tempValue) + "°C ";
  }
  
  // Check humidity
  if (humiValue < thresholds.humMin || humiValue > thresholds.humMax) {
    shouldAlert = true;
    alertReason += "Humidity: " + String(humiValue) + "% ";
  }
  
  // Check PM2.5
  if (dustValue > thresholds.pm25Max) {
    shouldAlert = true;
    alertReason += "PM2.5: " + String(dustValue) + " μg/m³ ";
  }
  
  // Trigger alert if needed (max once every 30 seconds)
  if (shouldAlert && millis() - lastAlertTime > 30000) {
    Serial.println("THRESHOLD ALERT: " + alertReason);
    triggerAlert();
    lastAlertTime = millis();
    
    // Send alert to Firebase
    if (firebaseConnected) {
  FirebaseJson alertJson;
      alertJson.add("active", true);
      alertJson.add("reason", alertReason);
      alertJson.add("timestamp", getUnixTime());
      Firebase.RTDB.setJSON(&fbdo, "/air_monitor/alert", &alertJson);
    }
  } else if (!shouldAlert && alertActive) {
    // Clear alert
    alertActive = false;
    if (firebaseConnected) {
      FirebaseJson alertJson;
      alertJson.add("active", false);
      alertJson.add("reason", "");
      alertJson.add("timestamp", getUnixTime());
      Firebase.RTDB.setJSON(&fbdo, "/air_monitor/alert", &alertJson);
    }
  }
}

void triggerAlert() {
  alertActive = true;
  Serial.println("TRIGGERING ALERT!");
  
  // Beep pattern: 3 sequences of 3 beeps
  for (int seq = 0; seq < 3; seq++) {
    for (int i = 0; i < 3; i++) {
      digitalWrite(BUZZER, HIGH);
      delay(200);
      digitalWrite(BUZZER, LOW);
      delay(100);
    }
    delay(500);
  }
}

void loadThresholds() {
  SimpleThresholds tempThresholds;
  EEPROM.get(0, tempThresholds);
  
  // Verify checksum
  uint32_t calculatedChecksum = calculateChecksum(tempThresholds);
  if (tempThresholds.checksum == calculatedChecksum) {
    thresholds = tempThresholds;
    Serial.println("Thresholds loaded from EEPROM");
    } else {
    // Use defaults
    Serial.println("Using default thresholds");
    saveThresholds();
  }
  
  Serial.printf("Thresholds - Temp: %.1f-%.1f°C, Hum: %.1f-%.1f%%, PM2.5: <%.1f μg/m³\n",
                thresholds.tempMin, thresholds.tempMax, 
                thresholds.humMin, thresholds.humMax, 
                thresholds.pm25Max);
}

void saveThresholds() {
  thresholds.checksum = calculateChecksum(thresholds);
  EEPROM.put(0, thresholds);
  EEPROM.commit();
  Serial.println("Thresholds saved to EEPROM");
}

uint32_t calculateChecksum(const SimpleThresholds& data) {
  uint32_t checksum = 0;
  const uint8_t* bytes = (const uint8_t*)&data;
  size_t dataSize = sizeof(SimpleThresholds) - sizeof(uint32_t);
  
  for (size_t i = 0; i < dataSize; i++) {
    checksum += bytes[i];
  }
  return checksum;
}

unsigned long getUnixTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    return millis() + 1704067200000UL; // Fallback timestamp
  }
  time_t now = mktime(&timeinfo);
  return (unsigned long)now * 1000;
}

bool ensureTimeSynced(uint8_t maxRetries) {
  struct tm timeinfo;
  uint8_t tries = 0;
  while (!getLocalTime(&timeinfo) && tries < maxRetries) {
    Serial.println("⏳ Waiting for NTP time sync...");
    delay(500);
    tries++;
  }
  if (tries >= maxRetries) {
    Serial.println("⚠️ NTP sync failed, continuing with fallback time");
    return false;
  }
  Serial.println("✅ NTP time synced");
  return true;
}

void buzzerBeep(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER, HIGH);
    delay(100);
    digitalWrite(BUZZER, LOW);
    delay(100);
  }
}
