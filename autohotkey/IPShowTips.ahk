#Requires AutoHotkey v2.0
#SingleInstance Force

; IP 悬浮窗 — AutoHotkey v2

APP_TITLE := "IP悬浮窗"
APP_VERSION := "1.0.0"
IP_API := "https://whois.pconline.com.cn/ipJson.jsp?json=true"
USER_AGENT := "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

TRANSPARENT := "010101"
ACCENT := "4F46E5"
DOT_TEXT := "E2E8F0"

DOT_SIZE := 36
PANEL_W := 300
PANEL_H := 120
MARGIN_X := 16
MARGIN_BOTTOM_RATIO := 0.30
HIDE_DELAY := 120
SNAP_THRESHOLD := 6
ANIM_DURATION := 70
ANIM_INTERVAL := 8
REFRESH_MS := 10000

; SetWindowPos flags
SWP_NOSIZE := 0x0001
SWP_NOZORDER := 0x0004
SWP_NOACTIVATE := 0x0010
SWP_NOCOPYBITS := 0x0100
SWP_MOVEONLY := SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOCOPYBITS
SWP_MOVEANDSIZE := SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOCOPYBITS

; ---------- GDI+ 抗锯齿悬浮球 ----------
GdipStartup() {
    static token := 0
    if token
        return token
    si := Buffer(24, 0)
    NumPut("UInt", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &token, "Ptr", si, "Ptr", 0)
    return token
}

CreateDotBitmap(size := DOT_SIZE) {
    return CreateCircleBitmap(size, false)
}

CreateTrayBitmap(size := 32) {
    return CreateCircleBitmap(size, true)
}

CreateCircleBitmap(size, withText := false) {
    GdipStartup()
    stride := ((size * 4 + 3) // 4) * 4
    bits := Buffer(stride * size, 0)
    pBmp := 0
    if DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", size, "Int", size, "Int", stride
        , "Int", 0x26200A, "Ptr", bits.Ptr, "Ptr*", &pBmp)
        throw Error("GdipCreateBitmapFromScan0 failed")

    pGfx := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBmp, "Ptr*", &pGfx)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGfx, "Int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGfx, "Int", 4)

    pad := Max(2.0, size * 0.06)
    d := size - pad * 2
    pBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF334155, "Ptr*", &pBrush)
    DllCall("gdiplus\GdipFillEllipse", "Ptr", pGfx, "Ptr", pBrush, "Float", pad, "Float", pad, "Float", d, "Float", d)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)

    pPen := 0
    penW := Max(1.5, size * 0.06)
    DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF818CF8, "Float", penW, "Int", 0, "Ptr*", &pPen)
    DllCall("gdiplus\GdipDrawEllipse", "Ptr", pGfx, "Ptr", pPen, "Float", pad, "Float", pad, "Float", d, "Float", d)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)

    if withText
        DrawIpOnGraphics(pGfx, size)

    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGfx)

    bgColor := withText ? 0 : 0xFF010101
    hbm := 0
    if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBmp, "Ptr*", &hbm, "UInt", bgColor)
        throw Error("GdipCreateHBITMAPFromBitmap failed")
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBmp)
    if !hbm
        throw Error("empty HBITMAP")
    return hbm
}

DrawIpOnGraphics(pGfx, size) {
    pFam := 0
    if DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Consolas", "Ptr", 0, "Ptr*", &pFam)
        DllCall("gdiplus\GdipGetGenericFontFamilySansSerif", "Ptr*", &pFam)
    pFont := 0
    DllCall("gdiplus\GdipCreateFont", "Ptr", pFam, "Float", Max(7.0, size * 0.30), "Int", 1, "Int", 2, "Ptr", 0, "Ptr*", &pFont)
    pBrushTxt := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFFE2E8F0, "Ptr*", &pBrushTxt)
    pFmt := 0
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &pFmt)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", pFmt, "Int", 1)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", pFmt, "Int", 1)
    rc := Buffer(16, 0)
    NumPut("Float", 0.0, rc, 0)
    NumPut("Float", 0.0, rc, 4)
    NumPut("Float", size * 1.0, rc, 8)
    NumPut("Float", size * 1.0, rc, 12)
    DllCall("gdiplus\GdipDrawString", "Ptr", pGfx, "WStr", "IP", "Int", 2, "Ptr", pFont, "Ptr", rc, "Ptr", pFmt, "Ptr", pBrushTxt)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", pFmt)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrushTxt)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", pFont)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", pFam)
}

class IPFloatMonitor {
    __New() {
        this.state := "dot"
        this.running := true
        this.anchorRight := true
        this.posX := 0
        this.posY := 0
        this.dotAnchorX := 0
        this.dotAnchorY := 0
        this.expandAnchorX := "left"
        this.expandAnchorY := "top"
        this.outsideSince := 0
        this.pressX := ""
        this.winXAtPress := 0
        this.winYAtPress := 0
        this.lastKnownIp := ""
        this.pendingIpOk := ""
        this.pendingIpError := false
        this.alertGui := ""
        this.animMode := ""
        this.animStart := 0
        this.inDotMode := false
        this.didDrag := false
        this.inTray := false
        this.dotHbm := 0
        this.dotPicSize := DOT_SIZE
        this.dragPollFn := this.DragPoll.Bind(this)

        this.BuildGui()
        this.BuildTray()
        this.BuildMenus()
        this.RegisterMessages()
        this.ShowDot()
        this.ApplyGeometry(DOT_SIZE, DOT_SIZE)
        this.EnsureOnScreen()

        SetTimer(this.HoverLoop.Bind(this), 50)
        SetTimer(this.ClockTick.Bind(this), 1000)
        SetTimer(this.IPRefreshLoop.Bind(this), REFRESH_MS)
        this.IPRefreshLoop()
    }

    Run() {
        ww := this.WindowWidth()
        wh := this.WindowHeight()
        this.ApplyGeometry(ww, wh)
        this.gui.Show("x" this.posX " y" this.posY " w" ww " h" wh " NoActivate")
    }

    BuildGui() {
        this.gui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound", APP_TITLE)
        this.gui.BackColor := TRANSPARENT
        this.gui.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))

        this.dotHbm := CreateDotBitmap(DOT_SIZE)
        this.dotPic := this.gui.Add("Picture", "x0 y0 w" DOT_SIZE " h" DOT_SIZE, "HBITMAP:*" this.dotHbm)
        this.dotPic.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))
        ; +0x201 = SS_CENTER | SS_CENTERIMAGE；x1 微调，Consolas 使 IP 视觉居中
        this.dotLbl := this.gui.Add("Text", "x1 y0 w" DOT_SIZE " h" DOT_SIZE " +0x201 BackgroundTrans c" DOT_TEXT, "IP")
        this.dotLbl.SetFont("s9 Bold", "Consolas")
        this.dotLbl.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))

        this.panel := this.gui.Add("Text", "x0 y0 w" PANEL_W " h" PANEL_H " BackgroundWhite")
        this.panel.Visible := false

        this.gui.SetFont("s16 Bold c" ACCENT, "Microsoft YaHei UI")
        this.lblIp := this.gui.Add("Text", "x10 y8 w280 Center BackgroundWhite c" ACCENT, "[ 加载中 ]")

        this.gui.SetFont("s12 c111111", "Microsoft YaHei UI")
        this.lblLoc := this.gui.Add("Text", "x10 y40 w280 Center BackgroundWhite", "归属地: --")

        this.gui.SetFont("s11 c666666", "Microsoft YaHei UI")
        this.lblRefresh := this.gui.Add("Text", "x10 y68 w280 Center BackgroundWhite", "最后刷新: --:--:--")

        this.gui.SetFont("s9 cBBBBBB", "Microsoft YaHei UI")
        this.lblVersion := this.gui.Add("Text", "x10 y92 w280 Center BackgroundWhite", "v" APP_VERSION)

        for ctrl in [this.panel, this.lblIp, this.lblLoc, this.lblRefresh, this.lblVersion]
            ctrl.OnEvent("ContextMenu", this.ShowContextMenu.Bind(this))

        WinSetTransColor(TRANSPARENT, this.gui)
        this.inDotMode := true
    }

    BuildTray() {
        hbm := CreateTrayBitmap(32)
        try {
            hIcon := LoadPicture("HBITMAP:*" hbm, "Icon w32 h-32")
            TraySetIcon(hIcon)
            DllCall("DestroyIcon", "Ptr", hIcon)
        } catch {
            try TraySetIcon("shell32.dll", 167)
        }
        DllCall("DeleteObject", "Ptr", hbm)
        A_IconTip := APP_TITLE " v" APP_VERSION
        this.BuildTrayMenu()
    }

    BuildTrayMenu() {
        A_TrayMenu.Delete()
        if this.inTray {
            A_TrayMenu.Add("显示悬浮球", this.ShowFromTray.Bind(this))
            A_TrayMenu.Default := "显示悬浮球"
        } else {
            A_TrayMenu.Add("最小化到托盘", this.HideToTray.Bind(this))
            A_TrayMenu.Default := "最小化到托盘"
        }
        A_TrayMenu.Add()
        A_TrayMenu.Add("退出", (*) => this.CloseApp())
        A_TrayMenu.ClickCount := 2
    }

    BuildMenus() {
        this.contextMenu := Menu()
        this.contextMenu.Add("最小化到托盘", this.HideToTray.Bind(this))
        this.contextMenu.Add()
        this.contextMenu.Add("退出程序", (*) => this.CloseApp())
    }

    RegisterMessages() {
        OnMessage(0x0084, this.OnNcHitTest.Bind(this))     ; WM_NCHITTEST
        OnMessage(0x00A1, this.OnNcLButtonDown.Bind(this)) ; WM_NCLBUTTONDOWN
        OnMessage(0x00A4, this.OnNcRButtonUp.Bind(this))   ; WM_NCRBUTTONUP
    }

    OnNcHitTest(wParam, lParam, msg, hwnd) {
        if !this.running || !this.IsOurHwnd(hwnd)
            return
        return 2  ; HTCAPTION：系统原生拖动，跟手不闪烁
    }

    OnNcRButtonUp(wParam, lParam, msg, hwnd) {
        if !this.running || hwnd != this.gui.Hwnd
            return
        this.ShowContextMenu()
        return 0
    }

    OnNcLButtonDown(wParam, lParam, msg, hwnd) {
        if !this.running || !this.IsOurHwnd(hwnd)
            return
        if (this.pressX != "")
            return
        MouseGetPos(&x, &y)
        this.pressX := x
        this.didDrag := false
        rect := this.GetWinRect()
        this.winXAtPress := rect[1]
        this.winYAtPress := rect[2]
        this.posX := rect[1]
        this.posY := rect[2]
        SetTimer(this.dragPollFn, 16)
    }

    DragPoll() {
        if (this.pressX = "")
            return
        if GetKeyState("LButton", "P") {
            rect := this.GetWinRect()
            if (Abs(rect[1] - this.winXAtPress) + Abs(rect[2] - this.winYAtPress) >= SNAP_THRESHOLD) {
                this.didDrag := true
                this.anchorRight := false
            }
            return
        }
        SetTimer(this.dragPollFn, 0)
        this.HandleClickOrDragEnd()
    }

    IsOurHwnd(hwnd) {
        if (hwnd = this.gui.Hwnd)
            return true
        return DllCall("IsChild", "Ptr", this.gui.Hwnd, "Ptr", hwnd)
    }

    HandleClickOrDragEnd() {
        if (this.pressX = "")
            return

        rect := this.GetWinRect()
        dragged := this.didDrag
        if !dragged
            dragged := (Abs(rect[1] - this.winXAtPress) + Abs(rect[2] - this.winYAtPress)) >= SNAP_THRESHOLD

        ; 拖动结束：限制在屏幕内（超出边界时拉回）
        if dragged {
            ww := this.WindowWidth()
            wh := this.WindowHeight()
            pos := this.ClampPosition(rect[1], rect[2], ww, wh)
            this.posX := pos[1]
            this.posY := pos[2]
            this.anchorRight := false
            this.SetWindowPos(pos[1], pos[2], ww, wh, true)
        } else if (this.state = "dot") {
            this.StartExpand()
        }

        this.pressX := ""
        this.didDrag := false
    }

    EnsureOnScreen() {
        rect := this.GetWinRect()
        ww := this.WindowWidth()
        wh := this.WindowHeight()
        pos := this.ClampPosition(rect[1], rect[2], ww, wh)
        if (pos[1] = rect[1] && pos[2] = rect[2]) {
            this.posX := rect[1]
            this.posY := rect[2]
            return
        }
        this.posX := pos[1]
        this.posY := pos[2]
        this.SetWindowPos(pos[1], pos[2], 0, 0, true)
    }

    StopDragTracking() {
        SetTimer(this.dragPollFn, 0)
        this.pressX := ""
        this.didDrag := false
    }

    UpdateDotPicture(size) {
        size := Round(size)
        if (this.dotHbm)
            DllCall("DeleteObject", "Ptr", this.dotHbm)
        this.dotHbm := CreateDotBitmap(size)
        this.dotPic.Value := "HBITMAP:*" this.dotHbm
        this.dotPic.Move(, , size, size)
        this.dotLbl.Move(, , size, size)
        fs := Max(7, Round(size * 0.25))
        this.dotLbl.SetFont("s" fs " Bold", "Consolas")
        this.dotPicSize := size
    }

    ShowDot() {
        this.dotPic.Visible := true
        this.dotLbl.Visible := true
        this.panel.Visible := false
        this.lblIp.Visible := false
        this.lblLoc.Visible := false
        this.lblRefresh.Visible := false
        this.lblVersion.Visible := false
        if !this.inDotMode {
            this.gui.BackColor := TRANSPARENT
            WinSetTransColor(TRANSPARENT, this.gui)
            this.inDotMode := true
        }
        if (this.dotPicSize != DOT_SIZE)
            this.UpdateDotPicture(DOT_SIZE)
        DllCall("SetWindowRgn", "Ptr", this.gui.Hwnd, "Ptr", 0, "Int", 1)  ; 清除矩形裁剪
    }

    ShowPanel() {
        this.dotPic.Visible := false
        this.dotLbl.Visible := false
        this.panel.Visible := true
        this.lblIp.Visible := true
        this.lblLoc.Visible := true
        this.lblRefresh.Visible := true
        this.lblVersion.Visible := true
        this.gui.BackColor := "White"
        this.inDotMode := false
        this.ApplyRectRegion(PANEL_W, PANEL_H)
    }

    ShowContextMenu(*) {
        MouseGetPos(&mx, &my)
        this.contextMenu.Show(mx, my)
    }

    ApplyRectRegion(w, h) {
        rgn := DllCall("CreateRectRgn", "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr")
        DllCall("SetWindowRgn", "Ptr", this.gui.Hwnd, "Ptr", rgn, "Int", 1)
    }

    GetWinRect() {
        rect := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", this.gui.Hwnd, "Ptr", rect)
        x := NumGet(rect, 0, "Int")
        y := NumGet(rect, 4, "Int")
        w := NumGet(rect, 8, "Int") - x
        h := NumGet(rect, 12, "Int") - y
        return [x, y, w, h]
    }

    ScreenSize() {
        return [A_ScreenWidth, A_ScreenHeight]
    }

    ClampPosition(x, y, w, h) {
        sz := this.ScreenSize()
        sw := sz[1]
        sh := sz[2]
        m := MARGIN_X
        w := Round(w)
        h := Round(h)
        ; w/h 必须用当前状态尺寸（悬浮球 36，不是面板 300）
        x := Max(m, Min(Round(x), sw - w - m))
        y := Max(m, Min(Round(y), sh - h - m))
        return [x, y]
    }
    WindowWidth() {
        if (this.state = "dot" || this.state = "shrinking")
            return DOT_SIZE
        if (this.state = "window" || this.state = "expanding")
            return PANEL_W
        rect := this.GetWinRect()
        return rect[3]
    }

    WindowHeight() {
        if (this.state = "dot" || this.state = "shrinking")
            return DOT_SIZE
        if (this.state = "window" || this.state = "expanding")
            return PANEL_H
        rect := this.GetWinRect()
        return rect[4]
    }

    SetWindowPos(x, y, w, h, moveOnly := false) {
        if moveOnly
            DllCall("SetWindowPos", "Ptr", this.gui.Hwnd, "Ptr", 0, "Int", x, "Int", y, "Int", 0, "Int", 0, "UInt", SWP_MOVEONLY)
        else
            DllCall("SetWindowPos", "Ptr", this.gui.Hwnd, "Ptr", 0, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", SWP_MOVEANDSIZE)
    }

    ApplyGeometry(w, h, forAnim := false) {
        w := Round(w)
        h := Round(h)
        if forAnim {
            pos := this.GeometryForAnim(w, h)
            x := pos[1]
            y := pos[2]
        } else if (this.anchorRight && this.state = "dot") {
            sz := this.ScreenSize()
            sw := sz[1]
            sh := sz[2]
            x := sw - w - MARGIN_X
            y := Round(sh * (1 - MARGIN_BOTTOM_RATIO) - h)
            pos := this.ClampPosition(x, y, w, h)
            x := pos[1]
            y := pos[2]
        } else {
            pos := this.ClampPosition(this.posX, this.posY, w, h)
            x := pos[1]
            y := pos[2]
        }
        this.posX := x
        this.posY := y
        if this.gui.Hwnd {
            this.SetWindowPos(x, y, w, h, false)
            if (!forAnim && (this.state = "dot" || this.state = "window"))
                this.EnsureOnScreen()
        } else
            this.gui.Show("w" w " h" h " x" x " y" y " NoActivate")
    }

    ResolveExpandAnchors() {
        sz := this.ScreenSize()
        sw := sz[1]
        sh := sz[2]
        m := MARGIN_X
        growRight := PANEL_W - DOT_SIZE
        growDown := PANEL_H - DOT_SIZE
        spaceRight := sw - (this.dotAnchorX + DOT_SIZE) - m
        spaceLeft := this.dotAnchorX - m
        spaceBottom := sh - (this.dotAnchorY + DOT_SIZE) - m
        spaceTop := this.dotAnchorY - m

        this.expandAnchorX := (spaceRight < growRight && spaceLeft > spaceRight) ? "right" : "left"
        this.expandAnchorY := (spaceBottom < growDown && spaceTop > spaceBottom) ? "bottom" : "top"
    }

    GeometryForAnim(w, h) {
        x := (this.expandAnchorX = "right") ? this.dotAnchorX + DOT_SIZE - w : this.dotAnchorX
        y := (this.expandAnchorY = "bottom") ? this.dotAnchorY + DOT_SIZE - h : this.dotAnchorY
        return this.ClampPosition(x, y, w, h)
    }

    SyncDotAnchorFromWindow() {
        rect := this.GetWinRect()
        currX := rect[1]
        currY := rect[2]
        this.dotAnchorX := (this.expandAnchorX = "right") ? currX + PANEL_W - DOT_SIZE : currX
        this.dotAnchorY := (this.expandAnchorY = "bottom") ? currY + PANEL_H - DOT_SIZE : currY
    }

    Ease(t) {
        return t * t * (3 - 2 * t)
    }

    StartExpand() {
        if (this.state = "window" || this.state = "expanding")
            return
        this.outsideSince := 0
        rect := this.GetWinRect()
        this.dotAnchorX := rect[1]
        this.dotAnchorY := rect[2]
        this.ResolveExpandAnchors()
        this.ShowDot()
        this.animMode := "expand"
        this.animStart := A_TickCount
        this.state := "expanding"
        SetTimer(this.TickAnim.Bind(this), ANIM_INTERVAL)
    }

    StartShrink() {
        if (this.state = "dot" || this.state = "shrinking")
            return
        this.outsideSince := 0
        this.SyncDotAnchorFromWindow()
        this.ShowPanel()
        this.animMode := "shrink"
        this.animStart := A_TickCount
        this.state := "shrinking"
        SetTimer(this.TickAnim.Bind(this), ANIM_INTERVAL)
    }

    TickAnim() {
        elapsed := A_TickCount - this.animStart
        t := Min(elapsed / ANIM_DURATION, 1.0)
        eased := this.Ease(t)

        if (this.animMode = "expand") {
            w := DOT_SIZE + (PANEL_W - DOT_SIZE) * eased
            h := DOT_SIZE + (PANEL_H - DOT_SIZE) * eased
            this.ApplyGeometry(w, h, true)
            if (eased < 0.55) {
                this.ShowDot()
                size := Round(Min(w, h))
                this.UpdateDotPicture(size)
            } else {
                this.ShowPanel()
            }
            if (t >= 1.0) {
                this.ApplyGeometry(PANEL_W, PANEL_H, true)
                this.ShowPanel()
                this.state := "window"
                this.animMode := ""
                this.outsideSince := 0
                SetTimer(this.TickAnim.Bind(this), 0)
            }
        } else if (this.animMode = "shrink") {
            w := PANEL_W - (PANEL_W - DOT_SIZE) * eased
            h := PANEL_H - (PANEL_H - DOT_SIZE) * eased
            this.ApplyGeometry(w, h, true)
            if (eased < 0.45)
                this.ShowPanel()
            else {
                this.ShowDot()
                size := Max(DOT_SIZE, Round(Min(w, h)))
                this.UpdateDotPicture(size)
            }
            if (t >= 1.0) {
                this.UpdateDotPicture(DOT_SIZE)
                this.ApplyGeometry(DOT_SIZE, DOT_SIZE, true)
                this.ShowDot()
                this.state := "dot"
                this.animMode := ""
                this.EnsureOnScreen()
                SetTimer(this.TickAnim.Bind(this), 0)
            }
        }
    }

    HoverLoop() {
        if !this.running || this.state != "window"
            return
        if this.PointerInside() {
            this.outsideSince := 0
            return
        }
        if (this.outsideSince = 0)
            this.outsideSince := A_TickCount
        else if (A_TickCount - this.outsideSince >= HIDE_DELAY)
            this.StartShrink()
    }

    PointerInside() {
        MouseGetPos(&mx, &my, &winHwnd)
        if (winHwnd = this.gui.Hwnd)
            return true
        rect := this.GetWinRect()
        return mx >= rect[1] && mx < rect[1] + rect[3] && my >= rect[2] && my < rect[2] + rect[4]
    }

    ClockTick() {
        if !this.running
            return
        this.FlushPendingIp(FormatTime(, "HH:mm:ss"))
    }

    IPRefreshLoop(*) {
        this.FetchIPWorker()
    }

    FetchIPWorker() {
        data := this.DoFetchIP()
        if data.Length >= 2 {
            this.pendingIpOk := data[1] . "|" . data[2]
            this.pendingIpError := false
        } else {
            this.pendingIpOk := ""
            this.pendingIpError := true
        }
        this.FlushPendingIp(FormatTime(, "HH:mm:ss"))
    }

    DoFetchIP() {
        try {
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", IP_API, false)
            http.SetRequestHeader("User-Agent", USER_AGENT)
            http.SetTimeouts(8000, 8000, 8000, 8000)
            http.Send()
            text := this.DecodeGBK(http.ResponseBody)
            if (text = "")
                text := http.ResponseText
            ip := this.JsonField(text, "ip")
            loc := this.JsonField(text, "addr")
            if (loc = "") {
                pro := this.JsonField(text, "pro")
                city := this.JsonField(text, "city")
                loc := pro . city
            }
            if (ip = "")
                throw Error("empty ip")
            return [ip, loc]
        } catch {
            return []
        }
    }

    DecodeGBK(body) {
        stream := ComObject("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(body)
        stream.Position := 0
        stream.Type := 2
        stream.Charset := "GB2312"
        return stream.ReadText()
    }

    JsonField(json, key) {
        if RegExMatch(json, '"' key '"\s*:\s*"([^"]*)"', &m)
            return m[1]
        if RegExMatch(json, '"' key '"\s*:\s*([^,}\s]+)', &m)
            return Trim(m[1], '"')
        return ""
    }

    FlushPendingIp(timeText) {
        if (this.pendingIpOk != "") {
            parts := StrSplit(this.pendingIpOk, "|", , 2)
            ip := parts[1]
            loc := parts[2]
            this.pendingIpOk := ""
            if (this.lastKnownIp != "" && this.lastKnownIp != ip)
                this.ShowIpChangeAlert(this.lastKnownIp, ip, loc)
            this.lastKnownIp := ip
            this.lblIp.Text := "[ " ip " ]"
            this.lblLoc.Text := "归属地: " loc
            this.lblRefresh.Text := "最后刷新: " timeText
            return
        }
        if this.pendingIpError {
            this.pendingIpError := false
            this.lblIp.Text := "[ 网络异常 ]"
            this.lblLoc.Text := "归属地: 获取失败"
            this.lblRefresh.Text := "最后刷新: " timeText
        }
    }

    AlertPosition(w, h) {
        rect := this.GetWinRect()
        dotX := rect[1]
        dotY := rect[2]
        dotW := this.WindowWidth()
        dotH := this.WindowHeight()
        x := dotX + dotW - w
        y := dotY - h - 12
        if (y < MARGIN_X)
            y := dotY + dotH + 12
        return this.ClampPosition(x, y, w, h)
    }

    ShowIpChangeAlert(oldIp, newIp, loc) {
        this.CloseIpAlert()
        alert := Gui("-Caption +AlwaysOnTop +ToolWindow", "IP变化提醒")
        alert.BackColor := "White"
        alert.SetFont("s13 Bold c" ACCENT, "Microsoft YaHei UI")
        alert.Add("Text", "x16 y10 w268 BackgroundWhite", "检测到 IP 地址变化")
        alert.SetFont("s11 c666666", "Consolas")
        alert.Add("Text", "x16 y40 w268 BackgroundWhite", "原 IP：" oldIp)
        alert.SetFont("s12 Bold c111111", "Consolas")
        alert.Add("Text", "x16 y62 w268 BackgroundWhite", "新 IP：" newIp)
        alert.SetFont("s11 c444444", "Microsoft YaHei UI")
        alert.Add("Text", "x16 y88 w268 BackgroundWhite", "归属地：" loc)
        btn := alert.Add("Button", "x200 y118 w80 h28", "知道了")
        btn.OnEvent("Click", (*) => this.CloseIpAlert())
        w := 300, h := 160
        pos := this.AlertPosition(w, h)
        x := pos[1]
        y := pos[2]
        alert.Show("w" w " h" h " x" x " y" y)
        this.alertGui := alert
    }

    CloseIpAlert(*) {
        if (this.alertGui != "") {
            try this.alertGui.Destroy()
            this.alertGui := ""
        }
    }

    HideToTray(*) {
        if (this.state != "dot" && this.state != "shrinking")
            this.StartShrink()
        SetTimer(() => this.gui.Hide(), -200)
        this.inTray := true
        this.BuildTrayMenu()
    }

    ShowFromTray(*) {
        this.gui.Show("NoActivate")
        WinSetAlwaysOnTop(true, this.gui)
        this.inTray := false
        this.BuildTrayMenu()
    }

    CloseApp(*) {
        if !this.running
            return
        this.running := false
        SetTimer(this.HoverLoop.Bind(this), 0)
        SetTimer(this.ClockTick.Bind(this), 0)
        SetTimer(this.IPRefreshLoop.Bind(this), 0)
        SetTimer(this.TickAnim.Bind(this), 0)
        SetTimer(this.dragPollFn, 0)
        this.StopDragTracking()
        this.CloseIpAlert()
        ExitApp()
    }
}

app := IPFloatMonitor()
app.Run()
