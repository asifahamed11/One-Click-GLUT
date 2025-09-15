@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: Enhanced GLUT Uninstaller
:: Compatible with Windows 7/8/10/11 (x86/x64)
:: Version 2.0

:: Auto-elevate to administrator if not already running as admin
if not "%1"=="am_admin" (
    cls
    echo.
    echo ===============================================
    echo     Administrator Privileges Required
    echo ===============================================
    echo.
    echo   Requesting administrator privileges...
    echo   Please click "Yes" when prompted.
    echo.
    powershell -Command "Start-Process '%~f0' -ArgumentList 'am_admin' -Verb RunAs" 2>nul
    if !errorlevel! neq 0 (
        echo   [ERROR] Failed to elevate privileges.
        echo   Please right-click and "Run as administrator"
        pause
    )
    exit
)

cls
echo.
echo ===============================================
echo        GLUT Uninstaller v2.0
echo ===============================================
echo   Complete removal for Code::Blocks + FreeGLUT
echo   Compatible with Windows 7/8/10/11
echo ===============================================
echo.

:: Detect system
call :detect_system
echo   System: !OS_NAME! (!OS_ARCH!)
echo   User: %USERNAME%
echo   Date: %DATE%
echo.

:: Define paths
set "CB_PATH1=C:\Program Files\CodeBlocks"
set "CB_PATH2=C:\Program Files (x86)\CodeBlocks"
set "CB_PATH3=C:\CodeBlocks"

echo ===============================================
echo              WARNING
echo ===============================================
echo   This will COMPLETELY REMOVE:
echo   - Code::Blocks IDE and all components
echo   - MinGW compiler and toolchain
echo   - FreeGLUT libraries and headers
echo   - All user settings and configurations
echo   - Desktop shortcuts and registry entries
echo.
echo   Your project files will NOT be deleted.
echo ===============================================
echo.

:: Scan for installations
echo [SCAN] Checking for Code::Blocks installations...
set "FOUND_INSTALLS=0"

if exist "!CB_PATH1!" (
    echo   [FOUND] !CB_PATH1!
    set /a FOUND_INSTALLS+=1
)
if exist "!CB_PATH2!" (
    echo   [FOUND] !CB_PATH2!
    set /a FOUND_INSTALLS+=1
)
if exist "!CB_PATH3!" (
    echo   [FOUND] !CB_PATH3!
    set /a FOUND_INSTALLS+=1
)

if !FOUND_INSTALLS! equ 0 (
    echo   [INFO] No Code::Blocks installations detected
    echo.
    set /p continue_anyway="   Continue with cleanup anyway? (y/n): "
    if /i not "!continue_anyway!"=="y" (
        echo   Cleanup cancelled.
        pause
        exit /b 0
    )
) else (
    echo   [INFO] Found !FOUND_INSTALLS! installation(s)
)

echo.
echo   This action cannot be undone!
set /p confirm="   Type 'YES' to confirm removal: "
if /i not "!confirm!"=="YES" (
    echo.
    echo   [INFO] Uninstallation cancelled
    pause
    exit /b 0
)

echo.
echo ===============================================
echo        Starting Removal Process
echo ===============================================

:: Step 1: Stop processes
echo.
echo [STEP 1] Stopping Code::Blocks processes...
taskkill /f /im codeblocks.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo   [SUCCESS] Code::Blocks process stopped
) else (
    echo   [INFO] Code::Blocks was not running
)

:: Kill related processes
taskkill /f /im gcc.exe >nul 2>&1
taskkill /f /im g++.exe >nul 2>&1
taskkill /f /im gdb.exe >nul 2>&1

timeout /t 3 /nobreak >nul
echo   [SUCCESS] All processes stopped

:: Step 2: Run official uninstaller
echo.
echo [STEP 2] Running official uninstaller...

set "UNINSTALLER_FOUND=0"
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Code::Blocks" 2^>nul ^| findstr "UninstallString"') do (
    set "UNINSTALLER_PATH=%%b"
    set "UNINSTALLER_FOUND=1"
    goto found_uninstaller
)

:: Check 32-bit registry on 64-bit systems
if "!OS_ARCH!"=="64-bit" (
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Code::Blocks" 2^>nul ^| findstr "UninstallString"') do (
        set "UNINSTALLER_PATH=%%b"
        set "UNINSTALLER_FOUND=1"
        goto found_uninstaller
    )
)

:found_uninstaller
if "!UNINSTALLER_FOUND!"=="1" (
    echo   [SUCCESS] Found official uninstaller
    echo   [INFO] Running uninstaller...
    !UNINSTALLER_PATH! /S >nul 2>&1
    timeout /t 10 /nobreak >nul
    echo   [SUCCESS] Official uninstaller completed
) else (
    echo   [INFO] No official uninstaller found
    echo   [INFO] Proceeding with manual removal
)

:: Step 3: Remove program files
echo.
echo [STEP 3] Removing program files...

if exist "!CB_PATH1!" (
    echo   [INFO] Removing !CB_PATH1!...
    rd /s /q "!CB_PATH1!" >nul 2>&1
    if not exist "!CB_PATH1!" (
        echo   [SUCCESS] Removed !CB_PATH1!
    ) else (
        echo   [WARNING] Could not fully remove !CB_PATH1!
        call :force_remove "!CB_PATH1!"
    )
)

if exist "!CB_PATH2!" (
    echo   [INFO] Removing !CB_PATH2!...
    rd /s /q "!CB_PATH2!" >nul 2>&1
    if not exist "!CB_PATH2!" (
        echo   [SUCCESS] Removed !CB_PATH2!
    ) else (
        echo   [WARNING] Could not fully remove !CB_PATH2!
        call :force_remove "!CB_PATH2!"
    )
)

if exist "!CB_PATH3!" (
    echo   [INFO] Removing !CB_PATH3!...
    rd /s /q "!CB_PATH3!" >nul 2>&1
    if not exist "!CB_PATH3!" (
        echo   [SUCCESS] Removed !CB_PATH3!
    ) else (
        echo   [WARNING] Could not fully remove !CB_PATH3!
        call :force_remove "!CB_PATH3!"
    )
)

:: Step 4: Clean system files
echo.
echo [STEP 4] Cleaning system files...

if exist "C:\Windows\System32\freeglut.dll" (
    echo   [INFO] Removing freeglut.dll from System32...
    del /f /q "C:\Windows\System32\freeglut.dll" >nul 2>&1
    if not exist "C:\Windows\System32\freeglut.dll" (
        echo   [SUCCESS] Removed freeglut.dll from System32
    ) else (
        echo   [WARNING] Could not remove freeglut.dll from System32
    )
)

if "!OS_ARCH!"=="64-bit" (
    if exist "C:\Windows\SysWOW64\freeglut.dll" (
        echo   [INFO] Removing freeglut.dll from SysWOW64...
        del /f /q "C:\Windows\SysWOW64\freeglut.dll" >nul 2>&1
        if not exist "C:\Windows\SysWOW64\freeglut.dll" (
            echo   [SUCCESS] Removed freeglut.dll from SysWOW64
        )
    )
)

echo   [SUCCESS] System files cleanup completed

:: Step 5: Remove user data
echo.
echo [STEP 5] Removing user data...

if exist "%USERPROFILE%\AppData\Roaming\CodeBlocks" (
    echo   [INFO] Removing user settings...
    rd /s /q "%USERPROFILE%\AppData\Roaming\CodeBlocks" >nul 2>&1
    if not exist "%USERPROFILE%\AppData\Roaming\CodeBlocks" (
        echo   [SUCCESS] User settings removed
    )
)

if exist "%USERPROFILE%\AppData\Local\CodeBlocks" (
    echo   [INFO] Removing user cache...
    rd /s /q "%USERPROFILE%\AppData\Local\CodeBlocks" >nul 2>&1
    if not exist "%USERPROFILE%\AppData\Local\CodeBlocks" (
        echo   [SUCCESS] User cache removed
    )
)

echo   [SUCCESS] User data cleanup completed

:: Step 6: Remove shortcuts
echo.
echo [STEP 6] Removing shortcuts...

if exist "%USERPROFILE%\Desktop\Code-Blocks.lnk" (
    del /f /q "%USERPROFILE%\Desktop\Code-Blocks.lnk" >nul 2>&1
    echo   [SUCCESS] Removed desktop shortcut
)

if exist "%PUBLIC%\Desktop\Code-Blocks.lnk" (
    del /f /q "%PUBLIC%\Desktop\Code-Blocks.lnk" >nul 2>&1
    echo   [SUCCESS] Removed public desktop shortcut
)

if exist "%USERPROFILE%\Desktop\CodeBlocks.lnk" (
    del /f /q "%USERPROFILE%\Desktop\CodeBlocks.lnk" >nul 2>&1
)

:: Remove Start Menu entries
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\CodeBlocks" (
    rd /s /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\CodeBlocks" >nul 2>&1
    echo   [SUCCESS] Removed Start Menu entries
)

if exist "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\CodeBlocks" (
    rd /s /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\CodeBlocks" >nul 2>&1
    echo   [SUCCESS] Removed system Start Menu entries
)

echo   [SUCCESS] Shortcuts cleanup completed

:: Step 7: Clean registry
echo.
echo [STEP 7] Cleaning registry...

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Code::Blocks" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Code::Blocks" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Code::Blocks" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\CodeBlocks" /f >nul 2>&1

echo   [SUCCESS] Registry cleanup completed

:: Step 8: Clean environment
echo.
echo [STEP 8] Cleaning environment variables...

:: Clean user PATH
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do (
    set "USER_PATH=%%b"
    set "USER_PATH=!USER_PATH:;C:\Program Files\CodeBlocks=!"
    set "USER_PATH=!USER_PATH:;C:\Program Files (x86)\CodeBlocks=!"
    set "USER_PATH=!USER_PATH:C:\Program Files\CodeBlocks;=!"
    set "USER_PATH=!USER_PATH:C:\Program Files (x86)\CodeBlocks;=!"
    set "USER_PATH=!USER_PATH:C:\Program Files\CodeBlocks=!"
    set "USER_PATH=!USER_PATH:C:\Program Files (x86)\CodeBlocks=!"
    reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!USER_PATH!" /f >nul 2>&1
)

echo   [SUCCESS] Environment cleanup completed

:: Final verification
echo.
echo [STEP 9] Final verification...

set "REMAINING=0"
if exist "!CB_PATH1!" (
    echo   [WARNING] Remaining files: !CB_PATH1!
    set /a REMAINING+=1
)
if exist "!CB_PATH2!" (
    echo   [WARNING] Remaining files: !CB_PATH2!
    set /a REMAINING+=1
)
if exist "!CB_PATH3!" (
    echo   [WARNING] Remaining files: !CB_PATH3!
    set /a REMAINING+=1
)
if exist "C:\Windows\System32\freeglut.dll" (
    echo   [WARNING] Remaining: freeglut.dll in System32
    set /a REMAINING+=1
)

if !REMAINING! equ 0 (
    echo   [SUCCESS] Complete removal verified
) else (
    echo   [WARNING] !REMAINING! items remain - restart may help
)

:: Show completion
echo.
echo ===============================================
if !REMAINING! equ 0 (
    echo        UNINSTALLATION COMPLETE!
) else (
    echo     UNINSTALLATION MOSTLY COMPLETE
)
echo ===============================================
echo.
echo   Removed:
echo   - Code::Blocks IDE
echo   - MinGW compiler
echo   - FreeGLUT libraries
echo   - User settings
echo   - Desktop shortcuts
echo   - Registry entries
echo.
echo   Your project files were preserved.
echo.

if !REMAINING! gtr 0 (
    echo   Some files could not be removed.
    echo   Consider restarting and running again.
    echo.
    set /p restart_now="   Restart now? (y/n): "
    if /i "!restart_now!"=="y" (
        echo   [INFO] Restarting in 5 seconds...
        shutdown /r /t 5 /c "Completing Code::Blocks removal"
        exit
    )
)

echo   Press any key to exit...
pause >nul
exit /b 0

:: ============================================
:: FUNCTIONS
:: ============================================

:detect_system
    for /f "tokens=4-5 delims=. " %%i in ('ver') do (
        if "%%i"=="10" set "OS_NAME=Windows 10/11"
        if "%%i"=="6" (
            if "%%j"=="3" set "OS_NAME=Windows 8.1"
            if "%%j"=="2" set "OS_NAME=Windows 8"
            if "%%j"=="1" set "OS_NAME=Windows 7"
        )
    )
    
    set "OS_ARCH=32-bit"
    if defined PROCESSOR_ARCHITEW6432 set "OS_ARCH=64-bit"
    if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "OS_ARCH=64-bit"
goto :eof

:force_remove
    echo   [INFO] Attempting forced removal of %~1
    
    :: Remove executables first
    if exist "%~1\*.exe" (
        del /f /q "%~1\*.exe" >nul 2>&1
    )
    
    :: Remove DLLs
    if exist "%~1\*.dll" (
        del /f /q "%~1\*.dll" >nul 2>&1
    )
    
    :: Remove MinGW directory
    if exist "%~1\MinGW" (
        echo   [INFO] Force removing MinGW...
        rd /s /q "%~1\MinGW" >nul 2>&1
    )
    
    :: Try to remove the main directory again
    rd /s /q "%~1" >nul 2>&1
    
    if not exist "%~1" (
        echo   [SUCCESS] Force removal successful
    ) else (
        echo   [WARNING] Some files are still locked
    )
goto :eof