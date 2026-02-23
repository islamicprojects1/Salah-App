@echo off
setlocal

:: Try keytool from PATH first
where keytool >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "KEYTOOL=keytool"
    goto :run
)

:: Try Android Studio JBR (common install paths)
for %%p in (
    "%LOCALAPPDATA%\Android\Sdk\jbr\bin\keytool.exe"
    "%PROGRAMFILES%\Android\Android Studio\jbr\bin\keytool.exe"
    "%PROGRAMFILES%\Android\Android Studio1\jbr\bin\keytool.exe"
) do (
    if exist %%p (
        set "KEYTOOL=%%~p"
        goto :run
    )
)

:: Try JAVA_HOME
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        set "KEYTOOL=%JAVA_HOME%\bin\keytool.exe"
        goto :run
    )
)

echo ERROR: keytool not found. Install Android Studio or Java JDK.
exit /b 1

:run
set "KEYSTORE=%USERPROFILE%\.android\debug.keystore"

if not exist "%KEYSTORE%" (
    echo ERROR: Debug keystore not found at %KEYSTORE%
    echo Run the app once from Android Studio or run: flutter run
    exit /b 1
)

echo Getting SHA-1 for debug keystore...
echo.
"%KEYTOOL%" -list -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android 2>nul
if %ERRORLEVEL% NEQ 0 (
    "%KEYTOOL%" -list -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android
)

echo.
echo ========================================================
echo COPY the SHA1 fingerprint above and add it to Firebase.
echo Firebase Console -^> Project Settings -^> Your apps -^> Add fingerprint
echo ========================================================
