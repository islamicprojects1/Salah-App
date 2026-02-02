@echo off
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -list -v -keystore "C:\Users\moere\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
echo.
echo ========================================================
echo COPY the SHA1 fingerprint above and add it to Firebase.
echo ========================================================
