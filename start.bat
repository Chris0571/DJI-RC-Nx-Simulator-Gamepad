@echo off
setlocal
title DJI RC-Nx Simulator

:: Always run from the script directory
cd /d "%~dp0"

:: 1. Check if Python is installed
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python was not found in your PATH!
    echo Please install Python and ensure "Add Python to PATH" is checked during setup.
    echo Download: https://www.python.org/downloads/
    goto :error
)

:: 2. Use virtual environment if present (.venv or venv), otherwise system python
if exist ".venv\Scripts\python.exe" (
    set "PYTHON_EXE=.venv\Scripts\python.exe"
) else if exist "venv\Scripts\python.exe" (
    set "PYTHON_EXE=venv\Scripts\python.exe"
) else (
    set "PYTHON_EXE=python"
)

:: 3. Launch the main script and forward any arguments
echo Starting DJI RC-Nx Simulator...
"%PYTHON_EXE%" main.py %*

:: If exit code was not 0, pause so the user can read the error message
if %ERRORLEVEL% neq 0 goto :error

exit /b 0

:error
echo.
echo Press any key to exit...
pause >nul
exit /b 1
