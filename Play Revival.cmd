@echo off
title Play Revival
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NBA2K17-Switcher.ps1" -Play Revival
