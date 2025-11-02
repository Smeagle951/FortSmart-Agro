@echo off
echo 🔍 Monitorando logs do aplicativo FortSmart Agro...
echo.
echo Procurando por mensagens relacionadas a:
echo - Database
echo - Crop
echo - Variety
echo - Foreign Key
echo - Constraint
echo - Error
echo.
echo Pressione Ctrl+C para parar
echo.

:loop
adb logcat -d | findstr /i "database crop variety foreign constraint error sqlite"
timeout /t 2 /nobreak > nul
goto loop
