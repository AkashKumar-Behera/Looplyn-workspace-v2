@echo off
echo ===================================================
echo           Starting Looplyn V2 Dev Server
echo ===================================================
echo.

cd /d "C:\Development\looplyn-v2\server"
start "Looplyn Server (Hono API :5000)" cmd /k "npm run dev"

echo Server started at http://localhost:5000
echo You can test health at: http://localhost:5000/health
echo.
echo To run Flutter Client:
echo cd C:\Development\looplyn-v2\client_app
echo flutter run -d chrome (or flutter run -d windows)
echo ===================================================
pause
