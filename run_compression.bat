@echo off
setlocal

REM === CONFIGURATION ===
set "HB_PATH=E:\Video Capture\Utilities\HandBrakeCLI.exe"
set "INPUT_DIR=H:\DTS Backup\Adrienne Lee\VHS-Orig"
set "OUTPUT_DIR=H:\DTS Backup\Adrienne Lee\VHS"

REM === Call PowerShell script with each path wrapped in quotes ===
powershell -ExecutionPolicy Bypass -File "E:\Video Capture\Utilities\BatchCompress_MP4_RF20.ps1" "%HB_PATH%" "%INPUT_DIR%" "%OUTPUT_DIR%"

pause
