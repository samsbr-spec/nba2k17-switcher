@echo off
title NBA 2K17 Switcher - check for updates
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NBA2K17-Switcher.ps1" -Update
