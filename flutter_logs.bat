@echo off
echo 🔍 Capturando logs do Flutter...
echo.

:loop
flutter logs -d dba00bda 2>&1 | findstr /i "database\|crop\|variety\|foreign\|constraint\|error\|exception\|failed"
timeout /t 1 /nobreak > nul
goto loop
