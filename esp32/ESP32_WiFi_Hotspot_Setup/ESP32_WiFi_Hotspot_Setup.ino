/*
 * ESP32 WiFi Hotspot Setup - IP Camera Style Onboarding
 * Creates WiFi hotspot for configuration, then switches to station mode
 */

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <SSD1306Wire.h>
#include <Wire.h>

// OLED Display
SSD1306Wire display(0x3c, 21, 22);

// Web Server and DNS for Captive Portal
WebServer server(80);
DNSServer dnsServer;

// Preferences for storing WiFi credentials
Preferences preferences;

// Device Configuration
String deviceId = "";
String deviceName = "";
String apSSID = "";
String apPassword = "12345678"; // Default AP password

// Setup State
enum SetupState {
  SETUP_MODE,
  CONNECTING_WIFI,
  CONNECTED,
  ERROR_STATE
};

SetupState currentState = SETUP_MODE;
String targetSSID = "";
String targetPassword = "";
unsigned long stateChangeTime = 0;

// Firebase Configuration
const char* firebaseHost = "iotkhongkhi-default-rtdb.asia-southeast1.firebasedatabase.app";
const char* firebaseAuth = ""; // Will be set from web interface

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 WiFi Hotspot Setup Starting...");

  // Initialize LED pin
  pinMode(2, OUTPUT);
  digitalWrite(2, LOW);

  // Initialize OLED
  Wire.begin(21, 22);
  display.init();
  display.flipScreenVertically();
  display.setFont(ArialMT_Plain_10);
  
  // Generate device ID and name
  generateDeviceInfo();
  
  // Initialize preferences
  preferences.begin("wifi-config", false);
  
  // Check if already configured (like BLKLab_PRJ05 EEPROM check)
  if (preferences.isKey("configured") && preferences.getBool("configured")) {
    // Try to connect to saved WiFi
    String savedSSID = preferences.getString("ssid", "");
    String savedPassword = preferences.getString("password", "");

    if (savedSSID.length() > 1) {  // Same check as BLKLab_PRJ05
      Serial.println("🔵 Found saved WiFi config:");
      Serial.println("📶 SSID: " + savedSSID);
      Serial.println("🔑 Password: [HIDDEN]");
      Serial.println("🔄 Attempting automatic connection...");

      // Try STA connection first (BLKLab_PRJ05 approach)
      connectToWiFi(savedSSID, savedPassword);
      return;
    }
  }
  
  // Start in setup mode
  startSetupMode();
}

void loop() {
  dnsServer.processNextRequest();
  server.handleClient();
  
  // Handle state transitions
  switch (currentState) {
    case SETUP_MODE:
      handleSetupMode();
      break;
      
    case CONNECTING_WIFI:
      handleConnectingState();
      break;
      
    case CONNECTED:
      handleConnectedState();
      break;
      
    case ERROR_STATE:
      handleErrorState();
      break;
  }
  
  // Update display
  updateDisplay();
  delay(100);
}

void generateDeviceInfo() {
  // Generate unique device ID from MAC address
  uint64_t chipid = ESP.getEfuseMac();
  deviceId = String((uint32_t)(chipid >> 32), HEX) + String((uint32_t)chipid, HEX);
  deviceId.toUpperCase();
  
  // Create device name and AP SSID
  deviceName = "ESP32-AirMonitor-" + deviceId.substring(0, 6);
  apSSID = "ESP32-Setup-" + deviceId.substring(0, 6);
  
  Serial.println("Device ID: " + deviceId);
  Serial.println("Device Name: " + deviceName);
  Serial.println("AP SSID: " + apSSID);
}

void startSetupMode() {
  Serial.println("🔧 Starting WiFi Setup Mode...");

  // Stop any existing connections
  WiFi.disconnect(true);
  delay(1000);

  // Configure AP mode with improved settings (like BLKLab_PRJ05)
  WiFi.mode(WIFI_AP);

  // Use same AP settings as BLKLab_PRJ05 for compatibility
  bool result = WiFi.softAP(apSSID.c_str(), apPassword.c_str(), 1, 0, 4);

  if (result) {
    Serial.println("✅ WiFi AP started successfully");
    Serial.println("📶 SSID: " + apSSID);
    Serial.println("🔑 Password: " + apPassword);
    Serial.println("📡 IP: " + WiFi.softAPIP().toString());
    Serial.println("👥 Max clients: 4");
    Serial.println("📻 Channel: 1");

    // Start DNS server for captive portal
    dnsServer.setErrorReplyCode(DNSReplyCode::NoError);
    dnsServer.start(53, "*", WiFi.softAPIP());

    // Setup web server routes
    setupWebServer();

    currentState = SETUP_MODE;
    stateChangeTime = millis();

    Serial.println("🔧 Setup mode ready - connect to WiFi and visit 192.168.4.1");

  } else {
    Serial.println("❌ Failed to start WiFi AP");
    Serial.println("🔄 Retrying with alternative configuration...");

    // Try alternative configuration like BLKLab_PRJ05
    result = WiFi.softAP(apSSID.c_str(), apPassword.c_str());

    if (result) {
      Serial.println("✅ Alternative AP configuration successful");
      Serial.println("📡 IP: " + WiFi.softAPIP().toString());

      // Start DNS server
      dnsServer.setErrorReplyCode(DNSReplyCode::NoError);
      dnsServer.start(53, "*", WiFi.softAPIP());

      // Setup web server routes
      setupWebServer();

      currentState = SETUP_MODE;
      stateChangeTime = millis();

    } else {
      Serial.println("❌ All AP configurations failed");
      currentState = ERROR_STATE;
    }
  }
}

void setupWebServer() {
  // Captive portal - redirect all requests to setup page
  server.onNotFound(handleCaptivePortal);
  
  // Setup page
  server.on("/", handleSetupPage);
  server.on("/setup", handleSetupPage);
  
  // API endpoints
  server.on("/api/info", HTTP_GET, handleGetInfo);
  server.on("/api/scan", HTTP_GET, handleWiFiScan);
  server.on("/api/configure", HTTP_POST, handleConfigure);
  server.on("/api/status", HTTP_GET, handleStatus);
  
  // Static files
  server.on("/style.css", handleCSS);
  server.on("/script.js", handleJS);
  
  server.begin();
  Serial.println("Web server started");
}

void handleCaptivePortal() {
  // Redirect to setup page
  server.sendHeader("Location", "http://192.168.4.1/setup", true);
  server.send(302, "text/plain", "");
}

void handleSetupPage() {
  String html = R"HTML(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESP32 Air Monitor Setup</title>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌬️ Air Monitor Setup</h1>
            <p class="device-info">Device: <span id="deviceName">Loading...</span></p>
        </div>
        
        <div class="setup-form">
            <h2>WiFi Configuration</h2>
            
            <div class="form-group">
                <label for="ssid">WiFi Network:</label>
                <select id="ssid" onchange="updatePassword()">
                    <option value="">Scanning networks...</option>
                </select>
                <button onclick="scanNetworks()" class="scan-btn">🔄 Refresh</button>
            </div>
            
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" placeholder="Enter WiFi password">
                <button type="button" onclick="togglePassword()" class="toggle-btn">👁️</button>
            </div>
            
            <div class="form-group">
                <button onclick="configureWiFi()" class="setup-btn" id="setupBtn">
                    Connect to WiFi
                </button>
            </div>
            
            <div id="status" class="status"></div>
            <div id="progress" class="progress" style="display: none;">
                <div class="progress-bar"></div>
            </div>
        </div>
    </div>
    
    <script src="/script.js"></script>
</body>
</html>
  )HTML";

  server.send(200, "text/html", html);
}

void connectToWiFi(String ssid, String password) {
  Serial.println("🔵 Connecting to WiFi: " + ssid);

  currentState = CONNECTING_WIFI;
  stateChangeTime = millis();
  targetSSID = ssid;
  targetPassword = password;

  // Stop AP mode first
  WiFi.softAPdisconnect(true);
  delay(1000);

  // Configure STA mode with improved settings
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

  // Start connection
  WiFi.begin(ssid.c_str(), password.c_str());

  Serial.println("🔵 WiFi connection started, waiting for result...");
}

void handleSetupMode() {
  // Blink built-in LED to indicate setup mode
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 1000) {
    digitalWrite(2, !digitalRead(2));
    lastBlink = millis();
  }
}

void handleConnectingState() {
  static unsigned long lastCheck = 0;
  static int connectAttempts = 0;

  if (millis() - lastCheck > 500) {
    connectAttempts++;

    wl_status_t status = WiFi.status();
    Serial.println("🔵 WiFi Status: " + String(status) + " (attempt " + String(connectAttempts) + "/30)");

    if (status == WL_CONNECTED) {
      Serial.println("✅ WiFi connected successfully!");
      Serial.println("📶 SSID: " + WiFi.SSID());
      Serial.println("📡 IP address: " + WiFi.localIP().toString());
      Serial.println("📊 Signal strength: " + String(WiFi.RSSI()) + " dBm");

      // Save configuration to EEPROM (like BLKLab_PRJ05)
      preferences.putString("ssid", targetSSID);
      preferences.putString("password", targetPassword);
      preferences.putBool("configured", true);

      currentState = CONNECTED;
      stateChangeTime = millis();
      connectAttempts = 0;

      // Register with Firebase
      registerWithFirebase();

    } else if (connectAttempts >= 30) {
      // Timeout after 30 attempts (15 seconds) - same as BLKLab_PRJ05
      Serial.println("❌ WiFi connection timeout after 30 attempts");
      Serial.println("🔄 Switching back to AP mode for reconfiguration");

      currentState = ERROR_STATE;
      stateChangeTime = millis();
      connectAttempts = 0;

      // Switch back to AP mode like BLKLab_PRJ05
      delay(1000);
      startSetupMode();

    } else {
      // Show connection progress
      if (connectAttempts % 5 == 0) {
        Serial.println("🔄 Still connecting... (" + String(connectAttempts) + "/30)");
      }
    }

    lastCheck = millis();
  }
}

void updateDisplay() {
  display.clear();
  
  switch (currentState) {
    case SETUP_MODE:
      display.drawString(0, 0, "Setup Mode");
      display.drawString(0, 12, "WiFi: " + apSSID);
      display.drawString(0, 24, "Pass: " + apPassword);
      display.drawString(0, 36, "IP: 192.168.4.1");
      display.drawString(0, 48, "Open browser to setup");
      break;
      
    case CONNECTING_WIFI:
      display.drawString(0, 0, "Connecting WiFi...");
      display.drawString(0, 12, "Network: " + targetSSID);
      display.drawString(0, 24, "Please wait...");
      break;
      
    case CONNECTED:
      display.drawString(0, 0, "Connected!");
      display.drawString(0, 12, "WiFi: " + targetSSID);
      display.drawString(0, 24, "IP: " + WiFi.localIP().toString());
      display.drawString(0, 36, "Device: " + deviceName);
      break;
      
    case ERROR_STATE:
      display.drawString(0, 0, "Connection Failed");
      display.drawString(0, 12, "Check WiFi settings");
      display.drawString(0, 24, "Restarting setup...");
      break;
  }
  
  display.display();
}

// API Handlers
void handleGetInfo() {
  DynamicJsonDocument doc(1024);
  doc["deviceId"] = deviceId;
  doc["deviceName"] = deviceName;
  doc["firmwareVersion"] = "1.0.0";
  doc["state"] = getStateString();
  doc["apSSID"] = apSSID;
  doc["apPassword"] = apPassword;

  if (currentState == CONNECTED) {
    doc["wifiSSID"] = WiFi.SSID();
    doc["wifiIP"] = WiFi.localIP().toString();
    doc["wifiRSSI"] = WiFi.RSSI();
  }

  String response;
  serializeJson(doc, response);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);
}

void handleWiFiScan() {
  Serial.println("Scanning WiFi networks...");

  int networkCount = WiFi.scanNetworks();

  DynamicJsonDocument doc(2048);
  JsonArray networks = doc.createNestedArray("networks");

  for (int i = 0; i < networkCount; i++) {
    JsonObject network = networks.createNestedObject();
    network["ssid"] = WiFi.SSID(i);
    network["rssi"] = WiFi.RSSI(i);
    network["encryption"] = (WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "open" : "secured";
  }

  String response;
  serializeJson(doc, response);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);
}

void handleConfigure() {
  if (server.method() != HTTP_POST) {
    server.send(405, "text/plain", "Method Not Allowed");
    return;
  }

  String body = server.arg("plain");
  DynamicJsonDocument doc(1024);
  deserializeJson(doc, body);

  String ssid = doc["ssid"];
  String password = doc["password"];

  if (ssid.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"SSID is required\"}");
    return;
  }

  Serial.println("Received WiFi configuration:");
  Serial.println("SSID: " + ssid);
  Serial.println("Password: [HIDDEN]");

  // Start WiFi connection
  connectToWiFi(ssid, password);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", "{\"status\":\"connecting\",\"message\":\"Connecting to WiFi...\"}");
}

void handleStatus() {
  DynamicJsonDocument doc(512);
  doc["state"] = getStateString();
  doc["uptime"] = millis();

  if (currentState == CONNECTING_WIFI) {
    doc["progress"] = min(100, (int)((millis() - stateChangeTime) / 300)); // 30 second timeout
    doc["message"] = "Connecting to " + targetSSID + "...";
  } else if (currentState == CONNECTED) {
    doc["wifiSSID"] = WiFi.SSID();
    doc["wifiIP"] = WiFi.localIP().toString();
    doc["message"] = "Connected successfully!";
  } else if (currentState == ERROR_STATE) {
    doc["message"] = "Connection failed. Please check credentials.";
  }

  String response;
  serializeJson(doc, response);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);
}

String getStateString() {
  switch (currentState) {
    case SETUP_MODE: return "setup";
    case CONNECTING_WIFI: return "connecting";
    case CONNECTED: return "connected";
    case ERROR_STATE: return "error";
    default: return "unknown";
  }
}

void handleConnectedState() {
  // Monitor connection and send data
  static unsigned long lastDataSend = 0;
  static unsigned long lastStatusCheck = 0;

  // Send data every 30 seconds
  if (millis() - lastDataSend > 30000) {
    sendSensorData();
    lastDataSend = millis();
  }

  // Check WiFi status every 5 seconds (like BLKLab_PRJ05)
  if (millis() - lastStatusCheck > 5000) {
    wl_status_t status = WiFi.status();

    if (status == WL_CONNECTED) {
      // Connection is good - solid LED
      digitalWrite(2, HIGH);

      // Log status occasionally
      static int statusCounter = 0;
      if (statusCounter++ >= 12) { // Every minute
        Serial.println("📶 WiFi Status: Connected (" + String(WiFi.RSSI()) + " dBm)");
        statusCounter = 0;
      }
    } else {
      Serial.println("❌ WiFi connection lost - Status: " + String(status));
      Serial.println("🔄 Attempting to reconnect...");

      // Try to reconnect like BLKLab_PRJ05
      String savedSSID = preferences.getString("ssid", "");
      String savedPassword = preferences.getString("password", "");

      if (savedSSID.length() > 1) {
        connectToWiFi(savedSSID, savedPassword);
      } else {
        // No saved credentials, go to setup mode
        Serial.println("⚠️ No saved WiFi credentials, switching to setup mode");
        currentState = ERROR_STATE;
        stateChangeTime = millis();
      }
    }

    lastStatusCheck = millis();
  }
}

void handleErrorState() {
  // Fast blink LED for error
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 200) {
    digitalWrite(2, !digitalRead(2));
    lastBlink = millis();
  }

  // Auto-restart setup mode after 10 seconds
  if (millis() - stateChangeTime > 10000) {
    Serial.println("Restarting setup mode after error...");
    preferences.putBool("configured", false); // Clear saved config
    ESP.restart();
  }
}

void registerWithFirebase() {
  // TODO: Implement Firebase device registration
  Serial.println("Registering device with Firebase...");

  // For now, just print the device info that would be registered
  Serial.println("Device registration data:");
  Serial.println("- Device ID: " + deviceId);
  Serial.println("- Device Name: " + deviceName);
  Serial.println("- WiFi SSID: " + WiFi.SSID());
  Serial.println("- IP Address: " + WiFi.localIP().toString());
  Serial.println("- MAC Address: " + WiFi.macAddress());
}

void sendSensorData() {
  // TODO: Implement sensor reading and data sending to Firebase
  Serial.println("Sending sensor data to Firebase...");

  // Example of what you might do here:
  // float temperature = readTemperature(); // Your function to read sensor
  // float humidity = readHumidity();       // Your function to read sensor
  //
  // if (WiFi.status() == WL_CONNECTED) {
  //   Firebase.setFloat("devices/" + deviceId + "/temperature", temperature);
  //   Firebase.setFloat("devices/" + deviceId + "/humidity", humidity);
  // }
}

// Static file handlers
void handleCSS() {
  String css = R"CSS(
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.container {
    background: white;
    border-radius: 16px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
    padding: 32px;
    width: 100%;
    max-width: 400px;
}

.header {
    text-align: center;
    margin-bottom: 32px;
}

.header h1 {
    color: #333;
    font-size: 24px;
    margin-bottom: 8px;
}

.device-info {
    color: #666;
    font-size: 14px;
}

.form-group {
    margin-bottom: 20px;
}

label {
    display: block;
    margin-bottom: 8px;
    color: #333;
    font-weight: 500;
}

select, input {
    width: 100%;
    padding: 12px;
    border: 2px solid #e1e5e9;
    border-radius: 8px;
    font-size: 16px;
    transition: border-color 0.3s;
}

select:focus, input:focus {
    outline: none;
    border-color: #667eea;
}

.scan-btn, .toggle-btn {
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 6px;
    padding: 8px 12px;
    margin-left: 8px;
    cursor: pointer;
    font-size: 14px;
}

.setup-btn {
    width: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 8px;
    padding: 16px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s;
}

.setup-btn:hover {
    transform: translateY(-2px);
}

.setup-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
}

.status {
    margin-top: 16px;
    padding: 12px;
    border-radius: 8px;
    text-align: center;
    font-weight: 500;
}

.status.success {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
}

.status.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f5c6cb;
}

.status.info {
    background: #d1ecf1;
    color: #0c5460;
    border: 1px solid #bee5eb;
}

.progress {
    margin-top: 16px;
    background: #e9ecef;
    border-radius: 8px;
    overflow: hidden;
    height: 8px;
}

.progress-bar {
    height: 100%;
    background: linear-gradient(90deg, #667eea, #764ba2);
    width: 0%;
    transition: width 0.3s ease;
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0% { opacity: 1; }
    50% { opacity: 0.7; }
    100% { opacity: 1; }
}

@media (max-width: 480px) {
    .container {
        padding: 24px;
        margin: 10px;
    }
}
  )CSS";

  server.send(200, "text/css", css);
}

void handleJS() {
  String js = R"JS(
let deviceInfo = {};
let statusCheckInterval;

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    loadDeviceInfo();
    scanNetworks();
});

async function loadDeviceInfo() {
    try {
        const response = await fetch('/api/info');
        deviceInfo = await response.json();
        document.getElementById('deviceName').textContent = deviceInfo.deviceName;
    } catch (error) {
        console.error('Failed to load device info:', error);
    }
}

async function scanNetworks() {
    const ssidSelect = document.getElementById('ssid');
    const scanBtn = document.querySelector('.scan-btn');

    ssidSelect.innerHTML = '<option value="">Scanning networks...</option>';
    scanBtn.textContent = '🔄 Scanning...';
    scanBtn.disabled = true;

    try {
        const response = await fetch('/api/scan');
        const data = await response.json();

        ssidSelect.innerHTML = '<option value="">Select a network...</option>';

        data.networks.forEach(network => {
            if (network.ssid && network.ssid.trim() !== '') {
                const option = document.createElement('option');
                option.value = network.ssid;
                option.textContent = `${network.ssid} (${network.rssi}dBm) ${network.encryption === 'open' ? '🔓' : '🔒'}`;
                ssidSelect.appendChild(option);
            }
        });

        showStatus('Found ' + data.networks.length + ' networks', 'info');
    } catch (error) {
        console.error('Network scan failed:', error);
        showStatus('Failed to scan networks. Please try again.', 'error');
        ssidSelect.innerHTML = '<option value="">Scan failed - try again</option>';
    } finally {
        scanBtn.textContent = '🔄 Refresh';
        scanBtn.disabled = false;
    }
}

function updatePassword() {
    const ssidSelect = document.getElementById('ssid');
    const passwordInput = document.getElementById('password');

    if (ssidSelect.value) {
        passwordInput.focus();
    }
}

function togglePassword() {
    const passwordInput = document.getElementById('password');
    const toggleBtn = document.querySelector('.toggle-btn');

    if (passwordInput.type === 'password') {
        passwordInput.type = 'text';
        toggleBtn.textContent = '🙈';
    } else {
        passwordInput.type = 'password';
        toggleBtn.textContent = '👁️';
    }
}

async function configureWiFi() {
    const ssid = document.getElementById('ssid').value;
    const password = document.getElementById('password').value;
    const setupBtn = document.getElementById('setupBtn');
    const progressDiv = document.getElementById('progress');
    const progressBar = document.querySelector('.progress-bar');

    if (!ssid) {
        showStatus('Please select a WiFi network', 'error');
        return;
    }

    setupBtn.disabled = true;
    setupBtn.textContent = 'Connecting...';
    progressDiv.style.display = 'block';
    progressBar.style.width = '0%';

    try {
        const response = await fetch('/api/configure', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ ssid, password })
        });

        const result = await response.json();

        if (response.ok) {
            showStatus('Connecting to ' + ssid + '...', 'info');
            startStatusCheck();
        } else {
            throw new Error(result.error || 'Configuration failed');
        }
    } catch (error) {
        console.error('Configuration failed:', error);
        showStatus('Failed to configure WiFi: ' + error.message, 'error');
        resetForm();
    }
}

function startStatusCheck() {
    let progress = 0;
    const progressBar = document.querySelector('.progress-bar');

    statusCheckInterval = setInterval(async () => {
        try {
            const response = await fetch('/api/status');
            const status = await response.json();

            if (status.state === 'connected') {
                clearInterval(statusCheckInterval);
                progressBar.style.width = '100%';
                showStatus('✅ Connected successfully! Device is now online.', 'success');

                setTimeout(() => {
                    showStatus('You can now close this page and return to the app.', 'success');
                }, 2000);

            } else if (status.state === 'error') {
                clearInterval(statusCheckInterval);
                showStatus('❌ Connection failed. Please check your password and try again.', 'error');
                resetForm();

            } else if (status.state === 'connecting') {
                progress = Math.min(progress + 5, 90);
                progressBar.style.width = progress + '%';
                showStatus(status.message || 'Connecting...', 'info');
            }
        } catch (error) {
            console.error('Status check failed:', error);
        }
    }, 1000);

    // Timeout after 45 seconds
    setTimeout(() => {
        if (statusCheckInterval) {
            clearInterval(statusCheckInterval);
            showStatus('Connection timeout. Please try again.', 'error');
            resetForm();
        }
    }, 45000);
}

function resetForm() {
    const setupBtn = document.getElementById('setupBtn');
    const progressDiv = document.getElementById('progress');

    setupBtn.disabled = false;
    setupBtn.textContent = 'Connect to WiFi';
    progressDiv.style.display = 'none';
}

function showStatus(message, type) {
    const statusDiv = document.getElementById('status');
    statusDiv.textContent = message;
    statusDiv.className = 'status ' + type;
    statusDiv.style.display = 'block';
}
  )JS";

  server.send(200, "application/javascript", js);
}
