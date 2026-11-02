@echo off
title Play Back2Back
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NBA2K17-Switcher.ps1" -Play Back2Back
