@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo 安装依赖...
python -m pip install -r requirements.txt

echo.
echo 清理旧构建产物...
if exist build rmdir /s /q build
if exist *.spec del /q *.spec

echo.
echo 开始打包 exe...
python -m PyInstaller --noconsole --onefile --clean ^
  --name "IPShowTips" ^
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
if exist "dist\IPShowTips.exe" (
    for %%A in ("dist\IPShowTips.exe") do echo 打包成功: dist\IPShowTips.exe  大小: %%~zA 字节
) else (
    echo 打包失败，请检查上方报错信息
)
pause
