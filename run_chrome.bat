@echo off
echo Starting Flutter Web build...
flutter clean
flutter pub get
flutter run -d chrome
pause
