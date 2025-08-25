@echo off
echo ========================================
echo   Getting SHA-1 using Gradle (Alternative)
echo ========================================
echo.

echo This method uses Gradle to get SHA-1 fingerprint
echo.

cd android
echo Running Gradle signing report...
echo.

REM Try gradlew first
if exist "gradlew.bat" (
    echo Using gradlew.bat...
    gradlew.bat signingReport
) else (
    echo gradlew.bat not found, trying gradle...
    gradle signingReport
)

echo.
echo ========================================
echo Look for "SHA1:" in the output above
echo Copy that fingerprint to Firebase Console
echo ========================================
echo.

cd ..
pause
