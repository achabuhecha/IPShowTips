@echo off
cd /d "%~dp0"

set "COMPILER_DIR=%~dp0tools\compiler"
set "AHK2EXE=%COMPILER_DIR%\Ahk2Exe.exe"
set "AHK_BIN=%COMPILER_DIR%\AutoHotkey64.exe"
set "AHK_CHM=%COMPILER_DIR%\AutoHotkey.chm"
set "MPRESS=%COMPILER_DIR%\MPRESS.exe"

if not exist "%COMPILER_DIR%" mkdir "%COMPILER_DIR%"

if not exist "%AHK2EXE%" (
    if exist "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" (
        copy /y "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" "%AHK2EXE%" >nul
    )
)

if not exist "%AHK_BIN%" (
    if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" (
        copy /y "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "%AHK_BIN%" >nul
    )
)

if not exist "%AHK_CHM%" (
    if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey.chm" (
        copy /y "C:\Program Files\AutoHotkey\v2\AutoHotkey.chm" "%AHK_CHM%" >nul
    )
)

if not exist "%MPRESS%" (
    if exist "C:\Program Files\AutoHotkey\Compiler\MPRESS.exe" (
        copy /y "C:\Program Files\AutoHotkey\Compiler\MPRESS.exe" "%MPRESS%" >nul
    )
)

set "COMPRESS=0"
if exist "%MPRESS%" set "COMPRESS=1"

if not exist "%AHK2EXE%" (
    echo Ahk2Exe not found. Install AutoHotkey v2 with the compiler, then retry.
    echo   Dash -^> Compile, or run: C:\Program Files\AutoHotkey\UX\install-ahk2exe.ahk
    pause
    exit /b 1
)

if not exist "%AHK_BIN%" (
    echo AutoHotkey64.exe not found. Please install AutoHotkey v2.
    pause
    exit /b 1
)

if not exist "%AHK_CHM%" (
    echo AutoHotkey.chm not found. Copy it from:
    echo   C:\Program Files\AutoHotkey\v2\AutoHotkey.chm
    echo to tools\compiler\
    pause
    exit /b 1
)

if not exist dist mkdir dist

echo Compiler: %AHK2EXE%
echo Building IPShowTips.ahk (compress=%COMPRESS%) ...

"%AHK2EXE%" /in "IPShowTips.ahk" /out "dist\IPShowTips_ahk.exe" /compress %COMPRESS% /bin "%AHK_BIN%"

echo.
if exist "dist\IPShowTips_ahk.exe" (
    for %%A in ("dist\IPShowTips_ahk.exe") do echo OK: dist\IPShowTips_ahk.exe  size: %%~zA bytes
) else (
    echo Build failed. Exit code 52 usually means AutoHotkey.chm is missing.
    echo Check tools\compiler\ for Ahk2Exe.exe, AutoHotkey64.exe, AutoHotkey.chm
)
pause
