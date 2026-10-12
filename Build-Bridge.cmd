@echo off
setlocal
cd /d "%~dp0native"
if not defined VSCMD_ARG_TGT_ARCH (
 for /f "usebackq tokens=*" %%I in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%%I\VC\Auxiliary\Build\vcvars64.bat" >nul
)
if /i not "%VSCMD_ARG_TGT_ARCH%"=="x64" (
 echo Open an x64 Native Tools Command Prompt with MSVC installed.
 exit /b 1
)
cl /nologo /O2 /MT /c /Iminhook\include minhook\src\buffer.c minhook\src\hook.c minhook\src\trampoline.c minhook\src\hde\hde64.c
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /EHsc /W4 /O2 /MT /DNATIVE_EXPAND /LD bridge.cpp buffer.obj hook.obj trampoline.obj hde64.obj /Fe:..\runtime\maschine-browser-bridge.dll /link user32.lib
if errorlevel 1 exit /b 1
if /i not "%~1"=="test" exit /b 0
cl /nologo /std:c++17 /EHsc /W4 /MT /DBRIDGE_TESTS /LD bridge.cpp /Fe:bridge-test.dll /link user32.lib
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /EHsc /W4 /MT host.cpp /Fe:host.exe /link user32.lib
if errorlevel 1 exit /b 1
host.exe
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /EHsc /W4 /MT /DNATIVE_EXPAND /DBRIDGE_TESTS /LD bridge.cpp buffer.obj hook.obj trampoline.obj hde64.obj /Fe:bridge-native-test.dll /link user32.lib
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /EHsc /W4 /MT native-host.cpp /Fe:native-host.exe /link user32.lib
if errorlevel 1 exit /b 1
native-host.exe
exit /b %errorlevel%
