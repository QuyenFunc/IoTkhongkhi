#ifndef _THRESHOLD_DISPLAY_H_
#define _THRESHOLD_DISPLAY_H_

#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

// Threshold structure definition
struct Thresholds {
    float tempMin;
    float tempMax;
    bool tempEnabled;
    float humMin;
    float humMax;
    bool humEnabled;
    float pm25Min;
    float pm25Max;
    bool pm25Enabled;
};

// Function to display threshold update notification on OLED
void displayThresholdUpdate(Adafruit_SH1106G &oled, struct Thresholds &thresholds) {
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SH110X_WHITE);
    
    // Title
    oled.setCursor(0, 5);
    oled.print("CAP NHAT NGUONG");
    
    // Temperature thresholds
    oled.setCursor(0, 20);
    oled.print("Temp: ");
    oled.print(thresholds.tempMin, 1);
    oled.print("-");
    oled.print(thresholds.tempMax, 1);
    oled.print("C");
    if (!thresholds.tempEnabled) {
        oled.print(" (OFF)");
    }
    
    // Humidity thresholds
    oled.setCursor(0, 32);
    oled.print("Humi: ");
    oled.print(thresholds.humMin, 1);
    oled.print("-");
    oled.print(thresholds.humMax, 1);
    oled.print("%");
    if (!thresholds.humEnabled) {
        oled.print(" (OFF)");
    }
    
    // PM2.5 thresholds
    oled.setCursor(0, 44);
    oled.print("PM2.5: ");
    oled.print(thresholds.pm25Min, 0);
    oled.print("-");
    oled.print(thresholds.pm25Max, 0);
    if (!thresholds.pm25Enabled) {
        oled.print(" (OFF)");
    }
    
    // Status message
    oled.setCursor(0, 56);
    oled.print(">>> DA CAP NHAT <<<");
    
    oled.display();
}

// Function to display threshold loading status
void displayThresholdLoading(Adafruit_SH1106G &oled) {
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SH110X_WHITE);
    
    oled.setCursor(0, 20);
    oled.print("Dang tai nguong");
    oled.setCursor(0, 32);
    oled.print("tu Firebase...");
    
    oled.display();
}

// Function to display threshold error
void displayThresholdError(Adafruit_SH1106G &oled) {
    oled.clearDisplay();
    oled.setTextSize(1);
    oled.setTextColor(SH110X_WHITE);
    
    oled.setCursor(0, 20);
    oled.print("Loi tai nguong!");
    oled.setCursor(0, 32);
    oled.print("Su dung mac dinh");
    
    oled.display();
}

#endif
