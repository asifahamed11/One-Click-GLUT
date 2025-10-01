@echo off
setlocal EnableDelayedExpansion

:: One Click GLUT Installer - Clean & Simple Version
:: Auto-detects and installs correct 32/64-bit libraries

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorLevel% neq 0 (
    echo Requesting administrator access...
    if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs"
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

cls
echo.
echo ========================================
echo   GLUT Installer v2
echo ========================================
echo.
echo Running as Administrator... OK
echo.

:: Detect System Architecture
echo Checking your system...
set "ARCH=unknown"
set "IS_64BIT=0"

if defined PROCESSOR_ARCHITEW6432 (
    set "ARCH=x64"
    set "IS_64BIT=1"
) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ARCH=x64"
    set "IS_64BIT=1"
) else if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "ARCH=x86"
    set "IS_64BIT=0"
)

if "!IS_64BIT!"=="1" (
    echo System: 64-bit Windows
    echo Installing: 64-bit GLUT
) else (
    echo System: 32-bit Windows
    echo Installing: 32-bit GLUT
)
echo.

:: Define paths
set "INSTALLER_DIR=%~dp0"
set "CODEBLOCKS_INSTALLER=%INSTALLER_DIR%codeblocks-25.03mingw-setup.exe"
set "FREEGLUT_DIR=%INSTALLER_DIR%freeglut"
set "TEST_PROJECT=%INSTALLER_DIR%Test\Test.cbp"

set "CODEBLOCKS_PATH="
if exist "C:\Program Files\CodeBlocks" (
    set "CODEBLOCKS_PATH=C:\Program Files\CodeBlocks"
) else if exist "C:\Program Files (x86)\CodeBlocks" (
    set "CODEBLOCKS_PATH=C:\Program Files (x86)\CodeBlocks"
) else (
    set "CODEBLOCKS_PATH=C:\Program Files\CodeBlocks"
)

echo Checking files...
if not exist "%CODEBLOCKS_INSTALLER%" (
    echo.
    echo ERROR: CodeBlocks installer not found!
    echo Looking for: codeblocks-25.03mingw-setup.exe
    echo.
    pause
    exit /b 1
)

if not exist "%FREEGLUT_DIR%" (
    echo.
    echo ERROR: FreeGLUT folder not found!
    echo Looking for: freeglut folder
    echo.
    pause
    exit /b 1
)

echo All files found! OK
echo.

:: Install Code::Blocks
echo Installing CodeBlocks...
echo Please wait, this may take a few minutes...
echo.

taskkill /f /im codeblocks.exe >nul 2>&1
start /wait "" "%CODEBLOCKS_INSTALLER%" /S /D=%CODEBLOCKS_PATH%

if %errorLevel% neq 0 (
    echo.
    echo ERROR: CodeBlocks installation failed!
    pause
    exit /b 1
)

echo Waiting for installation to complete...
timeout /t 5 /nobreak >nul



:: Detect MinGW
echo.
echo Detecting MinGW compiler...
set "MINGW_PATH="
set "MINGW_ARCH=unknown"
set "MINGW_FOUND=0"

:: Check for 64-bit MinGW first
if exist "%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\x86_64-w64-mingw32"
    set "MINGW_ARCH=x64"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW\mingw64" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\mingw64"
    set "MINGW_ARCH=x64"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW\bin\x86_64-w64-mingw32-gcc.exe" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW"
    set "MINGW_ARCH=x64"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW\mingw32" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW\mingw32"
    set "MINGW_ARCH=x86"
    set "MINGW_FOUND=1"
) else if exist "%CODEBLOCKS_PATH%\MinGW" (
    set "MINGW_PATH=%CODEBLOCKS_PATH%\MinGW"
    if exist "%CODEBLOCKS_PATH%\MinGW\bin\gcc.exe" (
        "%CODEBLOCKS_PATH%\MinGW\bin\gcc.exe" -dumpmachine > "%temp%\gcc_arch.txt" 2>&1
        findstr /i "x86_64" "%temp%\gcc_arch.txt" >nul
        if !errorLevel! equ 0 (
            set "MINGW_ARCH=x64"
        ) else (
            set "MINGW_ARCH=x86"
        )
        del "%temp%\gcc_arch.txt" >nul 2>&1
    ) else (
        set "MINGW_ARCH=x86"
    )
    set "MINGW_FOUND=1"
)

if "!MINGW_FOUND!"=="0" (
    echo.
    echo ERROR: MinGW compiler not found!
    pause
    exit /b 1
)

echo MinGW found: !MINGW_ARCH!-bit
echo.

:: Check for architecture mismatch
if "!IS_64BIT!"=="1" if "!MINGW_ARCH!"=="x86" (
    echo ========================================
    echo   WARNING: Architecture Mismatch!
    echo ========================================
    echo.
    echo Your Windows: 64-bit
    echo Your MinGW:   32-bit
    echo.
    echo This may cause errors!
    echo Recommendation: Use 64-bit MinGW
    echo ========================================
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" (
        echo Installation cancelled.
        pause
        exit /b 0
    )
    echo.
)

:: Setup FreeGLUT
echo Installing FreeGLUT (!MINGW_ARCH!-bit)...
echo.

if not exist "%MINGW_PATH%\include" mkdir "%MINGW_PATH%\include"
if not exist "%MINGW_PATH%\include\GL" mkdir "%MINGW_PATH%\include\GL"
if not exist "%MINGW_PATH%\lib" mkdir "%MINGW_PATH%\lib"
if not exist "%MINGW_PATH%\bin" mkdir "%MINGW_PATH%\bin"

:: Copy headers
echo Copying headers...
xcopy /y /i /q "%FREEGLUT_DIR%\include\GL\*" "%MINGW_PATH%\include\GL\" >nul
if %errorLevel% neq 0 (
    echo ERROR: Failed to copy headers!
    pause
    exit /b 1
)

:: Copy libraries based on architecture
echo Copying libraries...
if "!MINGW_ARCH!"=="x64" (
    if exist "%FREEGLUT_DIR%\lib\x64" (
        xcopy /y /q "%FREEGLUT_DIR%\lib\x64\*" "%MINGW_PATH%\lib\" >nul
    ) else if exist "%FREEGLUT_DIR%\lib" (
        xcopy /y /q "%FREEGLUT_DIR%\lib\*.a" "%MINGW_PATH%\lib\" >nul
    )
    
    if exist "%FREEGLUT_DIR%\bin\x64\freeglut.dll" (
        copy /y "%FREEGLUT_DIR%\bin\x64\freeglut.dll" "%MINGW_PATH%\bin\" >nul
        copy /y "%FREEGLUT_DIR%\bin\x64\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul
        copy /y "%FREEGLUT_DIR%\bin\x64\freeglut.dll" "%WINDIR%\System32\" >nul 2>&1
    ) else if exist "%FREEGLUT_DIR%\bin\freeglut.dll" (
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%MINGW_PATH%\bin\" >nul
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%WINDIR%\System32\" >nul 2>&1
    )
    
) else (
    if exist "%FREEGLUT_DIR%\lib\x86" (
        xcopy /y /q "%FREEGLUT_DIR%\lib\x86\*" "%MINGW_PATH%\lib\" >nul
    ) else if exist "%FREEGLUT_DIR%\lib" (
        xcopy /y /q "%FREEGLUT_DIR%\lib\*.a" "%MINGW_PATH%\lib\" >nul
    )
    
    if exist "%FREEGLUT_DIR%\bin\x86\freeglut.dll" (
        copy /y "%FREEGLUT_DIR%\bin\x86\freeglut.dll" "%MINGW_PATH%\bin\" >nul
        copy /y "%FREEGLUT_DIR%\bin\x86\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul
        copy /y "%FREEGLUT_DIR%\bin\x86\freeglut.dll" "%WINDIR%\SysWOW64\" >nul 2>&1
    ) else if exist "%FREEGLUT_DIR%\bin\freeglut.dll" (
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%MINGW_PATH%\bin\" >nul
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%CODEBLOCKS_PATH%\" >nul
        copy /y "%FREEGLUT_DIR%\bin\freeglut.dll" "%WINDIR%\SysWOW64\" >nul 2>&1
    )
)

echo Copying DLL files...
echo Done!
echo.

:: Create sample project
echo Creating sample project...
set "SAMPLE_DIR=%USERPROFILE%\Documents\GLUT_Sample"
if not exist "%SAMPLE_DIR%" mkdir "%SAMPLE_DIR%"

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
echo     std::cout ^<^< "FreeGLUT Sample - !MINGW_ARCH!-bit" ^<^< std::endl;
echo     
echo     glutInit^(^&argc, argv^);
echo     glutInitDisplayMode^(GLUT_DOUBLE ^| GLUT_RGB^);
echo     glutInitWindowSize^(800, 600^);
echo     glutCreateWindow^("FreeGLUT Test"^);
echo     glutDisplayFunc^(display^);
echo     glutMainLoop^(^);
echo     return 0;
echo }
) > "%SAMPLE_DIR%\main.cpp"

echo Sample created in Documents folder
echo.

:: Installation complete
cls
echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Your System:     !IS_64BIT! = 64-bit
echo Compiler:        !MINGW_ARCH!-bit MinGW
echo CodeBlocks:      %CODEBLOCKS_PATH%
echo Sample Code:     %SAMPLE_DIR%

echo.
echo ========================================

if "!IS_64BIT!"=="1" if "!MINGW_ARCH!"=="x86" (
    echo.
    echo WARNING: Mismatch detected!
    echo 64-bit Windows + 32-bit MinGW
    echo May cause errors!
    echo.
)


:: Open test project if exists
if exist "%TEST_PROJECT%" (
    echo ========================================
    echo   Test Project Available!
    echo ========================================
    echo.
    set /p open_test="Open test project? (y/n): "
    if /i "!open_test!"=="y" (
        echo.
        echo Opening CodeBlocks...
        start "" "%CODEBLOCKS_PATH%\codeblocks.exe" "%TEST_PROJECT%"
        echo.
        echo Press F9 to Build and Run
        echo.
    )
)

echo.
echo Press any key to exit...
pause >nul

if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" >nul 2>&1
exit /b 0
