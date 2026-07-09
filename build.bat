@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo 安装依赖...
python -m pip install -r requirements.txt

echo.
echo 开始打包 exe...
python -m PyInstaller --noconsole --onefile --clean ^
  --name "IPShowTips" ^
  --hidden-import=pystray._win32 ^
  ip_widget.py

echo.
if exist "dist\IPShowTips.exe" (
    echo 打包成功: dist\IPShowTips.exe
) else (
    echo 打包失败，请检查上方报错信息
)
pause
