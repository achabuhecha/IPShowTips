# IP 悬浮窗（IPShowTips）

**当前版本：v1.0.0**

一款轻量级的 Windows 桌面小工具，在屏幕右下角以悬浮球形式实时显示你的公网 IP 与归属地。适合需要随时关注 IP 是否变化的用户（如远程办公、网络切换、代理检测等场景）。

本项目提供 **两个实现版本**，功能一致，源码分目录存放：

| 版本 | 目录 | 源码 | 打包 | 输出 exe | 体积 |
|------|------|------|------|----------|------|
| **AutoHotkey 版（推荐）** | `autohotkey/` | `IPShowTips.ahk` | `build.bat` | `dist/IPShowTips_ahk.exe` | 约 1.2 MB |
| **Python 版** | `python/` | `ip_widget.py` | `build.bat` | `dist/IPShowTips_py.exe` | 约 19 MB |

![适用平台](https://img.shields.io/badge/平台-Windows-blue)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-green)
![Python](https://img.shields.io/badge/Python-3.8+-green)
![版本](https://img.shields.io/badge/版本-v1.0.0-orange)

## 功能特点

- **悬浮球显示**：默认以圆形悬浮球常驻桌面，置顶显示，不遮挡正常工作
- **公网 IP 查询**：自动获取当前公网 IP 及归属地（运营商/省市）
- **定时刷新**：每 10 秒自动刷新一次 IP 信息
- **IP 变化提醒**：检测到 IP 变更时弹出提醒框，显示原 IP、新 IP 与归属地
- **自由拖动**：按住悬浮球拖动即可调整位置，拖出屏幕边界时自动拉回
- **单击展开**：单击悬浮球展开详情面板，鼠标移开后自动收起
- **智能展开方向**：靠近屏幕边缘时，面板会向内侧展开，避免内容被裁切
- **系统托盘**：可最小化到任务栏托盘区，后台继续监控

## 快速开始（exe 用户）

任选其一，双击运行即可：

1. **轻量版（推荐）**：`autohotkey/dist/IPShowTips_ahk.exe`
2. **Python 版**：`python/dist/IPShowTips_py.exe`

屏幕右下角出现 **IP** 悬浮球，即表示启动成功。

> 若托盘区看不到图标，请点击任务栏右下角 **^** 展开隐藏图标。

## 操作说明

| 操作 | 说明 |
|------|------|
| **拖动悬浮球** | 按住左键拖动，调整位置 |
| **单击悬浮球** | 展开 IP 详情面板 |
| **鼠标移开面板** | 自动收起为悬浮球 |
| **右键悬浮球** | 打开菜单（最小化到托盘 / 退出） |
| **双击托盘图标** | 重新显示悬浮球 |
| **IP 变化** | 自动弹出提醒，点击「知道了」关闭 |

## 开发与运行

### AutoHotkey 版（`autohotkey/`）

**环境要求：** Windows 10/11，[AutoHotkey v2](https://www.autohotkey.com/)（安装时勾选 Compiler）

```bash
cd autohotkey
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" IPShowTips.ahk
```

**编译为 exe：**

```bash
cd autohotkey
build.bat
```

输出：`autohotkey/dist/IPShowTips_ahk.exe`（约 **1.2 MB**）

### Python 版（`python/`）

**环境要求：** Windows 10/11，Python 3.8 及以上

```bash
cd python
pip install -r requirements.txt
python ip_widget.py
```

**打包为 exe：**

```bash
cd python
build.bat
```

输出：`python/dist/IPShowTips_py.exe`（约 **19 MB**）

> **最终用户无需安装 Python 或 AutoHotkey**，只需运行对应目录下编译好的 exe。

## 项目结构

```
IPShowTips/
├── autohotkey/              # AutoHotkey 版
│   ├── IPShowTips.ahk
│   ├── build.bat
│   ├── tools/compiler/      # 本地编译工具（build 时自动生成，已 gitignore）
│   └── dist/
│       └── IPShowTips_ahk.exe
├── python/                  # Python 版
│   ├── ip_widget.py
│   ├── requirements.txt
│   ├── build.bat
│   └── dist/
│       └── IPShowTips_py.exe
├── README.md
├── 使用说明.txt
└── LICENSE
```

## 数据来源

IP 信息通过 [太平洋电脑网 IP 接口](https://whois.pconline.com.cn/) 获取，需联网使用。

## 常见问题

**Q：两个版本有什么区别？**  
A：功能一致。AHK 版体积更小、启动更快，推荐日常使用；Python 版便于用 Python 二次开发。

**Q：悬浮球点不动 / 拖不动？**  
A：请用左键按住圆球本身拖动；轻点一下（不拖动）才会展开面板。

**Q：如何彻底退出？**  
A：右键悬浮球 →「退出程序」，或右键托盘图标 →「退出」。

## 免责声明

本工具仅供学习与交流使用。IP 归属地信息来自第三方接口，仅供参考，不保证绝对准确。

## 开源协议

MIT License — 可自由使用、修改与分发。
