
class Window
{
	
	; 指定したハンドルでWindowオブジェクトを作って返す
	Make(id)
	{		
		; アクティブなウィンドウとタイトル、サイズを取得
		WinGetTitle, title, ahk_id %id%
		WinGetPos, ax, ay, aw, ah, ahk_id %id%
		
		return new Window(id, title, ax, ay, aw, ah)
	}

	; コンストラクタ
	__New(id, title, x, y, w, h)
	{
		OutputDebug, % "  --> Make Window"
		this.id := id
		this.title := title
		this.x := x
		this.y := y
		this.w := w
		this.h := h

		; ウィンドウのパスを取得する
		WinGet, path, ProcessPath, ahk_id %id%
		this.path := path
		
		; ウィンドウのボーダーオフセットを取得する
		r := this.GetWindowBorderOffset(this.id)
		this.offset_width := r[1]
		this.offset_height := r[2]

		; コマンドプロンプトウィンドウの場合は、サイズを15に固定する。
		if(InStr(this.path, "cmd.exe", False))
		{
			this.offset_width := 15
		}
		
		; ウィンドウ状態を格納しておく
		this.r := DllCall("GetWindowLongPtr", "Ptr", this.id, "Uint", -16) ; GWL_STYLE
		this.exr := DllCall("GetWindowLongPtr", "Ptr", this.id, "Uint", -20) ; GWL_EXSTYLE
		this.Zoomed := this.IsZoomed()
		this.Iconic := this.IsIconic()
		this.HugApp := this.IsHungAppWindow()
		this.Enabled := this.IsWindowEnabled()
		this.TopMost := this.IsTopMost()
	}

	; 指定したハンドルのウィンドウのボーダーを取得し設定する
	; https://www.webtech.co.jp/blog/os/win10/8445/
	GetWindowBorderOffset(id)
	{
		; ウィンドウのサイズを取得
 		Static WinRECT
		VarSetCapacity(WinRECT,24,0)
		PtrType:=(A_PtrSize=8) ? "Ptr":"UInt"
		r := DllCall("GetWindowRect",PtrType,id,PtrType,&WinRECT)
		wLeft :=NumGet(WinRECT,0,"Int")
    	wTop  :=NumGet(WinRECT,4,"Int")
   	 	wRight   :=NumGet(WinRECT,8,"Int")
    	wBottom  :=NumGet(WinRECT,12,"Int")
		wWidth := wRight - wLeft
		wHeight := wBottom - wTop
		OutputDebug, % "    Window pos         : " wLeft " , " wTop  " , " wRight " , " wBottom " : " wWidth " x " wHeight
		
		; ウィンドウのクライアント領域を取得
 		Static ClientRECT
		VarSetCapacity(ClientRECT,24,0)
		PtrType:=(A_PtrSize=8) ? "Ptr":"UInt"
		r := DllCall("GetClientRect",PtrType,id,PtrType,&ClientRECT)
		cLeft :=NumGet(ClientRECT,0,"Int")
    	cTop  :=NumGet(ClientRECT,4,"Int")
   	 	cRight   :=NumGet(ClientRECT,8,"Int")
    	cBottom  :=NumGet(ClientRECT,12,"Int")
		cWidth := cRight - cLeft
		cHeight := cBottom - cTop
		OutputDebug, % "    Window Client size : " cLeft " , " cTop  " , " cRight " , " cBottom " : " cWidth " x " cHeight

		; DWMウィンドウのクライアント領域を取得
 		Static DWMRECT
		VarSetCapacity(DWMRECT,16,0)
		PtrType:=(A_PtrSize=8) ? "Ptr":"UInt"
		r := DllCall("Dwmapi.dll\DwmGetWindowAttribute",PtrType,id,"Uint",9,PtrType,&DWMRECT,"Uint", 16)
		dLeft :=NumGet(DWMRECT,0,"Int")
    	dTop  :=NumGet(DWMRECT,4,"Int")
   	 	dRight   :=NumGet(DWMRECT,8,"Int")
    	dBottom  :=NumGet(DWMRECT,12,"Int")
		dWidth := dRight - dLeft
		dHeight := dBottom - dTop
		OutputDebug, % "    Window Client DWM  : " dLeft " , " dTop  " , " dRight " , " dBottom " : " dWidth " x " dHeight

		; 領域の差 = ボーダーを計算する
		offsetw := wWidth - dWidth
		offseth := wHeight - dHeight
		OutputDebug % "    Window border : " offsetw " x " offseth

		return [offsetw, offseth]
	}

	; -------------------------------
	;
	; ウィンドウ情報取得メソッド
	;
	; -------------------------------

	; 最大化しているかどうか取得する
	IsZoomed()
	{		
		r := DllCall("IsZoomed", "UInt", this.id)
		return r == 1 ? true : false
	}
	
	; 最小化しているかどうか取得する
	IsIconic()
	{		
		r := DllCall("IsIconic", "UInt", this.id)
		return r == 1 ? true : false
	}
	
	; 応答なしか？取得する
	IsHungAppWindow()
	{
		r := DllCall("IsHungAppWindow", "UInt", this.id)
		return r == 1 ? true : false
	}

	; 有効なウィンドウか？取得する
	IsWindowEnabled()
	{
		r := DllCall("IsWindowEnabled", "UInt", this.id)
		return r == 1 ? true : false
	}

	; 常に最前面か？取得する
	IsTopMost()
	{		
		; アクティブウィンドウが最前面かどうか調べる
		; GetWindowLongのGWL_EXSTYLE(拡張ウィンドウスタイル)の戻り値が、
		;   WS_EX_TOPMOST == 0x8
		; が含まれていたら最前面
		id := this.id
		WinGet,exstyle, ExStyle, ahk_id %id%
		return exstyle & 0x8 == 0x8 ? true : false
	}

	; -------------------------------
	;
	; ウィンドウ移動などのメソッド
	;
	; -------------------------------

	; アクティブウィンドウが最大化もしくは最小化されていたら解除する	
	Restore()
	{				
		r := this.IsZoomed()
		if(r == 1)
		{		
			OutputDebug % "Window maximized : " r
			r := DllCall("ShowWindow"
			, "UInt", this.id
			, "UInt", 9) ; SW_RESTORE  
			OutputDebug % "Window restore : " r			
		}
		
		r := this.IsIconic()
		if(r == 1)
		{		
			OutputDebug % "Window minimized : " r
			r := DllCall("ShowWindow"
			, "UInt", this.id
			, "UInt", 9) ; SW_RESTORE  
			OutputDebug % "Window restore : " r			
		}
	}

	; ウィンドウを常に全面
	AlwaysOnTop(enable)
	{
		id := this.id
		sw := enable == true ? ON : OFF
		WinSet, Topmost, %sw%, ahk_id %id%
		
		OutputDebug, % "  Topmost = " id ", enable = " enable
	}

	AlwaysOnTopToggle()
	{		
		id := this.id
		WinSet, Topmost, TOGGLE, ahk_id %id%
	}

	; アクティブウィンドウの最大化→通常をトグルする	
	Toggle()
	{		
		; アクティブウィンドウが最大化されていたら解除する		
		r := this.IsZoomed()
		OutputDebug % "Window maximized : " r

		if(r == 1)
		{		
			r := DllCall("ShowWindow"
			, "UInt", this.id
			, "UInt", 9) ; SW_RESTORE  
			OutputDebug % "Window restore : " r			
		}
		else
		{
			r := DllCall("ShowWindow"
			, "UInt", this.id
			, "UInt", 3) ; SW_MAXIMIZE  
			OutputDebug % "Window maximized : " r	
		} 
	}

	RestorePos()
	{
		processed := false

		; 元々、最小化されていたら最小化する
		if(this.Iconic == 1)
		{	
			WinMinimize, % "ahk_id" this.id
			processed := true
		}

		; 元々、最大化されていたら最大化する
		else if(this.Zoomed == 1)
		{	
			WinMaximize, % "ahk_id" this.id
			processed := true
		}

		; 元々、普通で、最小化されていたら→解除する
		else if(this.Iconic == 0 && this.IsIconic() == 1)
		{
			this.Restore()
			processed := true
		}

		; 元々、普通で、最大化されていたら→解除する
		else if(this.Zoomed == 0 && this.IsZoomed() == 1)
		{
			this.Restore()	
			processed := true
		}
		
		; 最前面なら最前面にする
		if(this.TopMost == 1)
		{
			this.AlwaysOnTop(true)
		}

		; 全面に移動する
		id := this.id
		WinSet, Top,,ahk_id %id%

		; 移動する
		if(processed == false)
		{
			this.WinRestorePlus(this.id, this.x, this.y, this.w, this.h)
		}
	}

	; https://www.autohotkey.com/boards/viewtopic.php?t=39569
	WinRestorePlus(hwnd:="", X:="", Y:="", W:="", H:="")
	{
		;hwnd := hwnd = "" ? WinExist("A") : hwnd
		hwnd := hwnd = "" ? this.id : hwnd
		X := X = "" ? this.x : X
		Y := Y = "" ? this.y : Y
		W := W = "" ? this.w : W
		H := H = "" ? this.h : H
		
		OutputDebug, % "  Move to = " X ", " Y ", " W ", " H

		VarSetCapacity(WP, 44, 0), NumPut(44, WP, "UInt")
		DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", &WP)
		Lo := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
		To := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
		Wo := NumGet(WP, 36, "Int") - Lo   ; Width of the window in its original restored state
		Ho := NumGet(WP, 40, "Int") - To   ; Height of the window in its original restored state
		L := X = "" ? Lo : X               ; X coordinate of the upper-left corner of the window in its new restored state
		T := Y = "" ? To : Y               ; Y coordinate of the upper-left corner of the window in its new restored state
		R := L + (W = "" ? Wo : W)         ; X coordinate of the bottom-right corner of the window in its new restored state
		B := T + (H = "" ? Ho : H)         ; Y coordinate of the bottom-right corner of the window in its new restored state
		NumPut(9, WP, 8, "UInt")           ; SW_RESTORE = 9
		NumPut(L, WP, 28, "Int")
		NumPut(T, WP, 32, "Int")
		NumPut(R, WP, 36, "Int")
		NumPut(B, WP, 40, "Int")
		Return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", &WP)
	}

	Activate()
	{
		id := this.id
		WinActivate, ahk_id %id%
	}

	CallCursor()
	{
		; マウスカーソルをウィンドウ中央に移動する
		OutputDebug, % "--> CallCursor : " this.x " x " this.y
		CoordMode,Mouse,Window
		MouseMove, this.w / 2, this.h / 2, 0
	}

	Debug()
	{		
		SetFormat, integer, hex
		OutputDebug, % "    id = " . this.id ", title = " this.title 
		OutputDebug, % "    r = " this.r ", exr = " this.exr 
		. ", Zoomed = " . this.Zoomed . ", `tIconic = " . this.Iconic 
		. ", En = " . this.Enabled . ", Hup = " . this.HugApp
		. ", TopMost = " . this.TopMost
		SetFormat, integer, d

		OutputDebug, % "    pos = " . this.x " x " this.y " x " this.w " x " this.h
		 . ", border size = " . this.offset_width
	}

}