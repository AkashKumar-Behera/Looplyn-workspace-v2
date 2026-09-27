@echo off
title Looplyn V2 - Backend ^& DB Tunnel (Port 8000)
color 0A
cd /d "%~dp0"

echo =========================================================
echo       Starting Cloudflare DB Tunnel + Backend (Port 8000)
echo =========================================================
echo.

echo [1/2] Connecting Cloudflare Database Tunnel (postgress.looplyn.tech -> localhost:8689)...
start "LooplynTunnel" cloudflared access tcp --hostname postgress.looplyn.tech --url localhost:8689

timeout /t 3 /nobreak >nul

cd server
if not exist node_modules (
    echo [2/2] Installing backend dependencies...
    call npm install
)

echo [2/2] Launching Looplyn V2 Backend API on Port 8000...
npm run dev

pause
