// Firebase ESP32 Configuration
#define FIREBASE_HOST "iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "AIzaSyDntHJ1ncMgoyVr39BrFA3T2xtrvz5ZD7g"

// Import required libraries
#include <WiFi.h>
#include <WiFiClient.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <FirebaseESP32.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <SimpleKalmanFilter.h>
#include <DNSServer.h>
#include "index_html.h"
#include "data_config.h"
#include <EEPROM.h>
#include <Arduino_JSON.h>
#include "icon.h"

// Create AsyncWebServer object on port 80
AsyncWebServer server(80);

// Create DNS Server for Captive Portal
DNSServer dnsServer;

//----------------------- Khai báo Firebase -----------------------
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;
bool firebaseReady = false;
String deviceId = "";
String userUID = "";
String userKey = "";
unsigned long lastSensorUpdate = 0;
unsigned long lastCommandCheck = 0; 

//----------------------- Khai báo Setup Mode -----------------------
bool setupMode = false;
String setupAPSSID = "";
const char* setupAPPassword = "12345678";
const String captivePortalURL = "http://192.168.4.1"; 
// Một số Macro
#define ENABLE    1
#define DISABLE   0
// ---------------------- Khai báo cho OLED 1.3 --------------------------
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

#define i2c_Address 0x3C //initialize with the I2C addr 0x3C Typically eBay OLED's
//#define i2c_Address 0x3d //initialize with the I2C addr 0x3D Typically Adafruit OLED's
#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels
#define OLED_RESET -1   //   QT-PY / XIAO
Adafruit_SH1106G oled = Adafruit_SH1106G(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define NUMFLAKES 10
#define XPOS 0
#define YPOS 1
#define DELTAY 2

#define OLED_SDA      21
#define OLED_SCL      22

typedef enum {
  SCREEN0,
  SCREEN1,
  SCREEN2,
  SCREEN3,
  SCREEN4,
  SCREEN5,
  SCREEN6,
  SCREEN7,
  SCREEN8,
  SCREEN9,
  SCREEN10,
  SCREEN11,
  SCREEN12,
  SCREEN13
}SCREEN;
int screenOLED = SCREEN0;

bool enableShow = DISABLE;

#define SAD    0
#define NORMAL 1
#define HAPPY  2
int warningTempState = SAD;
int warningHumiState = NORMAL;
int warningDustState = HAPPY;


bool autoWarning = DISABLE;
// --------------------- Cảm biến DHT11 ---------------------
#include "DHT.h"
#define DHT11_PIN         26
#define DHTTYPE DHT11
DHT dht(DHT11_PIN, DHTTYPE);
float tempValue = 30;
int humiValue   = 60;
SimpleKalmanFilter tempfilter(2, 2, 0.1);
SimpleKalmanFilter humifilter(2, 2, 0.1);
bool dht11ReadOK = true;
// -------------------- Khai báo cảm biến bụi --------------
#include <GP2Y1010AU0F.h>
#define DUST_TRIG             23
#define DUST_ANALOG           36
GP2Y1010AU0F dustSensor(DUST_TRIG, DUST_ANALOG);
SimpleKalmanFilter dustfilter(2, 2, 1);
int dustValue = 10;
int dustValueMax = 0;
// Khai bao LED
#define LED           33
// Khai báo BUZZER
#define BUZZER        2
uint32_t timeCountBuzzerWarning = 0;
#define TIME_BUZZER_WARNING     300  //thời gian cảnh báo bằng còi (đơn vị giây)
//-------------------- Khai báo Button-----------------------
#include "mybutton.h"
#define BUTTON_DOWN_PIN   34
#define BUTTON_UP_PIN     35
#define BUTTON_SET_PIN    32

#define BUTTON1_ID  1
#define BUTTON2_ID  2
#define BUTTON3_ID  3
Button buttonSET;
Button buttonDOWN;
Button buttonUP;
void button_press_short_callback(uint8_t button_id);
void button_press_long_callback(uint8_t button_id);
//------------------------------------------------------------
TaskHandle_t TaskButton_handle      = NULL;
TaskHandle_t TaskOLEDDisplay_handle = NULL;
TaskHandle_t TaskDHT11_handle = NULL;
TaskHandle_t TaskDustSensor_handle = NULL;
TaskHandle_t TaskAutoWarning_handle = NULL;
void setup(){
  Serial.begin(115200);
  // Đọc data setup từ eeprom
  EEPROM.begin(1024);  // Increased for larger address space
  readEEPROM();
    // Khởi tạo LED
  pinMode(LED, OUTPUT);
  // Khởi tạo BUZZER
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, DISABLE);
  // Khởi tạo OLED
  oled.begin(i2c_Address, true);
  oled.setTextSize(2);
  oled.setTextColor(SH110X_WHITE);
  // Khởi tạo DHT11
  dht.begin();
  // Khai báo cảm biến bụi
  dustSensor.begin();
    // ---------- Đọc giá trị AutoWarning trong EEPROM ----------------
  autoWarning = EEPROM.read(210);

  // Khởi tạo nút nhấn
  pinMode(BUTTON_SET_PIN, INPUT_PULLUP);
  pinMode(BUTTON_UP_PIN, INPUT_PULLUP);
  pinMode(BUTTON_DOWN_PIN, INPUT_PULLUP);
  button_init(&buttonSET, BUTTON_SET_PIN, BUTTON1_ID);
  button_init(&buttonUP, BUTTON_UP_PIN, BUTTON2_ID);
  button_init(&buttonDOWN,   BUTTON_DOWN_PIN,   BUTTON3_ID);
  button_pressshort_set_callback((void *)button_press_short_callback);
  button_presslong_set_callback((void *)button_press_long_callback);

  xTaskCreatePinnedToCore(TaskButton,          "TaskButton" ,          1024*10 ,  NULL,  20 ,  &TaskButton_handle       , 1);
  xTaskCreatePinnedToCore(TaskOLEDDisplay,     "TaskOLEDDisplay" ,     1024*16 ,  NULL,  20 ,  &TaskOLEDDisplay_handle  , 1);
  xTaskCreatePinnedToCore(TaskDHT11,           "TaskDHT11" ,           1024*10 ,  NULL,  10 ,  &TaskDHT11_handle  , 1);
  xTaskCreatePinnedToCore(TaskDustSensor,      "TaskDustSensor" ,      1024*10 ,  NULL,  10 ,  &TaskDustSensor_handle  , 1);
  xTaskCreatePinnedToCore(TaskAutoWarning,     "TaskAutoWarning" ,     1024*10 ,  NULL,  10  , &TaskAutoWarning_handle ,  1);

  // Generate device ID
  deviceId = WiFi.macAddress();
  deviceId.replace(":", "");
  deviceId = "ESP32-" + deviceId;
  
  // Generate setup AP SSID
  setupAPSSID = "ESP32-Setup-" + deviceId.substring(6); // Last 6 chars
  
  // Check if we need to enter setup mode with enhanced validation
  Serial.println("╔══════════════════════════════════════╗");
  Serial.println("║       WiFi CONFIGURATION CHECK      ║");
  Serial.println("╚══════════════════════════════════════╝");
  Serial.println("📋 ESSID from EEPROM: '" + Essid + "'");
  Serial.println("📏 ESSID Length: " + String(Essid.length()));
  Serial.println("📋 Password Length: " + String(Epass.length()));
  Serial.println("🔥 Firebase Host: " + String(EfirebaseHost.length() > 0 ? "✅ Present" : "❌ Missing"));
  Serial.println("🗝️  Firebase Auth: " + String(EfirebaseAuth.length() > 0 ? "✅ Present" : "❌ Missing"));
  Serial.println("👤 UserUID: " + String(EuserUID.length() > 0 ? "✅ Present" : "❌ Missing"));
  Serial.println("🔑 UserKey: " + String(EuserKey.length() > 0 ? "✅ Present" : "❌ Missing"));
  
  // Enhanced validation - check all required fields
  bool validWiFiConfig = (Essid.length() > 0 && 
                         Essid != "BLK" && 
                         Essid != "" && 
                         Epass.length() > 0);
                         
  bool validFirebaseConfig = (EfirebaseHost.length() > 0 && 
                             EfirebaseAuth.length() > 0 && 
                             EuserUID.length() > 0 && 
                             EuserKey.length() > 0);
  
  if (!validWiFiConfig) {
    Serial.println("🔧 ENTERING SETUP MODE - WiFi configuration invalid!");
    Serial.println("   Reason: " + String(Essid.length() == 0 ? "Empty SSID" : 
                                        Essid == "BLK" ? "Default SSID" : 
                                        Epass.length() == 0 ? "Empty Password" : "Unknown"));
    setupMode = true;
    startSetupMode();
  } else if (!validFirebaseConfig) {
    Serial.println("🔧 ENTERING SETUP MODE - Firebase configuration incomplete!");
    Serial.println("   Missing: " + 
                  String(EfirebaseHost.length() == 0 ? "Host " : "") +
                  String(EfirebaseAuth.length() == 0 ? "Auth " : "") +
                  String(EuserUID.length() == 0 ? "UID " : "") +
                  String(EuserKey.length() == 0 ? "Key " : ""));
    setupMode = true;
    startSetupMode();
  } else {
    Serial.println("✅ Configuration appears valid, attempting connection...");
    Serial.println("📡 CONNECTING TO STORED WiFi: " + Essid);
    setupMode = false;
    connectSTA();  // connectSTA() handles Firebase connection internally
  }

}

void loop() {
  vTaskDelete(NULL);
}

//--------------------Task đo DHT11 ---------------
void TaskDHT11(void *pvParameters) { 
    //delay(10000);
    while(1) {
      int humi =  dht.readHumidity();
      float temp =  dht.readTemperature();
      if (isnan(humi) || isnan(temp) ) {
          Serial.println(F("Failed to read from DHT sensor!"));
          dht11ReadOK = false;
      }
      else if(humi <= 100 && temp < 100) {
          dht11ReadOK = true;
          // humiValue = humifilter.updateEstimate(humi);
          // tempValue = tempfilter.updateEstimate(temp);
          humiValue = humi;
          tempValue = temp;

          Serial.print(F("Humidity: "));
          Serial.print(humiValue);
          Serial.print(F("%  Temperature: "));
          Serial.print(tempValue);
          Serial.print(F("°C "));
          Serial.println();

          if(tempValue < EtempThreshold1 || tempValue > EtempThreshold2) 
            warningTempState = NORMAL;
          else
            warningTempState = HAPPY;
          if(humiValue < EhumiThreshold1 || humiValue > EhumiThreshold2) 
            warningHumiState = NORMAL;
          else
            warningHumiState = HAPPY;
      }
      delay(3000);
    }
}
int countDust = 0;
//---------------- Task đo cảm biến bụi ----------
void TaskDustSensor(void *pvParameters) {
    while(1) {
        countDust++;
        if (countDust > 30) {
            countDust = 0;
            dustValueMax = 0;
        }

        int dustValueTemp = dustSensor.read();
        dustValueTemp = constrain(dustValueTemp, 0, 500);  // Giới hạn giá trị

        // Cập nhật giá trị bụi
        dustValueMax = max(dustValueMax, dustValueTemp);
        dustValue = dustValueMax;  // Hoặc có thể sử dụng bộ lọc Kalman

        Serial.print("Dust Density = ");
        Serial.print(dustValue);
        Serial.println(" ug/m3");

        // Cập nhật trạng thái cảnh báo
        if (dustValue <= EdustThreshold1)
            warningDustState = HAPPY;
        else if (dustValue > EdustThreshold1 && dustValue < EdustThreshold2)
            warningDustState = NORMAL;
        else
            warningDustState = SAD;

        vTaskDelay(pdMS_TO_TICKS(200));  // Thay vì delay(200)
    }
}

// Xóa 1 ô hình chữ nhật từ tọa độ (x1,y1) đến (x2,y2)
void clearRectangle(int x1, int y1, int x2, int y2) {
   for(int i = y1; i < y2; i++) {
     oled.drawLine(x1, i, x2, i, 0);
   }
}

void clearOLED(){
  oled.clearDisplay();
  oled.display();
}

int countSCREEN9 = 0;
// Task hiển thị OLED
void TaskOLEDDisplay(void *pvParameters) {
  while (1) {
      switch(screenOLED) {
        case SCREEN0: // Hiệu ứng khởi động
          for(int j = 0; j < 3; j++) {
            for(int i = 0; i < FRAME_COUNT_loadingOLED; i++) {
              oled.clearDisplay();
              oled.drawBitmap(32, 0, loadingOLED[i], FRAME_WIDTH_64, FRAME_HEIGHT_64, 1);
              oled.display();
              delay(FRAME_DELAY/4);
            }
          }
          screenOLED = SCREEN4;
          break;
        case SCREEN1:   // Hiển thị nhiệt độ 
          for(int j = 0; j < 2 && enableShow == ENABLE; j++) {

            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(0, 20);
            oled.print("Nhiet do : ");
            oled.setTextSize(2);
            oled.setCursor(0, 32);
            //if(dht11ReadOK == true)
              oled.print(tempValue,1); 
            //else
            //  oled.print("NaN"); 
            oled.drawCircle(54, 32, 3,SH110X_WHITE); 
            oled.print(" C"); 
          
            for(int i = 0; i < FRAME_COUNT_face1OLED && enableShow == ENABLE; i++) {
                  clearRectangle(96, 0, 128, 64);
                  if(warningTempState == SAD)
                    oled.drawBitmap(96, 20, face1OLED[i], 32, 32, 1);
                  else if(warningTempState == NORMAL)
                    oled.drawBitmap(96, 20, face2OLED[i], 32, 32, 1);
                  else if(warningTempState == HAPPY)
                    oled.drawBitmap(96, 20, face3OLED[i], 32, 32, 1);
                  oled.display();
                  delay(FRAME_DELAY);
            }
            oled.display();
            delay(100);
          }
          if( enableShow == ENABLE)
            screenOLED = SCREEN2;
          break;
        case SCREEN2:   // Hiển thị độ ẩm
          for(int j = 0; j < 2 && enableShow == ENABLE; j++) {
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(0, 20);
            oled.print("Do am khong khi: ");
            oled.setTextSize(2);
            oled.setCursor(0, 32);
            //if(dht11ReadOK == true)
              oled.print(humiValue); 
            //else
            //  oled.print("NaN");
            oled.print(" %"); 
 
            for(int i = 0; i < FRAME_COUNT_face1OLED && enableShow == ENABLE; i++) {
                  clearRectangle(96, 0, 128, 64);
                  if(warningHumiState == SAD)
                    oled.drawBitmap(96, 20, face1OLED[i], 32, 32, 1);
                  else if(warningHumiState == NORMAL)
                    oled.drawBitmap(96, 20, face2OLED[i], 32, 32, 1);
                  else if(warningHumiState == HAPPY)
                    oled.drawBitmap(96, 20, face3OLED[i], 32, 32, 1);
                  oled.display();
                  delay(FRAME_DELAY);
            }
            oled.display();
            delay(100);
          }
          if( enableShow == ENABLE)
            screenOLED = SCREEN3;
          break;
        case SCREEN3:  // Hiển thị Bụi
          for(int j = 0; j < 2 && enableShow == ENABLE; j++) {
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(0, 20);
            oled.print("Bui min PM2.5: ");
            oled.setTextSize(2);
            oled.setCursor(0, 32);
            oled.print(dustValue); 
            oled.setTextSize(1);
            oled.print(" ug/m3");  
            for(int i = 0; i < FRAME_COUNT_face1OLED && enableShow == ENABLE; i++) {
              clearRectangle(96, 0, 128, 64);
              if(warningDustState == SAD)
                oled.drawBitmap(96, 20, face1OLED[i], 32, 32, 1);
              else if(warningDustState == NORMAL)
                oled.drawBitmap(96, 20, face2OLED[i], 32, 32, 1);
              else if(warningDustState == HAPPY)
                oled.drawBitmap(96, 20, face3OLED[i], 32, 32, 1);
              oled.display();
              delay(FRAME_DELAY);  
            }
            oled.display();
            delay(100);
          }
          if( enableShow == ENABLE)
            screenOLED = SCREEN1;
          break; 
        case SCREEN4:    // Đang kết nối Wifi
          oled.clearDisplay();
          oled.setTextSize(1);
          oled.setCursor(40, 5);
          oled.print("WIFI");
          oled.setTextSize(1.5);
          oled.setCursor(40, 17);
          oled.print("Dang ket noi..");
      
          for(int i = 0; i < FRAME_COUNT_wifiOLED; i++) {
            clearRectangle(0, 0, 32, 32);
            oled.drawBitmap(0, 0, wifiOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
            oled.display();
            delay(FRAME_DELAY);
          }
          break;
        case SCREEN5:    // Kết nối wifi thất bại
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 5);
            oled.print("WIFI");
            oled.setTextSize(1.5);
            oled.setCursor(40, 17);
            oled.print("Mat ket noi.");
            oled.drawBitmap(0, 0, wifiOLED[FRAME_COUNT_wifiOLED - 1 ], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
            oled.drawLine(31, 0 , 0, 31 , 1);
            oled.drawLine(32, 0 , 0, 32 , 1);
            oled.display();
            delay(2000);
            screenOLED = SCREEN9;
          break;
        case SCREEN6:   // Đã kết nối Wifi, đang kết nối Firebase
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 5);
            oled.print("WIFI");
            oled.setTextSize(1.5);
            oled.setCursor(40, 17);
            oled.print("Da ket noi.");
            oled.drawBitmap(0, 0, wifiOLED[FRAME_COUNT_wifiOLED - 1 ], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);

            oled.setTextSize(1);
            oled.setCursor(40, 34);
            oled.print("FIREBASE");
            oled.setTextSize(1.5);
            oled.setCursor(40, 51);
            oled.print("Dang ket noi..");
                        

            for(int i = 0; i < FRAME_COUNT_blynkOLED; i++) {
              clearRectangle(0, 32, 32, 64);
              oled.drawBitmap(0, 32, blynkOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
              oled.display();
              delay(FRAME_DELAY);
            }

          break;
        case SCREEN7:   // Đã kết nối Wifi, Đã kết nối Firebase
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 5);
            oled.print("WIFI");
            oled.setTextSize(1.5);
            oled.setCursor(40, 17);
            oled.print("Da ket noi.");
            oled.drawBitmap(0, 0, wifiOLED[FRAME_COUNT_wifiOLED - 1 ], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);

            oled.setTextSize(1);
            oled.setCursor(40, 34);
            oled.print("FIREBASE");
            oled.setTextSize(1.5);
            oled.setCursor(40, 51);
            oled.print("Da ket noi.");
            oled.drawBitmap(0, 32, blynkOLED[FRAME_COUNT_wifiOLED/2], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
            oled.display();
            delay(2000);
            screenOLED = SCREEN3;
            enableShow = ENABLE;
          break;
        case SCREEN8:   // Đã kết nối Wifi, Mat kết nối Firebase
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 5);
            oled.print("WIFI");
            oled.setTextSize(1.5);
            oled.setCursor(40, 17);
            oled.print("Da ket noi.");
            oled.drawBitmap(0, 0, wifiOLED[FRAME_COUNT_wifiOLED - 1 ], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);

            oled.setTextSize(1);
            oled.setCursor(40, 34);
            oled.print("FIREBASE");
            oled.setTextSize(1.5);
            oled.setCursor(40, 51);
            oled.print("Mat ket noi.");
            oled.drawBitmap(0, 32, blynkOLED[FRAME_COUNT_wifiOLED/2], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
            oled.drawLine(31, 32 , 0, 63 , 1);
            oled.drawLine(32, 32 , 0, 64 , 1);
            oled.display();
            delay(2000);
            screenOLED = SCREEN9;
          break;
        case SCREEN9:   // Setup mode display - Enhanced version
            oled.clearDisplay();
            
            if (setupMode) {
                // Title with larger text
            oled.setTextSize(1);
                oled.setCursor(25, 0);
                oled.print("== SETUP ==");
                
                // WiFi Network Name (split into 2 lines if needed)
            oled.setTextSize(1);
                oled.setCursor(0, 12);
                oled.print("Network:");
                oled.setCursor(0, 22);
                if (setupAPSSID.length() > 21) {
                    oled.print(setupAPSSID.substring(0, 21));
                } else {
                    oled.print(setupAPSSID);
                }
                
                // Password - Larger and clearer
                oled.setCursor(0, 32);
                oled.print("Password:");
                oled.setTextSize(2);
                oled.setCursor(0, 42);
                oled.print(String(setupAPPassword));
                
                // IP Address
            oled.setTextSize(1);
                oled.setCursor(0, 58);
                oled.print("IP: 192.168.4.1");
                
            } else {
                // Normal mode - simpler display
                oled.setTextSize(1);
                oled.setCursor(0, 5);
                oled.print("Ket noi Wifi:");
                oled.setCursor(0, 17);
                oled.print("ESP32_IOT");
                oled.setCursor(0, 38);
            oled.print("Dia chi IP:");
                oled.setCursor(0, 50);
            oled.print("192.168.4.1");

                // Animation only in normal mode
            for(int i = 0; i < FRAME_COUNT_settingOLED; i++) {
              clearRectangle(0, 0, 32, 64);
              oled.drawBitmap(0, 16, settingOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
              oled.display();
              delay(FRAME_DELAY*2);
            }
            }
            
            // Display the content
            oled.display();
            
            // Only show animation when not in setup mode
            if (!setupMode) {
            countSCREEN9++;
            if(countSCREEN9 > 10) {
              countSCREEN9 = 0;
              screenOLED = SCREEN1;
              enableShow = ENABLE;
                }
            } else {
                // In setup mode, keep displaying this screen
                delay(1000); // Update every second
                countSCREEN9 = 0;
            }

            break;
          case SCREEN10:    // auto : on
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 20);
            oled.print("Canh bao:");
            oled.setTextSize(2);
            oled.setCursor(40, 32);
            oled.print("DISABLE"); 
            for(int i = 0; i < FRAME_COUNT_autoOnOLED; i++) {
              clearRectangle(0, 0, 32, 64);
              oled.drawBitmap(0, 16, autoOnOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
              oled.display();
              delay(FRAME_DELAY);
            }
            clearRectangle(40, 32, 128, 64);
            oled.setCursor(40, 32);
            oled.print("ENABLE"); 
            oled.display();   
            delay(2000);
            screenOLED = SCREEN1;
            enableShow = ENABLE;
            break;
          case SCREEN11:     // auto : off
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 20);
            oled.print("Canh bao:");
            oled.setTextSize(2);
            oled.setCursor(40, 32);
            oled.print("ENABLE");
            for(int i = 0; i < FRAME_COUNT_autoOffOLED; i++) {
              clearRectangle(0, 0, 32, 64);
              oled.drawBitmap(0, 16, autoOffOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
              oled.display();
              delay(FRAME_DELAY);
            }
            clearRectangle(40, 32, 128, 64);
            oled.setCursor(40, 32);
            oled.print("DISABLE"); 
            oled.display();    
            delay(2000);
            screenOLED = SCREEN1;  
            enableShow = ENABLE;
            break;
          case SCREEN12:  // gui du lieu len Firebase
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(40, 20);
            oled.print("Gui du lieu");
            oled.setCursor(40, 32);
            oled.print("den FIREBASE"); 
            for(int i = 0; i < FRAME_COUNT_sendDataOLED; i++) {
                clearRectangle(0, 0, 32, 64);
                oled.drawBitmap(0, 16, sendDataOLED[i], FRAME_WIDTH_32, FRAME_HEIGHT_32, 1);
                oled.display();
                delay(FRAME_DELAY);
            } 
            delay(1000);
            screenOLED = SCREEN1; 
            enableShow = ENABLE;
            break;
          case SCREEN13:   // khoi dong lai
            oled.clearDisplay();
            oled.setTextSize(1);
            oled.setCursor(0, 20);
            oled.print("Khoi dong lai");
            oled.setCursor(0, 32);
            oled.print("Vui long doi ..."); 
            oled.display();
            break;
          default : 
            delay(500);
            break;
      } 
      delay(10);
  }
}



//-----------------Kết nối STA wifi với retry logic ----------------------- 
void connectSTA() {
      delay(3000);  // Shorter initial delay
      enableShow = DISABLE;
      
      // Enhanced validation and logging
      Serial.println("╔══════════════════════════════════════╗");
      Serial.println("║           CONNECTING TO WiFi         ║");
      Serial.println("╚══════════════════════════════════════╝");
      
      if (Essid.length() <= 1) {
          Serial.println("❌ Invalid SSID length: " + String(Essid.length()));
          Serial.println("🔄 Entering setup mode due to invalid SSID");
          setupMode = true;
          startSetupMode();
          return;
      }
      
      Serial.println("📡 SSID: " + Essid);
      Serial.println("🔐 Password: [HIDDEN " + String(Epass.length()) + " chars]");
      Serial.println("🔥 Firebase Host: " + EfirebaseHost);
      Serial.println("🗝️  Firebase API Key: [HIDDEN " + String(EfirebaseAuth.length()) + " chars]");
      Serial.println("👤 UserUID: " + EuserUID.substring(0, 8) + "***");
      Serial.println("🔑 UserKey: " + EuserKey.substring(0, 8) + "***");
      
      // Try connecting with extended timeout and retry
      const int MAX_WIFI_RETRIES = 2;
      const int WIFI_TIMEOUT_SECONDS = 30; // Increased from 7.5s to 30s
      
      for (int retry = 1; retry <= MAX_WIFI_RETRIES; retry++) {
          Serial.println("🔄 WiFi connection attempt " + String(retry) + "/" + String(MAX_WIFI_RETRIES));
          
          WiFi.mode(WIFI_STA);
          WiFi.begin(Essid.c_str(), Epass.c_str());
          
      int countConnect = 0;
          const int maxCount = WIFI_TIMEOUT_SECONDS * 2; // 500ms intervals
          
          while (WiFi.status() != WL_CONNECTED && countConnect < maxCount) {
          delay(500);   
              countConnect++;
              
              // Show progress every 5 seconds
              if (countConnect % 10 == 0) {
                  Serial.println("⏳ Connecting... " + String(countConnect/2) + "s/" + String(WIFI_TIMEOUT_SECONDS) + "s");
              }
              
              // Update OLED display
          screenOLED = SCREEN4;
          }
          
          if (WiFi.status() == WL_CONNECTED) {
              Serial.println("✅ WiFi connected successfully!");
              Serial.println("📍 IP address: " + WiFi.localIP().toString());
              Serial.println("📶 Signal strength: " + String(WiFi.RSSI()) + " dBm");
              break;
          } else {
              Serial.println("❌ WiFi connection failed on attempt " + String(retry));
              Serial.println("📊 WiFi status: " + String(WiFi.status()));
              
              if (retry < MAX_WIFI_RETRIES) {
                  Serial.println("⏳ Waiting 5s before retry...");
                  delay(5000);
              }
          }
      }
      
      if (WiFi.status() == WL_CONNECTED) {
       // MODE wifi đã kết nối, đang kết nối Firebase
       screenOLED = SCREEN6;
       delay(2000);
       
          Serial.println("🔥 Attempting Firebase connection...");
          
          // Try Firebase with retry
          const int MAX_FIREBASE_RETRIES = 3;
          bool firebaseConnected = false;
          
          for (int fbRetry = 1; fbRetry <= MAX_FIREBASE_RETRIES; fbRetry++) {
              Serial.println("🔄 Firebase attempt " + String(fbRetry) + "/" + String(MAX_FIREBASE_RETRIES));
              
              if (connectFirebase()) {
                  firebaseConnected = true;
                  break;
              } else {
                  Serial.println("❌ Firebase connection failed on attempt " + String(fbRetry));
                  if (fbRetry < MAX_FIREBASE_RETRIES) {
                      Serial.println("⏳ Waiting 3s before Firebase retry...");
                      delay(3000);
                  }
              }
          }
          
          if (firebaseConnected) {
              Serial.println("✅ Firebase connected successfully!");
            enableShow = ENABLE;
            screenOLED = SCREEN7;
            delay(2000);
              
              xTaskCreatePinnedToCore(TaskFirebase, "TaskFirebase", 1024*16, NULL, 20, NULL, 1);
            buzzerBeep(5);  
              
              Serial.println("🎉 ESP32 fully operational!");
            return; 
          } else {
              Serial.println("❌ Firebase connection failed after " + String(MAX_FIREBASE_RETRIES) + " attempts");
            screenOLED = SCREEN8;
              delay(5000);
              
              // Instead of restart, enter setup mode
              Serial.println("🔄 Entering setup mode due to Firebase failure");
              setupMode = true;
              startSetupMode();
              return;
          }
      } else {
          Serial.println("❌ WiFi connection failed after " + String(MAX_WIFI_RETRIES) + " attempts");
          Serial.println("📊 Final WiFi status: " + String(WiFi.status()));
          
          // Show error on OLED and buzzer
          screenOLED = SCREEN5;
        digitalWrite(BUZZER, ENABLE);
        delay(2000);
        digitalWrite(BUZZER, DISABLE);
          delay(3000);
          
          // Enter setup mode instead of restart loop
          Serial.println("🔄 Entering setup mode due to WiFi failure");
          setupMode = true;
          startSetupMode();
          return;
      }
}


// Note: connectAPMode() removed - replaced by startSetupMode()

// Note: getDataFromClient() removed - handled in setupWebServerRoutes()

// ------------ Hàm in các giá trị cài đặt ------------
void printValueSetup() {
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║           EEPROM CONFIG DUMP           ║");
    Serial.println("╚════════════════════════════════════════╝");
    Serial.println("📡 SSID: '" + Essid + "' (len=" + String(Essid.length()) + ")");
    Serial.println("🔐 Password: '" + String(Epass.length() > 0 ? "[HIDDEN " + String(Epass.length()) + " chars]" : "[EMPTY]") + "'");
    Serial.println("🔥 Firebase Host: '" + EfirebaseHost + "' (len=" + String(EfirebaseHost.length()) + ")");
    Serial.println("🗝️  Firebase API Key: '" + String(EfirebaseAuth.length() > 0 ? "[HIDDEN " + String(EfirebaseAuth.length()) + " chars]" : "[EMPTY]") + "'");
    Serial.println("👤 UserUID: '" + String(EuserUID.length() > 0 ? EuserUID.substring(0, 8) + "***" : "[EMPTY]") + "' (len=" + String(EuserUID.length()) + ")");
    Serial.println("🔑 UserKey: '" + String(EuserKey.length() > 0 ? EuserKey.substring(0, 8) + "***" : "[EMPTY]") + "' (len=" + String(EuserKey.length()) + ")");
    Serial.println("🌡️  Temp Thresholds: " + String(EtempThreshold1) + "/" + String(EtempThreshold2));
    Serial.println("💧 Humidity Thresholds: " + String(EhumiThreshold1) + "/" + String(EhumiThreshold2));
    Serial.println("💨 Dust Thresholds: " + String(EdustThreshold1) + "/" + String(EdustThreshold2));
    Serial.println("⚠️  Auto Warning: " + String(autoWarning ? "ON" : "OFF"));
}



//-------- Hàm tạo biến JSON để gửi đi khi có request HTTP_GET "/" --------
String getJsonData() {
  JSONVar myObject;
  myObject["ssid"]  = Essid;
  myObject["pass"]  = Epass;
  myObject["firebaseHost"] = EfirebaseHost;
  myObject["firebaseAPIKey"] = EfirebaseAuth;
  myObject["userUID"] = EuserUID;
  myObject["userKey"] = EuserKey;
  myObject["tempThreshold1"] = EtempThreshold1;
  myObject["tempThreshold2"] = EtempThreshold2;
  myObject["humiThreshold1"] = EhumiThreshold1;
  myObject["humiThreshold2"] = EhumiThreshold2;
  myObject["dustThreshold1"] = EdustThreshold1;
  myObject["dustThreshold2"] = EdustThreshold2;

  String jsonData = JSON.stringify(myObject);
  return jsonData;
}

//-------------------------------------------------------------------------------
//--------------------------------Task Blynk-------------------------------------

//----------------------------- Task auto Warning--------------------------------
void TaskAutoWarning(void *pvParameters)  {
    delay(20000);
    while(1) {
      if(autoWarning == 1) {
          check_air_quality_and_send_to_firebase(ENABLE, tempValue, humiValue, dustValue);
      }
      delay(10000);
    }
}

//----------------------- Send Data to Firebase ------------------------
void sendDataToFirebase() {
    if (firebaseReady && deviceId.length() > 0) {
        unsigned long currentTime = millis();
        String timestamp = String(currentTime);
        
        // Send to latest data path (for real-time display)
        String latestPath = "/sensorData/" + deviceId + "/latest";
        FirebaseJson latestJson;
        latestJson.set("timestamp", timestamp);
        latestJson.set("deviceId", deviceId);
        latestJson.set("temperature", tempValue);
        latestJson.set("humidity", humiValue);
        latestJson.set("airQuality", dustValue);
        latestJson.set("status", "online");
        latestJson.set("lastUpdate", timestamp);
        
        if (Firebase.setJSON(firebaseData, latestPath.c_str(), latestJson)) {
            Serial.println("Latest data sent to Firebase successfully");
        } else {
            Serial.println("Failed to send latest data to Firebase");
            Serial.println(firebaseData.errorReason());
        }
        
        // Also send to historical data (optional, for charts)
        String historyPath = "/sensorData/" + deviceId + "/history/" + timestamp;
        FirebaseJson historyJson;
        historyJson.set("timestamp", timestamp);
        historyJson.set("temperature", tempValue);
        historyJson.set("humidity", humiValue);
        historyJson.set("airQuality", dustValue);
        
        Firebase.setJSON(firebaseData, historyPath.c_str(), historyJson);
        // Don't check result for history to avoid blocking
    }
}

//----------------------- Check Firebase Commands -----------------------
void checkFirebaseCommands() {
    if (firebaseReady && userUID.length() > 0 && deviceId.length() > 0) {
        String commandPath = "/users/" + userUID + "/devices/" + deviceId + "/commands";
        
        // Check individual commands
            // Check restart command
        if (Firebase.getBool(firebaseData, (commandPath + "/restart").c_str()) && firebaseData.boolData()) {
                ESP.restart();
            }
            
            // Check autoWarning setting
        if (Firebase.getBool(firebaseData, (commandPath + "/autoWarning").c_str())) {
            autoWarning = firebaseData.boolData() ? 1 : 0;
                EEPROM.write(210, autoWarning);
                EEPROM.commit();
                if(autoWarning == 0) screenOLED = SCREEN11;
                else screenOLED = SCREEN10;
                enableShow = DISABLE;
                buzzerBeep(1);
                
                // Clear the command
            Firebase.deleteNode(firebaseData, (commandPath + "/autoWarning").c_str());
            }
            
            // Check manual data request
        if (Firebase.getBool(firebaseData, (commandPath + "/requestData").c_str()) && firebaseData.boolData()) {
                buzzerBeep(1);
                check_air_quality_and_send_to_firebase(DISABLE, tempValue, humiValue, dustValue);
                screenOLED = SCREEN12;
                enableShow = DISABLE;
                
                // Clear the command
            Firebase.deleteNode(firebaseData, (commandPath + "/requestData").c_str());
        }
    }
}

//---------------------------Task Firebase---------------------------
void TaskFirebase(void *pvParameters) {
    while(1) {
        if (firebaseReady) {
            // Send sensor data every 30 seconds
            if (millis() - lastSensorUpdate > 30000) {
                sendDataToFirebase();
                lastSensorUpdate = millis();
            }
            
            // Check commands every 5 seconds
            if (millis() - lastCommandCheck > 5000) {
                checkFirebaseCommands();
                lastCommandCheck = millis();
            }
        }
        delay(1000);
    }
}

/*
 * Các hàm liên quan đến lưu dữ liệu cài đặt vào EEPROM
*/
//--------------------------- Read Eeprom  --------------------------------
void debugEEPROM() {
  Serial.println("🔍 Raw EEPROM dump (first 200 bytes):");
  for (int i = 0; i < 200; i++) {
    if (i % 16 == 0) Serial.printf("\n%03d: ", i);
    Serial.printf("%02X ", EEPROM.read(i));
  }
  Serial.println();
}

void readEEPROM() {
    Serial.println("📖 Reading EEPROM configuration...");
    
    // Debug raw EEPROM first
    debugEEPROM();
    
    // Clear all strings first
    Essid = "";
    Epass = "";
    EfirebaseHost = "";
    EfirebaseAuth = "";
    EuserUID = "";
    EuserKey = "";
    
    // IMPROVED ADDRESS SPACE ALLOCATION:
    // SSID: 0-31 (32 bytes)
    // Password: 32-95 (64 bytes) 
    // Firebase Host: 100-199 (100 bytes)
    // Firebase Auth: 200-399 (200 bytes) 
    // UserUID: 400-499 (100 bytes)
    // UserKey: 500-599 (100 bytes)
    
    // Read SSID (0-31)
    Serial.println("📋 Reading SSID...");
    for (int i = 0; i < 32; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            Essid += c;
        } else if (c == 0) {
            break; // Stop at null terminator
        }
    }
    
    // Read Password (32-95)
    Serial.println("📋 Reading Password...");
    for (int i = 32; i < 96; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            Epass += c;
        } else if (c == 0) {
            break;
        }
    }
    
    // Read Firebase Host (100-199)
    Serial.println("📋 Reading Firebase Host...");
    for (int i = 100; i < 200; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            EfirebaseHost += c;
        } else if (c == 0) {
            break;
        }
    }
    
    // Read Firebase Auth (200-399)
    Serial.println("📋 Reading Firebase Auth...");
    for (int i = 200; i < 400; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            EfirebaseAuth += c;
        } else if (c == 0) {
            break;
        }
    }
    
    // Read User UID (400-499)
    Serial.println("📋 Reading UserUID...");
    for (int i = 400; i < 500; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            EuserUID += c;
        } else if (c == 0) {
            break;
        }
    }
    
    // Read User Key (500-599)
    Serial.println("📋 Reading UserKey...");
    for (int i = 500; i < 600; ++i) {
        char c = EEPROM.read(i);
        if (c != 0 && c != 255 && isPrintable(c)) {
            EuserKey += c;
        } else if (c == 0) {
            break;
        }
    }
    
    // Enhanced validation
    if (Essid.length() == 0 || 
        Essid == "BLK" || 
        Essid.indexOf("ÿ") >= 0 || 
        Essid.indexOf("�") >= 0) {
        Serial.println("⚠️  Invalid SSID detected, clearing all config...");
        Essid = "";
        Epass = "";
        EfirebaseHost = "";
        EfirebaseAuth = "";
        EuserUID = "";
        EuserKey = "";
    }
    
    Serial.println("📊 EEPROM Read Results:");
    Serial.println("   📶 SSID: '" + Essid + "' (" + String(Essid.length()) + " chars)");
    Serial.println("   🔒 Pass: " + String(Epass.length()) + " chars");
    Serial.println("   🔥 Host: " + String(EfirebaseHost.length()) + " chars");
    Serial.println("   🗝️  Auth: " + String(EfirebaseAuth.length()) + " chars");
    Serial.println("   👤 UID:  " + String(EuserUID.length()) + " chars");
    Serial.println("   🔑 Key:  " + String(EuserKey.length()) + " chars");

    // Read thresholds from new addresses (600+)
    EtempThreshold1 = EEPROM.read(600);
    EtempThreshold2 = EEPROM.read(601);

    EhumiThreshold1 = EEPROM.read(602);
    EhumiThreshold2 = EEPROM.read(603);

    EdustThreshold1 = EEPROM.read(604) * 100 + EEPROM.read(605);
    EdustThreshold2 = EEPROM.read(606) * 100 + EEPROM.read(607);  

    autoWarning     = EEPROM.read(610);

    printValueSetup();
}

// ------------------------ Clear Eeprom ------------------------

void clearEeprom() {
    Serial.println("🧹 Clearing EEPROM (first 700 bytes)...");
    for (int i = 0; i < 700; ++i) 
      EEPROM.write(i, 0);
    EEPROM.commit();
    Serial.println("✅ EEPROM cleared");
}

// -------------------- Hàm ghi data vào EEPROM ------------------
void writeEEPROM() {
    Serial.println("💾 Writing EEPROM configuration...");
    
    // Clear first to ensure clean state
    clearEeprom();
    
    // Write using NEW ADDRESS SPACE ALLOCATION:
    // SSID: 0-31 (32 bytes)
    // Password: 32-95 (64 bytes) 
    // Firebase Host: 100-199 (100 bytes)
    // Firebase Auth: 200-399 (200 bytes) 
    // UserUID: 400-499 (100 bytes)
    // UserKey: 500-599 (100 bytes)
    // Thresholds: 600+ (non-conflicting)
    
    // Write SSID (0-31)
    Serial.println("💾 Writing SSID...");
    for (int i = 0; i < Essid.length() && i < 32; ++i)
          EEPROM.write(i, Essid[i]);  
          
    // Write Password (32-95)
    Serial.println("💾 Writing Password...");
    for (int i = 0; i < Epass.length() && i < 64; ++i)
          EEPROM.write(32+i, Epass[i]);
          
    // Write Firebase Host (100-199)
    Serial.println("💾 Writing Firebase Host...");
    for (int i = 0; i < EfirebaseHost.length() && i < 100; ++i)
          EEPROM.write(100+i, EfirebaseHost[i]);
          
    // Write Firebase Auth (200-399)
    Serial.println("💾 Writing Firebase Auth...");
    for (int i = 0; i < EfirebaseAuth.length() && i < 200; ++i)
          EEPROM.write(200+i, EfirebaseAuth[i]);
          
    // Write UserUID (400-499)
    Serial.println("💾 Writing UserUID...");
    for (int i = 0; i < EuserUID.length() && i < 100; ++i)
          EEPROM.write(400+i, EuserUID[i]);
          
    // Write UserKey (500-599)
    Serial.println("💾 Writing UserKey...");
    for (int i = 0; i < EuserKey.length() && i < 100; ++i)
          EEPROM.write(500+i, EuserKey[i]);

    // Write thresholds at non-conflicting addresses (600+)
    EEPROM.write(600, EtempThreshold1);          // lưu ngưỡng nhiệt độ 1
    EEPROM.write(601, EtempThreshold2);          // lưu ngưỡng nhiệt độ 2

    EEPROM.write(602, EhumiThreshold1);          // lưu ngưỡng độ ẩm 1
    EEPROM.write(603, EhumiThreshold2);          // lưu ngưỡng độ ẩm 2

    EEPROM.write(604, EdustThreshold1 / 100);      // lưu hàng nghìn + trăm bụi 1
    EEPROM.write(605, EdustThreshold1 % 100);      // lưu hàng chục + đơn vị bụi 1

    EEPROM.write(606, EdustThreshold2 / 100);      // lưu hàng nghìn + trăm bụi 2
    EEPROM.write(607, EdustThreshold2 % 100);      // lưu hàng chục + đơn vị bụi 2
    
    EEPROM.write(610, autoWarning);              // auto warning status
    
    // CRITICAL: Commit to flash memory
    EEPROM.commit();

    Serial.println("✅ EEPROM write completed and committed");
    Serial.println("📊 Written lengths:");
    Serial.println("   📶 SSID: " + String(Essid.length()) + " chars");
    Serial.println("   🔒 Pass: " + String(Epass.length()) + " chars");  
    Serial.println("   🔥 Host: " + String(EfirebaseHost.length()) + " chars");
    Serial.println("   🗝️  Auth: " + String(EfirebaseAuth.length()) + " chars");
    Serial.println("   👤 UID:  " + String(EuserUID.length()) + " chars");
    Serial.println("   🔑 Key:  " + String(EuserKey.length()) + " chars");
    delay(500);
}


//-----------------------Task Task Button ----------
void TaskButton(void *pvParameters) {
    while(1) {
      handle_button(&buttonSET);
      handle_button(&buttonUP);
      handle_button(&buttonDOWN);
      delay(10);
    }
}
//-----------------Hàm xử lí nút nhấn nhả ----------------------
void button_press_short_callback(uint8_t button_id) {
    switch(button_id) {
      case BUTTON1_ID :  
        buzzerBeep(1);
        Serial.println("btSET press short");
        break;
      case BUTTON2_ID :
        buzzerBeep(1);
        Serial.println("btUP press short");
        break;
      case BUTTON3_ID :
        buzzerBeep(1);
        Serial.println("btDOWN press short");
        enableShow = DISABLE;
        check_air_quality_and_send_to_firebase(DISABLE, tempValue, humiValue, dustValue);
        screenOLED = SCREEN12;
        break;  
    } 
} 
//-----------------Hàm xử lí nút nhấn giữ ----------------------
void button_press_long_callback(uint8_t button_id) {
  switch(button_id) {
    case BUTTON1_ID :
      buzzerBeep(2);  
      enableShow = DISABLE;
      Serial.println("╔════════════════════════════════════════╗");
      Serial.println("║    RESET TO SETUP MODE REQUESTED      ║");
      Serial.println("║    Button 1 held - clearing WiFi      ║");
      Serial.println("╚════════════════════════════════════════╝");
      
      // Clear EEPROM WiFi config to force setup mode
      Serial.println("🗑️  Clearing stored WiFi configuration...");
      Essid = "";
      Epass = "";
      EuserKey = "";
      EfirebaseHost = "";
      EfirebaseAuth = "";
      EuserUID = "";
      writeEEPROM();
      Serial.println("✅ WiFi configuration cleared from EEPROM");
      
      // Show on OLED
      oled.clearDisplay();
      oled.setTextSize(1);
      oled.setCursor(10, 10);
      oled.print("RESETTING...");
      oled.setCursor(0, 25);
      oled.print("Clearing WiFi");
      oled.setCursor(0, 35);
      oled.print("Entering Setup");
      oled.setCursor(0, 50);
      oled.print("Please wait...");
      oled.display();
      
      Serial.println("🔄 Restarting ESP32 to enter setup mode...");
      delay(3000);
      ESP.restart(); // Restart to enter setup mode
      break;
    case BUTTON2_ID :
      buzzerBeep(2);
      Serial.println("btUP press short");
      break;
    case BUTTON3_ID :
      buzzerBeep(2);
      Serial.println("btDOWN press short");
      enableShow = DISABLE;
      autoWarning = 1 - autoWarning;
      EEPROM.write(210, autoWarning);  EEPROM.commit();
      // Update autoWarning status to Firebase
      updateAutoWarningToFirebase(autoWarning);
      if(autoWarning == 0) screenOLED = SCREEN11;
      else screenOLED = SCREEN10;
      break;  
  } 
} 
// ---------------------- Hàm điều khiển còi -----------------------------
void buzzerBeep(int numberBeep) {
  for(int i = 0; i < numberBeep; ++i) {
    digitalWrite(BUZZER, ENABLE);
    delay(100);
    digitalWrite(BUZZER, DISABLE);
    delay(100);
  }  
}
// ---------------------- Hàm điều khiển LED -----------------------------
void blinkLED(int numberBlink) {
  for(int i = 0; i < numberBlink; ++i) {
    digitalWrite(LED, DISABLE);
    delay(300);
    digitalWrite(LED, ENABLE);
    delay(300);
  }  
}

/**
 * @brief Kiểm tra chất lượng không khí và gửi lên Firebase
 *
 * @param autoWarning auto Warning
 * @param temp Nhiệt độ hiện tại    *C
 * @param humi Độ ẩm hiện tại        %
 * @param dust bụi PM2.5 hiện tại    ug/m3
 */
void check_air_quality_and_send_to_firebase(bool autoWarning, int temp, int humi, int dust) {
  String notifications = "";
  int tempIndex = 0;
  int dustIndex = 0;
  int humiIndex = 0;
  if(dht11ReadOK ==  true) {
  if(autoWarning == 0) {
    if(temp < EtempThreshold1 )tempIndex = 1;
    else if(temp >= EtempThreshold1 && temp <=  EtempThreshold2)  tempIndex = 2;
    else tempIndex = 3;
    

    if(humi < EhumiThreshold1 ) humiIndex = 1;
    else if(humi >= EhumiThreshold1 && humi <= EhumiThreshold2)   humiIndex = 2;
    else humiIndex = 3;

    if(dust < EdustThreshold1 ) dustIndex = 1;
    else if(dust >= EdustThreshold1 && EdustThreshold1 <= EtempThreshold2)   dustIndex = 2;
    else dustIndex = 3;
    
    notifications = snTemp[tempIndex] + String(temp) + "*C . " + snHumi[humiIndex] + String(humi) + "% . " + snDust[dustIndex] + String(dust) + "ug/m3 . " ;  
    
    sendAlertToFirebase("check_data", notifications);
  } else {
    if(temp < EtempThreshold1 )tempIndex = 1;
    else if(temp >= EtempThreshold1 && temp <=  EtempThreshold2)  tempIndex = 0;
    else tempIndex = 3;
    

    if(humi < EhumiThreshold1 ) humiIndex = 1;
    else if(humi >= EhumiThreshold1 && humi <= EhumiThreshold2)   humiIndex = 0;
    else humiIndex = 3;

    if(dust < EdustThreshold1 ) dustIndex = 0;
    else if(dust >= EdustThreshold1 && EdustThreshold1 <= EdustThreshold2)   dustIndex = 2;
    else dustIndex = 3;

    if(tempIndex == 0 && humiIndex == 0 && dustIndex == 0)
      notifications = "";
    else {
      if(tempIndex != 0) notifications = notifications + snTemp[tempIndex] + String(temp) + "*C . ";
      if(humiIndex != 0) notifications = notifications + snHumi[humiIndex] + String(humi) + "% . " ;
      if(dustIndex != 0) notifications = notifications + snDust[dustIndex] + String(dust) + "ug/m3 . " ;
      sendAlertToFirebase("auto_warning", notifications);
    }
  }

  Serial.println(notifications);
  }
}

//--------------------------- Setup Mode Functions ---------------------------
void startSetupMode() {
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║          SETUP MODE STARTING          ║");
    Serial.println("╚════════════════════════════════════════╝");
    
    // Stop any existing WiFi connection and tasks
    WiFi.disconnect(true);
    delay(1000);
    
    // Try to start AP with retry logic to avoid restart loops
    const int MAX_AP_RETRIES = 3;
    bool apStarted = false;
    
    for (int retry = 1; retry <= MAX_AP_RETRIES; retry++) {
        Serial.println("🔄 Starting WiFi AP (attempt " + String(retry) + "/" + String(MAX_AP_RETRIES) + ")");
        
        WiFi.mode(WIFI_AP);
        delay(500);  // Give time for mode switch
        
        bool apResult = WiFi.softAP(setupAPSSID.c_str(), setupAPPassword, 1, 0, 4);
        
        if (apResult) {
            // Configure AP settings
            IPAddress local_IP(192, 168, 4, 1);
            IPAddress gateway(192, 168, 4, 1);  
            IPAddress subnet(255, 255, 255, 0);
            WiFi.softAPConfig(local_IP, gateway, subnet);
            
            // Wait for AP to stabilize
            delay(2000);
            
            // Verify AP is working
            if (WiFi.getMode() == WIFI_AP && WiFi.softAPIP().toString() == "192.168.4.1") {
                apStarted = true;
                Serial.println("✅ WiFi AP started and verified!");
                break;
            } else {
                Serial.println("⚠️  AP verification failed on attempt " + String(retry));
            }
        } else {
            Serial.println("❌ Failed to start WiFi AP on attempt " + String(retry));
        }
        
        if (retry < MAX_AP_RETRIES) {
            Serial.println("⏳ Waiting 3s before retry...");
            WiFi.mode(WIFI_OFF);
            delay(3000);
        }
    }
    
    if (!apStarted) {
        Serial.println("💥 CRITICAL: Cannot start AP after " + String(MAX_AP_RETRIES) + " attempts!");
        Serial.println("🔄 Will try basic AP configuration...");
        
        // Last resort - try basic AP without custom config
        WiFi.mode(WIFI_AP);
        if (WiFi.softAP("ESP32-Emergency", "12345678")) {
            Serial.println("⚠️  Emergency AP started: ESP32-Emergency / 12345678");
            setupAPSSID = "ESP32-Emergency";
        } else {
            Serial.println("💀 Complete AP failure - entering infinite loop");
            while(1) {
                delay(10000);
                Serial.println("💀 ESP32 AP hardware failure - manual restart required");
            }
        }
    }
    
    // Print detailed AP information
    Serial.println("📡 WiFi Access Point Details:");
    Serial.println("   SSID: " + setupAPSSID);
    Serial.println("   Password: " + String(setupAPPassword));
    Serial.println("   IP Address: " + WiFi.softAPIP().toString());
    Serial.println("   MAC Address: " + WiFi.softAPmacAddress());
    Serial.println("   Channel: 1");
    Serial.println("   Max Connections: 4");
    
    // Setup web server routes
    setupWebServerRoutes();
    
    // Start web server (no DNS server needed for API-only mode)
    server.begin();
    Serial.println("🌐 Web server started on http://192.168.4.1");
    Serial.println("🔧 API endpoints ready: /api/scan, /api/configure, /api/info");
    
    // Update OLED display
    screenOLED = SCREEN9; // Show setup mode screen
    Serial.println("📺 OLED display set to setup mode");
    
    // Start a task to monitor AP status
    xTaskCreatePinnedToCore(TaskMonitorAP, "TaskMonitorAP", 1024*2, NULL, 5, NULL, 1);
    
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║         SETUP MODE READY!             ║");
    Serial.println("║  Connect to WiFi: " + setupAPSSID.substring(0, 16) + " ║");
    Serial.println("║  Password: " + String(setupAPPassword) + "                   ║");
    Serial.println("║  Use Android App for configuration     ║");
    Serial.println("╚════════════════════════════════════════╝");
}

void setupWebServerRoutes() {
    // Simple status page instead of complex HTML form
    server.on("/", HTTP_GET, [](AsyncWebServerRequest *request){
        String html = "<!DOCTYPE html><html><head><title>ESP32 Setup</title></head><body>"
                     "<h1>ESP32 Air Monitor</h1>"
                     "<p><strong>Device ID:</strong> " + deviceId + "</p>"
                     "<p><strong>Status:</strong> Setup Mode - Waiting for Android App</p>"
                     "<p><strong>Network:</strong> " + setupAPSSID + "</p>"
                     "<p><strong>Password:</strong> " + String(setupAPPassword) + "</p>"
                     "<h2>API Endpoints:</h2>"
                     "<p>GET /api/info - Device information</p>"
                     "<p>GET /api/scan - Scan WiFi networks</p>"
                     "<p>POST /api/configure - Configure device</p>"
                     "<hr><p>Use the Android app to configure this device.</p>"
                     "</body></html>";
        request->send(200, "text/html", html);
    });

    // API endpoint to scan WiFi networks - Enhanced with error handling
    server.on("/api/scan", HTTP_GET, [](AsyncWebServerRequest *request){
        Serial.println("📡 Received WiFi scan request from Android app");
        
        JSONVar jsonResponse;
        JSONVar networks;
        
        Serial.println("🔍 Starting WiFi scan...");
        int n = WiFi.scanNetworks();
        Serial.println("📶 Found " + String(n) + " WiFi networks");
        
        if (n == 0) {
            jsonResponse["networks"] = networks;
            jsonResponse["count"] = 0;
            jsonResponse["message"] = "No networks found";
        } else if (n > 0) {
            for (int i = 0; i < n; i++) {
                JSONVar network;
                network["ssid"] = WiFi.SSID(i);
                network["rssi"] = WiFi.RSSI(i);
                network["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
                networks[i] = network;
                
                Serial.println("  📡 " + WiFi.SSID(i) + " (" + String(WiFi.RSSI(i)) + "dBm)");
            }
            jsonResponse["networks"] = networks;
            jsonResponse["count"] = n;
            jsonResponse["message"] = "Scan completed successfully";
        } else {
            Serial.println("❌ WiFi scan failed");
            jsonResponse["networks"] = networks;
            jsonResponse["count"] = 0;
            jsonResponse["message"] = "Scan failed";
        }
        
        String jsonString = JSON.stringify(jsonResponse);
        
        // Add CORS headers and send response
        request->send(200, "application/json", jsonString);
        
        Serial.println("✅ WiFi scan response sent to Android app");
    });

    // API endpoint to get device info
    server.on("/api/info", HTTP_GET, [](AsyncWebServerRequest *request){
        JSONVar response;
        response["deviceId"] = deviceId;
        response["status"] = "setup_mode";
        response["version"] = "1.0.0";
        response["setupSSID"] = setupAPSSID;
        
        String jsonString = JSON.stringify(response);
        request->send(200, "application/json", jsonString);
    });

    // API endpoint to configure device
    server.on("/api/configure", HTTP_POST, [](AsyncWebServerRequest *request){
        Serial.println("📡 Received configuration request from Android app");
        // This will be handled in the body handler
    }, NULL, [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total){
        
        Serial.println("📥 Processing configuration data...");
        String requestBody = String((char*)data);
        Serial.println("Request body: " + requestBody);
        
        JSONVar configData = JSON.parse(requestBody.c_str());
        JSONVar response;
        
        if (JSON.typeof(configData) == "undefined") {
            Serial.println("❌ Invalid JSON received");
            response["success"] = false;
            response["message"] = "Invalid JSON format";
            String jsonString = JSON.stringify(response);
            request->send(400, "application/json", jsonString);
            return;
        }
        
        try {
            // Extract configuration data
            String ssid = (const char*)configData["ssid"];
            String password = (const char*)configData["password"];
            String userKey = (const char*)configData["userKey"];
            String userUID = (const char*)configData["userUID"];
            
            Serial.println("🔧 Config received:");
            Serial.println("  SSID: " + ssid);
            Serial.println("  Password: [HIDDEN]");
            Serial.println("  UserKey: " + userKey.substring(0, 8) + "***");
            Serial.println("  UserUID: " + userUID.substring(0, 8) + "***");
            
            if (ssid.length() > 0 && password.length() > 0 && userKey.length() > 0 && userUID.length() > 0) {
                // Save to EEPROM
                Essid = ssid;
                Epass = password;
                EuserKey = userKey;
                EuserUID = userUID;  // Save userUID to EEPROM
                EfirebaseHost = String(FIREBASE_HOST);
                EfirebaseAuth = String(FIREBASE_AUTH);
                
                Serial.println("💾 Saving configuration to EEPROM...");
                writeEEPROM();
                Serial.println("✅ Configuration saved successfully!");
                
                response["success"] = true;
                response["message"] = "Configuration saved successfully. Device will restart.";
                
                String jsonString = JSON.stringify(response);
                request->send(200, "application/json", jsonString);
                
                Serial.println("📤 Response sent to Android app");
                Serial.println("🔄 Scheduling restart in 3 seconds...");
                
                // Schedule restart using task to ensure response is sent first
                xTaskCreate([](void* param) {
                    delay(3000); // Wait 3 seconds to ensure response is fully sent
                    Serial.println("🔄 Restarting ESP32 to connect to home WiFi...");
                    ESP.restart();
                }, "RestartTask", 2048, NULL, 1, NULL);
            } else {
                Serial.println("❌ Invalid configuration data - missing fields");
                response["success"] = false;
                response["message"] = "Missing required fields: ssid, password, userKey, or userUID";
                String jsonString = JSON.stringify(response);
                request->send(400, "application/json", jsonString);
            }
        } catch (...) {
            Serial.println("❌ Error parsing JSON configuration data");
            response["success"] = false;
            response["message"] = "Error parsing configuration data";
            String jsonString = JSON.stringify(response);
            request->send(400, "application/json", jsonString);
        }
    });

    // Catch all other requests and redirect to captive portal
    server.onNotFound([](AsyncWebServerRequest *request){
        if (request->host() != WiFi.softAPIP().toString()) {
            request->redirect(captivePortalURL);
        } else {
            request->send(404, "text/plain", "Not found");
        }
    });
}

//---------------------------Task DNS Server---------------------------
void TaskDNSServer(void *pvParameters) {
    while(1) {
        if (setupMode) {
            dnsServer.processNextRequest();
        }
        delay(10);
    }
}

//---------------------------Task Monitor AP---------------------------
void TaskMonitorAP(void *pvParameters) {
    int lastClientCount = 0;
    int checkCounter = 0;
    
    while(1) {
        if (setupMode) {
            // Check every 5 seconds
            checkCounter++;
            if (checkCounter >= 500) { // 500 * 10ms = 5 seconds
                checkCounter = 0;
                
                // Get number of connected clients
                int currentClients = WiFi.softAPgetStationNum();
                
                if (currentClients != lastClientCount) {
                    Serial.println("👥 Connected clients: " + String(currentClients));
                    if (currentClients > 0) {
                        Serial.println("📱 Android device connected to ESP32 WiFi!");
                    }
                    lastClientCount = currentClients;
                }
                
                // Check WiFi AP status
                if (WiFi.getMode() != WIFI_AP) {
                    Serial.println("⚠️  WiFi AP disconnected! Restarting...");
                    ESP.restart();
                }
                
                // Print periodic status
                Serial.println("📊 AP Status - Clients: " + String(currentClients) + 
                              ", SSID: " + setupAPSSID + 
                              ", IP: " + WiFi.softAPIP().toString());
            }
        }
        delay(10);
  }
}

//--------------------------- Firebase Functions ---------------------------
void initFirebase() {
    // Configure Firebase with default values
    config.host = FIREBASE_HOST;
    config.api_key = FIREBASE_AUTH;  // Use API key instead of legacy token
    
    // Initialize Firebase
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    
    Serial.println("Firebase initialized with default config");
    Serial.println("Host: " + String(FIREBASE_HOST));
}

bool connectFirebase() {
    Serial.println("🔥 Configuring Firebase connection...");
    
    // Validate Firebase credentials from EEPROM
    if (EfirebaseHost.length() == 0) {
        Serial.println("❌ Firebase Host missing from EEPROM");
        return false;
    }
    if (EfirebaseAuth.length() == 0) {
        Serial.println("❌ Firebase Auth Key missing from EEPROM");
        return false;
    }
    if (EuserUID.length() == 0) {
        Serial.println("❌ UserUID missing from EEPROM");
        return false;
    }
    
    Serial.println("✅ Firebase credentials validation passed");
    Serial.println("   🔥 Host: " + EfirebaseHost);
    Serial.println("   🗝️  Auth: " + String(EfirebaseAuth.length()) + " chars");
    Serial.println("   👤 UID:  " + EuserUID.substring(0, 8) + "***");
    
    // Configure Firebase
    config.host = EfirebaseHost;
    config.api_key = EfirebaseAuth;
    config.database_url = "https://" + EfirebaseHost;  // Add proper database URL
    
    Serial.println("📝 Signing up anonymously with API key...");
    if (!Firebase.signUp(&config, &auth, "", "")) {
        Serial.println("❌ SignUp failed: " + String(config.signer.signupError.message.c_str()));
        return false;
    }

    Serial.println("✅ SignUp OK, initializing Firebase...");
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    // Wait up to 10s for token ready
    unsigned long fbWaitUntil = millis() + 10000;
    while (!Firebase.ready() && millis() < fbWaitUntil) {
        delay(200);
    }
    
    // Test Firebase connection with a simple read
    Serial.println("🧪 Testing Firebase connection...");
    if (Firebase.ready()) {
        Serial.println("✅ Firebase ready and authenticated");
        
        // Set global variables from EEPROM
        userUID = EuserUID;  // Real userUID from Firebase Auth
        userKey = EuserKey;  // UserKey for device pairing
        
        // Register device in pending devices (for app to discover)
        Serial.println("📝 Registering device in pending list...");
        if (registerDevicePending()) {
            firebaseReady = true;
            Serial.println("✅ Firebase connected and device registered successfully");
            return true;
        } else {
            Serial.println("❌ Device registration failed");
            firebaseReady = false;
            return false;
        }
    } else {
        Serial.println("❌ Firebase connection failed - not ready");
        // Test with a simple operation to get error details
        String testPath = "/test";
        if (!Firebase.getString(firebaseData, testPath)) {
            Serial.println("🔍 Firebase error: " + firebaseData.errorReason());
        }
        firebaseReady = false;
        return false;
    }
}

void sendAlertToFirebase(String alertType, String message) {
    if (firebaseReady && userUID.length() > 0 && message.length() > 0) {
        String alertId = String(millis());
        String path = "/alerts/" + userUID + "/" + alertId;
        
        FirebaseJson json;
        json.set("deviceId", deviceId);
        json.set("type", alertType);
        json.set("message", message);
        json.set("timestamp", alertId);
        json.set("acknowledged", false);
        
        if (Firebase.setJSON(firebaseData, path.c_str(), json)) {
            Serial.println("Alert sent to Firebase: " + message);
        } else {
            Serial.println("Failed to send alert to Firebase");
            Serial.println(firebaseData.errorReason());
        }
    }
}

void updateAutoWarningToFirebase(int autoWarningStatus) {
    if (firebaseReady && userUID.length() > 0 && deviceId.length() > 0) {
        String path = "/users/" + userUID + "/devices/" + deviceId + "/autoWarning";
        
        if (Firebase.setBool(firebaseData, path.c_str(), autoWarningStatus == 1)) {
            Serial.println("AutoWarning status updated in Firebase");
        } else {
            Serial.println("Failed to update autoWarning in Firebase");
            Serial.println(firebaseData.errorReason());
        }
    }
}

bool registerDevicePending() {
    if (userKey.length() > 0 && deviceId.length() > 0) {
        Serial.println("Registering device in pending list...");
        
        // Register in pendingDevices (app will discover this device)
        String pendingPath = "/pendingDevices/" + deviceId;
        FirebaseJson pendingJson;
        pendingJson.set("deviceId", deviceId);
        pendingJson.set("deviceName", "ESP32 Air Monitor");
        pendingJson.set("userKey", userKey);
        pendingJson.set("macAddress", WiFi.macAddress());
        pendingJson.set("ipAddress", WiFi.localIP().toString());
        pendingJson.set("wifiSSID", WiFi.SSID());
        pendingJson.set("status", "pending_pairing");
        pendingJson.set("firmware", "1.0.0");
        pendingJson.set("registeredAt", String(millis()));
        
        if (!Firebase.setJSON(firebaseData, pendingPath.c_str(), pendingJson)) {
            Serial.println("Failed to register device in pending list: " + firebaseData.errorReason());
            return false;
        }
        
        Serial.println("Device registered in pending list successfully");
        Serial.println("UserKey: " + userKey);
        Serial.println("DeviceId: " + deviceId);
        return true;
    } else {
        Serial.println("Missing userKey or deviceId for registration");
        Serial.println("UserKey: " + userKey);
        Serial.println("DeviceId: " + deviceId);
        return false;
    }
}
