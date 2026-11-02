@echo off
title NBA 2K17 Switcher - give Back2Back its own game folder
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NBA2K17-Switcher.ps1" -Split
