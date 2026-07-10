@echo off
cd /d "%~dp0"

echo Installing dependencies...
python -m pip install -r requirements.txt

echo.
echo Cleaning old build artifacts...
if exist build rmdir /s /q build
if exist *.spec del /q *.spec

echo.
echo Building exe...
python -m PyInstaller --noconsole --onefile --clean ^
  --name "IPShowTips_py" ^
  --hidden-import=pystray._win32 ^
  --exclude-module setuptools ^
  --exclude-module distutils ^
  --exclude-module unittest ^
  --exclude-module test ^
  --exclude-module pydoc ^
  --exclude-module xml ^
  --exclude-module xmlrpc ^
  --exclude-module multiprocessing ^
  ip_widget.py

echo.
if exist "dist\IPShowTips_py.exe" (
    for %%A in ("dist\IPShowTips_py.exe") do echo OK: dist\IPShowTips_py.exe  size: %%~zA bytes
) else (
    echo Build failed. Check errors above.
)
pause
