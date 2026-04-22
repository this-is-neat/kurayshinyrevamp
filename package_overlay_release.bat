@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0package_overlay_release.ps1" %*
