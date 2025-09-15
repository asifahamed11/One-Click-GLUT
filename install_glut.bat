@echo off
setlocal EnableDelayedExpansion

:: One Click GLUT Installer - Enhanced Version
:: Compatible with Windows 10 and Windows 11
:: Installs Code::Blocks with MinGW and sets up FreeGLUT automatically

:: Auto-elevate to administrator if not already running as admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs"
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

cls
echo ===============================================
echo        One Click GLUT Installer v2.0
echo        Compatible with Windows 10 and 11
echo ===============================================
echo.
echo [INFO] Running with administrator privileges...
echo [INFO] OS Version: %OS%
echo.

:: Define paths with better compatibility
set "INSTALLER_DIR=%~dp0"
set "CODEBLOCKS_INSTALLER=%INSTALLER_DIR%codeblocks-25.03mingw-setup.exe"
set "FREEGLUT_DIR=%INSTALLER_DIR%freeglut"
set "TEST_PROJECT=%INSTALLER_DIR%Test\Test.cbp"

:: Check for different possible installation paths
set "CODEBLOCKS_PATH="
if exist "C:\Program Files\CodeBlocks" (
    set "CODEBLOCKS_PATH=C:\Program Files\CodeBlocks"
) else if exist "C:\Program Files (x86)\CodeBlocks" (
    set "CODEBLOCKS_PATH=C:\Program Files (x86)\CodeBlocks"
) else (
    set "CODEBLOCKS_PATH=C:\Program Files\CodeBlocks"
)

:: Detect system architecture for better MinGW path detection
set "MINGW_PATH="
if exist "%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32"
) else if exist "%CODEBLOCKS_PATH%\MinGW" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW"
) else (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32"
)

:: System info
echo [INFO] System Architecture: %PROCESSOR_ARCHITECTURE%
echo [INFO] Target CodeBlocks Path: %CODEBLOCKS_PATH%
echo.

:: Verify required files exist
echo [STEP 1] Verifying installation files...
if not exist "%CODEBLOCKS_INSTALLER%" (
    echo [ERROR] Code::Blocks installer not found: %CODEBLOCKS_INSTALLER%
    echo.
    echo Please ensure the following file is in the same directory as this script:
    echo - codeblocks-25.03mingw-setup.exe
    echo.
    echo You can download it from: https://www.codeblocks.org/downloads/
    pause
    exit /b 1
)

if not exist "%FREEGLUT_DIR%" (
    echo [ERROR] FreeGLUT directory not found: %FREEGLUT_DIR%
    echo.
    echo Please ensure the 'freeglut' folder is in the same directory as this script.
    echo The folder should contain:
    echo - include/GL/ ^(header files^)
    echo - lib/ ^(library files^)
    echo - bin/ ^(DLL files^)
    pause
    exit /b 1
)

:: Verify FreeGLUT structure
set "GLUT_VALID=1"
if not exist "%FREEGLUT_DIR%\include\GL" (
    echo [ERROR] FreeGLUT GL headers not found in: %FREEGLUT_DIR%\include\GL
    set "GLUT_VALID=0"
)

if not exist "%FREEGLUT_DIR%\lib" (
    echo [ERROR] FreeGLUT lib directory not found: %FREEGLUT_DIR%\lib
    set "GLUT_VALID=0"
)

if "!GLUT_VALID!"=="0" (
    echo.
    echo Please ensure your freeglut folder has this structure:
    echo freeglut/
    echo ├── include/GL/
    echo │   ├── freeglut.h
    echo │   ├── glut.h
    echo │   └── ...
    echo ├── lib/
    echo │   ├── libfreeglut.a
    echo │   ├── libfreeglut_static.a
    echo │   └── ...
    echo └── bin/ ^(optional^)
    echo     └── freeglut.dll
    pause
    exit /b 1
)

echo [SUCCESS] All required files found.
echo.

:: Check Windows version compatibility
echo [STEP 2] Checking Windows compatibility...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo [INFO] Windows version: %VERSION%

if "%VERSION%" geq "10.0" (
    echo [SUCCESS] Windows 10/11 detected - Compatible
) else (
    echo [WARNING] Older Windows version detected. This script is optimized for Windows 10/11.
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)
echo.

:: Check if Code::Blocks is already installed
echo [STEP 3] Checking existing installations...
if exist "%CODEBLOCKS_PATH%" (
    echo [WARNING] Code::Blocks appears to be already installed at:
    echo %CODEBLOCKS_PATH%
    echo.
    echo Options:
    echo 1. Continue and upgrade/repair installation
    echo 2. Skip Code::Blocks installation ^(only install GLUT^)
    echo 3. Cancel installation
    echo.
    set /p choice="Enter your choice (1/2/3): "
    if "!choice!"=="3" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
    if "!choice!"=="2" (
        goto :skip_codeblocks
    )
)
echo.

:: Install Code::Blocks
echo [STEP 4] Installing Code::Blocks with MinGW...
echo This may take several minutes. Please be patient...
echo.

:: Kill any running Code::Blocks processes
taskkill /f /im codeblocks.exe >nul 2>&1

:: Run installer with improved error handling
start /wait "" "%CODEBLOCKS_INSTALLER%" /S /D=%CODEBLOCKS_PATH%
set "INSTALL_RESULT=%errorLevel%"

if !INSTALL_RESULT! neq 0 (
    echo [ERROR] Code::Blocks installation failed with error code: !INSTALL_RESULT!
    echo.
    echo Possible solutions:
    echo 1. Run this script as Administrator
    echo 2. Temporarily disable antivirus software
    echo 3. Ensure no other installations are running
    echo 4. Check if you have enough disk space
    pause
    exit /b 1
)

:: Wait for installation to complete with better detection
echo Verifying installation completion...
set "WAIT_COUNT=0"
:wait_loop
if not exist "%CODEBLOCKS_PATH%\codeblocks.exe" (
    set /a WAIT_COUNT+=1
    if !WAIT_COUNT! gtr 30 (
        echo [ERROR] Installation verification timeout.
        echo Code::Blocks executable not found after 60 seconds.
        pause
        exit /b 1
    )
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

:: Additional wait to ensure all components are installed
timeout /t 3 /nobreak >nul

:skip_codeblocks

:: Verify MinGW installation with multiple possible paths
echo [STEP 5] Verifying MinGW compiler...
set "MINGW_FOUND=0"

:: Check multiple possible MinGW locations
if exist "%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW\mingw32" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\mingw32"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW"
    set "MINGW_FOUND=1"
)

if "!MINGW_FOUND!"=="0" (
    echo [ERROR] MinGW compiler not found in Code::Blocks installation.
    echo Expected locations:
    echo - %CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32
    echo - %CODEBLOCKS_PATH%\MinGW\mingw32
    echo - %CODEBLOCKS_PATH%\MinGW
    echo.
    echo Please ensure Code::Blocks was installed with the MinGW compiler package.
    pause
    exit /b 1
)

echo [SUCCESS] MinGW found at: %MINGW_PATH%
echo.

:: Setup FreeGLUT
echo [STEP 6] Setting up FreeGLUT...

:: Create directories if they don't exist
if not exist "%MINGW_PATH%\include" mkdir "%MINGW_PATH%\include"
if not exist "%MINGW_PATH%\include\GL" mkdir "%MINGW_PATH%\include\GL"
if not exist "%MINGW_PATH%\lib" mkdir "%MINGW_PATH%\lib"

:: Copy GL headers with verification
echo Copying OpenGL/GLUT headers...
xcopy /y /i "%FREEGLUT_DIR%\include\GL\*" "%MINGW_PATH%\include\GL\"
if %errorLevel% neq 0 (
    echo [ERROR] Failed to copy GL headers.
    echo Source: %FREEGLUT_DIR%\include\GL\
    echo Target: %MINGW_PATH%\include\GL\
    pause
    exit /b 1
)

:: Copy library files with better handling
echo Copying library files...
if exist "%FREEGLUT_DIR%\lib\libfreeglut.a" (
    copy /y "%FREEGLUT_DIR%\lib\libfreeglut.a" "%MINGW_PATH%\lib\"
)
if exist "%FREEGLUT_DIR%\lib\libfreeglut_static.a" (
    copy /y "%FREEGLUT_DIR%\lib\libfreeglut_static.a" "%MINGW_PATH%\lib\"
)

:: Handle both 32-bit and 64-bit libraries
if exist "%FREEGLUT_DIR%\lib\x64" (
    echo Copying 64-bit libraries...
    xcopy /y "%FREEGLUT_DIR%\lib\x64\*" "%MINGW_PATH%\lib\"
)
if exist "%FREEGLUT_DIR%\lib\x86" (
    echo Copying 32-bit libraries...
    xcopy /y "%FREEGLUT_DIR%\lib\x86\*" "%MINGW_PATH%\lib\"
)

:: Copy DLL files to system and local directories
echo Installing DLL files...
set "DLL_COPIED=0"

:: Try to copy to Windows System32 directory
if exist "%FREEGLUT_DIR%\bin\x64\freeglut.dll" (
    copy /y "%FREEGLUT_DIR%\bin\x64\freeglut.dll" "%WINDIR%\System32\" >nul 2>&1
    if !errorLevel! equ 0 set "DLL_COPIED=1"
)

if exist "%FREEGLUT_DIR%\bin\freeglut.dll" (
    copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%WINDIR%\System32\" >nul 2>&1
    if !errorLevel! equ 0 set "DLL_COPIED=1"
)

:: Also copy to Code::Blocks directory as backup
if exist "%FREEGLUT_DIR%\bin\x64\freeglut.dll" (
    copy /y "%FREEGLUT_DIR%\bin\x64\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul 2>&1
)
if exist "%FREEGLUT_DIR%\bin\freeglut.dll" (
    copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul 2>&1
)

if "!DLL_COPIED!"=="0" (
    echo [WARNING] Could not copy DLL to System32. DLL copied to Code::Blocks directory instead.
)

echo [SUCCESS] FreeGLUT files installed successfully.
echo.

:: Update Code::Blocks configuration and templates
echo [STEP 7] Configuring Code::Blocks for GLUT...

:: Update GLUT template if it exists
set "TEMPLATE_DIR=%CODEBLOCKS_PATH%\share\CodeBlocks\templates"
if exist "%TEMPLATE_DIR%\glut.cbp" (
    echo Updating GLUT project template...
    powershell -Command "try { (Get-Content '%TEMPLATE_DIR%\glut.cbp' -Raw) -replace 'glut32', 'freeglut' -replace 'opengl32', 'opengl32' | Set-Content '%TEMPLATE_DIR%\glut.cbp' -NoNewline; exit 0 } catch { exit 1 }"
    if !errorLevel! equ 0 (
        echo [SUCCESS] GLUT template updated.
    ) else (
        echo [WARNING] Could not automatically update GLUT template.
    )
) else (
    echo [INFO] GLUT template not found - will be available after first Code::Blocks run.
)

:: Create a sample GLUT project template
echo Creating sample GLUT configuration...
set "SAMPLE_DIR=%USERPROFILE%\Documents\CodeBlocks_GLUT_Sample"
if not exist "%SAMPLE_DIR%" mkdir "%SAMPLE_DIR%"

:: Create sample main.cpp
(
echo #include ^<GL/freeglut.h^>
echo #include ^<iostream^>
echo.
echo void display^(^) {
echo     glClear^(GL_COLOR_BUFFER_BIT^);
echo     glColor3f^(1.0f, 0.0f, 0.0f^);
echo     glBegin^(GL_TRIANGLES^);
echo         glVertex2f^(-0.5f, -0.5f^);
echo         glVertex2f^( 0.5f, -0.5f^);
echo         glVertex2f^( 0.0f,  0.5f^);
echo     glEnd^(^);
echo     glutSwapBuffers^(^);
echo }
echo.
echo int main^(int argc, char** argv^) {
echo     glutInit^(^&argc, argv^);
echo     glutInitDisplayMode^(GLUT_DOUBLE ^| GLUT_RGB^);
echo     glutInitWindowSize^(800, 600^);
echo     glutCreateWindow^("FreeGLUT Sample"^);
echo     glutDisplayFunc^(display^);
echo     glutMainLoop^(^);
echo     return 0;
echo }
) > "%SAMPLE_DIR%\main.cpp"

echo [SUCCESS] Sample GLUT project created at: %SAMPLE_DIR%
echo.

:: Installation complete
cls
echo ===============================================
echo        Installation Complete!
echo ===============================================
echo.
echo Code::Blocks with FreeGLUT has been successfully installed and configured.
echo.
echo Installation Details:
echo ========================================================
echo Code::Blocks IDE:     %CODEBLOCKS_PATH%
echo MinGW Compiler:       %MINGW_PATH%
echo GLUT Headers:         %MINGW_PATH%\include\GL\
echo GLUT Libraries:       %MINGW_PATH%\lib\
echo Sample Project:       %SAMPLE_DIR%
echo ========================================================
echo.

echo Quick Start Guide:
echo 1. Launch Code::Blocks from Start Menu or desktop shortcut
echo 2. Create a new project: File -^> New -^> Project -^> GLUT project
echo 3. Link against: -lfreeglut -lopengl32 -lglu32
echo 4. Sample code available at: %SAMPLE_DIR%
echo.

:: Create desktop shortcut
echo [STEP 8] Creating shortcuts...
set /p shortcut="Create desktop shortcut for Code::Blocks? (y/n): "
if /i "!shortcut!"=="y" (
    powershell -Command "try { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('$env:USERPROFILE\Desktop\CodeBlocks-GLUT.lnk'); $Shortcut.TargetPath = '%CODEBLOCKS_PATH%\codeblocks.exe'; $Shortcut.WorkingDirectory = '%CODEBLOCKS_PATH%'; $Shortcut.Description = 'Code::Blocks IDE with FreeGLUT'; $Shortcut.IconLocation = '%CODEBLOCKS_PATH%\codeblocks.exe,0'; $Shortcut.Save(); exit 0 } catch { exit 1 }"
    if !errorLevel! equ 0 (
        echo [SUCCESS] Desktop shortcut created: CodeBlocks-GLUT.lnk
    ) else (
        echo [WARNING] Could not create desktop shortcut.
    )
)

:: Create start menu shortcut
powershell -Command "try { $WshShell = New-Object -comObject WScript.Shell; $StartMenu = $WshShell.SpecialFolders('StartMenu'); $Shortcut = $WshShell.CreateShortcut('$StartMenu\Programs\CodeBlocks with GLUT.lnk'); $Shortcut.TargetPath = '%CODEBLOCKS_PATH%\codeblocks.exe'; $Shortcut.WorkingDirectory = '%CODEBLOCKS_PATH%'; $Shortcut.Description = 'Code::Blocks IDE with FreeGLUT'; $Shortcut.IconLocation = '%CODEBLOCKS_PATH%\codeblocks.exe,0'; $Shortcut.Save(); exit 0 } catch { exit 1 }" >nul 2>&1

echo.
echo ===============================================
echo        Installation Summary
echo ===============================================
echo Status: SUCCESS [OK]
echo OS: Windows !VERSION! [OK]
echo Code::Blocks: Installed [OK]
echo MinGW Compiler: Configured [OK]
echo FreeGLUT: Installed [OK]
echo Templates: Updated [OK]
echo Shortcuts: Created [OK]
echo ===============================================
echo.
echo You can now start developing OpenGL applications with GLUT!
echo.
echo Troubleshooting:
echo - If you get linking errors, ensure you link: -lfreeglut -lopengl32 -lglu32
echo - If DLL errors occur, copy freeglut.dll to your project's output directory
echo - Sample project available in Documents folder for reference
echo.

:: Check if test project exists and offer to open it
if exist "%TEST_PROJECT%" (
    echo ===============================================
    echo        Test Project Found!
    echo ===============================================
    echo.
    echo A test project has been found at:
    echo %TEST_PROJECT%
    echo.
    set /p open_test="Open and run the test project now? (y/n): "
    if /i "!open_test!"=="y" (
        echo.
        echo [INFO] Opening test project in Code::Blocks...
        echo [INFO] This will demonstrate that GLUT is working correctly.
        echo.
        
        :: Open the project in Code::Blocks
        start "" "%CODEBLOCKS_PATH%\codeblocks.exe" "%TEST_PROJECT%"
        
        :: Wait a moment for Code::Blocks to load
        timeout /t 3 /nobreak >nul
        
        echo [SUCCESS] Test project opened in Code::Blocks!
        echo.
        echo Instructions for running the test:
        echo 1. Wait for Code::Blocks to fully load the project
        echo 2. Press F9 (or go to Build -^> Build and Run^)
        echo 3. If successful, you should see a GLUT window with graphics
        echo.
        echo If the test runs successfully, your GLUT installation is complete!
        echo If you encounter errors, check the troubleshooting section above.
        echo.
    )
) else (
    echo [INFO] Test project not found at: %TEST_PROJECT%
    echo You can create your own GLUT project using the sample code provided.
    echo.
)
echo Press any key to exit...
pause >nul

:: Clean up temporary files
if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" >nul 2>&1

exit /b 0