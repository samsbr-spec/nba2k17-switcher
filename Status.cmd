@echo off
title NBA 2K17 Switcher - status
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NBA2K17-Switcher.ps1" -Status
