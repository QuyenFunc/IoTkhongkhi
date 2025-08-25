@echo off
echo ========================================
echo   Getting SHA-1 Fingerprint for Android
echo ========================================
echo.

echo Trying multiple methods to find keytool...
echo.

REM Method 1: Try keytool from PATH
echo Method 1: Checking if keytool is in PATH...
where keytool >nul 2>&1
if %errorlevel% == 0 (
    echo Found keytool in PATH!
    echo Getting DEBUG SHA-1 fingerprint...
    keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM Method 2: Try Android Studio's JDK
echo Method 2: Trying Android Studio JDK...
set "ANDROID_STUDIO_JDK=%LOCALAPPDATA%\Android\Sdk\jre\bin\keytool.exe"
if exist "%ANDROID_STUDIO_JDK%" (
    echo Found keytool in Android Studio JDK!
    echo Getting DEBUG SHA-1 fingerprint...
    "%ANDROID_STUDIO_JDK%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM Method 3: Try newer Android Studio JDK path
echo Method 3: Trying newer Android Studio JDK path...
set "ANDROID_STUDIO_JDK2=%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe"
if exist "%ANDROID_STUDIO_JDK2%" (
    echo Found keytool in Android Studio JBR!
    echo Getting DEBUG SHA-1 fingerprint...
    "%ANDROID_STUDIO_JDK2%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM Method 4: Try system Java
echo Method 4: Trying system Java installation...
set "JAVA_KEYTOOL=%JAVA_HOME%\bin\keytool.exe"
if exist "%JAVA_KEYTOOL%" (
    echo Found keytool in JAVA_HOME!
    echo Getting DEBUG SHA-1 fingerprint...
    "%JAVA_KEYTOOL%" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
    goto :end
)

REM Method 5: Search common Java installation paths
echo Method 5: Searching common Java paths...
for /d %%i in ("C:\Program Files\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        echo Found keytool in %%i!
        echo Getting DEBUG SHA-1 fingerprint...
        "%%i\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        goto :end
    )
)

for /d %%i in ("C:\Program Files (x86)\Java\jdk*") do (
    if exist "%%i\bin\keytool.exe" (
        echo Found keytool in %%i!
        echo Getting DEBUG SHA-1 fingerprint...
        "%%i\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        goto :end
    )
)

echo.
echo ❌ ERROR: Could not find keytool!
echo.
echo 📋 SOLUTIONS:
echo 1. Install Android Studio (includes keytool)
echo 2. Install Java JDK
echo 3. Use Flutter command instead (see below)
echo.
echo 🔧 ALTERNATIVE: Use Flutter command
echo Run this command in terminal:
echo flutter build apk --debug
echo Then check: android\app\build\outputs\flutter-apk\
echo.

:end
echo.
echo ========================================
echo Copy the SHA1 fingerprint from above
echo and add it to Firebase Console
echo ========================================
echo.
pause
