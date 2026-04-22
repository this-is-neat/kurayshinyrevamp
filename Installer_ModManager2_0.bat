@echo off
setlocal enabledelayedexpansion
title KIF Mod Manager 2.0 Installer
color 0A

echo ============================================
echo    KIF Mod Manager 2.0 - Installer
echo ============================================
echo.
echo This will overwrite your existing Mod Manager
echo with the latest version from:
echo   https://github.com/KIF-Mods/mod-manager
echo.

:: Must be run from game root
if not exist "Game.exe" (
    if not exist "Game.rxproj" (
        color 0C
        echo [ERROR] Game.exe not found in current folder.
        echo.
        echo Place this .bat inside your KIF Multiplayer game
        echo folder (next to Game.exe^) and run it again.
        echo.
        pause
        exit /b 1
    )
)

set "GAME_ROOT=%~dp0"
if "%GAME_ROOT:~-1%"=="\" set "GAME_ROOT=%GAME_ROOT:~0,-1%"

set "SEVENZ=%GAME_ROOT%\REQUIRED_BY_INSTALLER_UPDATER\7z.exe"
if not exist "%SEVENZ%" (
    color 0C
    echo [ERROR] Bundled 7z.exe not found at:
    echo   %SEVENZ%
    echo.
    echo Your KIF install appears to be incomplete.
    pause
    exit /b 1
)

echo [OK] Game folder detected.
echo [OK] Found bundled 7z.exe
echo.

set "DOWNLOAD_URL=https://raw.githubusercontent.com/KIF-Mods/mod-manager/main/KIF-ModManager.7z"
set "TEMP_FILE=%TEMP%\KIF-ModManager.7z"

if exist "%TEMP_FILE%" del "%TEMP_FILE%" >NUL 2>&1

echo ============================================
echo  Step 1: Downloading...
echo ============================================
echo.

where curl >NUL 2>&1
if %errorlevel%==0 (
    curl --ssl-no-revoke -L --progress-bar -o "%TEMP_FILE%" "%DOWNLOAD_URL%"
    goto :download_check
)

echo Using PowerShell to download...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_FILE%'" 2>&1

:download_check
if not exist "%TEMP_FILE%" (
    color 0C
    echo.
    echo [ERROR] Download failed. Check your internet connection.
    echo.
    echo Manual download:
    echo   %DOWNLOAD_URL%
    echo.
    pause
    exit /b 1
)

for %%A in ("%TEMP_FILE%") do set "FILESIZE=%%~zA"
if %FILESIZE% LSS 1024 (
    color 0C
    echo.
    echo [ERROR] Downloaded file is too small (%FILESIZE% bytes^).
    echo The archive may not exist on the server yet.
    del "%TEMP_FILE%" >NUL 2>&1
    pause
    exit /b 1
)

echo.
echo [OK] Downloaded successfully.
echo.

echo ============================================
echo  Step 2: Extracting into game folder...
echo ============================================
echo.
echo (existing Mod Manager files will be overwritten^)
echo.

"%SEVENZ%" x -y -o"%GAME_ROOT%" "%TEMP_FILE%"

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERROR] Extraction failed.
    del "%TEMP_FILE%" >NUL 2>&1
    pause
    exit /b 1
)

echo.
echo [OK] Extracted successfully.
echo.

echo Cleaning up...
del "%TEMP_FILE%" >NUL 2>&1

echo.
color 0A
echo ============================================
echo  SUCCESS! Mod Manager 2.0 installed!
echo ============================================
echo.
echo Restart the game to apply the changes.
echo.
pause
exit /b 0