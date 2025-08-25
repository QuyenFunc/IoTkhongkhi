@echo off
echo Starting Flutter Android build...
flutter clean
flutter pub get
flutter run -d emulator-5554
pause
