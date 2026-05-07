@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_pokengine_pack.ps1" -SpecPath "%~dp0config\community_packs\mongratis_community_sampler.json" -Force
pause
