@echo off
echo ========================================
echo   Getting SHA-1 using Flutter Build
echo ========================================
echo.

echo This method builds the app and shows signing info
echo.

echo Step 1: Building debug APK...
flutter build apk --debug

echo.
echo Step 2: Checking if debug keystore exists...
if exist "%USERPROFILE%\.android\debug.keystore" (
    echo ✅ Debug keystore found at: %USERPROFILE%\.android\debug.keystore
    echo.
    echo Step 3: Trying to find keytool in Flutter installation...
    
    REM Try Flutter's bundled Java
    for /f "tokens=*" %%i in ('where flutter') do set FLUTTER_PATH=%%i
    for %%i in ("%FLUTTER_PATH%") do set FLUTTER_DIR=%%~dpi
    
    set "FLUTTER_JAVA=%FLUTTER_DIR%bin\cache\artifacts\engine\windows-x64\flutter_tester.exe"
    
    echo Flutter directory: %FLUTTER_DIR%
    echo.
    
    REM Alternative: Use Android Studio's keytool if available
    if exist "%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe" (
        echo Found Android Studio keytool!
        "%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    ) else if exist "%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe" (
        echo Found Android Studio keytool (older version)!
        "%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    ) else (
        echo ❌ Could not find keytool
        echo.
        echo 📋 MANUAL SOLUTION:
        echo 1. Open Android Studio
        echo 2. Go to Build ^> Generate Signed Bundle / APK
        echo 3. Choose APK ^> Next
        echo 4. Click "Create new..." keystore
        echo 5. The SHA-1 will be shown in the process
        echo.
        echo OR install Java JDK and try again
    )
) else (
    echo ❌ Debug keystore not found!
    echo.
    echo 📋 SOLUTION:
    echo 1. Run: flutter build apk --debug
    echo 2. Or create new project to generate keystore
)

echo.
echo ========================================
echo Look for "SHA1:" in the output above
echo Copy that fingerprint to Firebase Console
echo ========================================
echo.
pause
