# 🚀 Quick Start - Cấu Trúc Tối Ưu

## ESP32 Setup
```cpp
// Upload file: esp32/optimized_air_monitor.ino
// Cấu hình WiFi và Firebase trong code
```

## Android App Setup
```bash
# Sử dụng main tối ưu
cp lib/main_optimized.dart lib/main.dart

# Chạy app
flutter run
```

## Firebase Setup
```bash
# Deploy rules
dart run scripts/deploy_optimized_structure.dart
firebase deploy --only database
```

## Cấu Trúc Firebase Mới
```
/air_monitor/
├── latest_data     # Dữ liệu real-time (5s)
├── history         # Lịch sử (5 phút)
├── status          # Trạng thái thiết bị
├── control         # Điều khiển LED
└── thresholds      # Ngưỡng cảnh báo
```

## Tính Năng
- ✅ Real-time monitoring
- ✅ LED control từ xa
- ✅ Biểu đồ lịch sử
- ✅ Cảnh báo thông minh
- ✅ Không cần đăng nhập

## Cảm Biến ESP32
- DHT11: Nhiệt độ, độ ẩm
- GP2Y1010AU0F: Bụi PM2.5
- LED: Điều khiển từ app
- Buzzer: Phản hồi lệnh
