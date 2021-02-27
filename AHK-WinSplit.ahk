; + Shift
; ^ Control
; ! Alt
; # Windows

; https://so-zou.jp/software/tool/system/auto-hot-key/basic-usage/functions.htm
; http://ahkwiki.net/Objects
; https://poimono.exblog.jp/19210175/
; http://eternalwindows.jp/winbase/window/window13.html
; https://odashi.hatenablog.com/entry/20110911/1315730376
; https://riptutorial.com/ja/autohotkey/example/15621/単純な配列の作成と初期化

; ToDo
;	Save windows position
; 	Win10仮想デスクトップに対応する
;		https://blog.tmyt.jp/entry/2015/09/14/193840
;		キーワード : windows10 仮想デスクトップ ウィンドウ位置 api

class Action
{
	__New(name)
	{
		this.name := name
		this.count := 1
		
		; シーケンスを格納するリストを生成
		this.seq := Object()
		return this
	}

	InitCount()
	{
		this.count := 1
	}

	IsLeft()
	{
		return InStr(this.name, "left", false) > 0
	}
	
	IsRight()
	{
		return InStr(this.name, "right", false) > 0
	}
	
	IsUp()
	{
		return InStr(this.name, "up", false) > 0
	}
	
	IsDown()
	{
		return InStr(this.name, "down", false) > 0
	}

	Add(seq)
	{
		this.seq.Insert(seq)
		return this
	}

	GetSequence()
	{
		; シーケンスを取得する
		s := false
		s := this.seq[this.count]
		
		; トグル番号をインクリメントする
		this.count := this.count + 1
		
		; トグル番号が格納しているseqよりも大きくなったら1に戻す
		if this.count > this.seq.length()
		{
			this.count := 1
		}

		OutputDebug, % "  sequence = " (this.count - 1) " = " s.x " x " s.y " x " s.w " x " s.h 

		return s
	}	
}

class Sequence
{
	__New(x, y, w, h)
	{
		this.x := x
		this.y := y
		this.w := w
		this.h := h
	}

	IsVariable()
	{
		return (this.x == "*" || this.y == "*" || this.w == "*" || this.h == "*")
	}
}

class Monitor
{
	; モニタ範囲を格納する
	__New(no,left,top,right,bottom)
	{
		this.no     := no
		this.left   := left
		this.top    := top
		this.right  := right
		this.bottom := bottom

		; 幅と逆さを計算
		; プライマリスクリーンの左上座標が 0,0でOS全体の原点になる。
		; セカンダリスクリーンがプライマリスクリーン左側にある場合、-1920,0,0,1024等となる。s
		this.w := right - left
		this.h := bottom - top

		OutputDebug, % "     --> Monitor = " no
		OutputDebug, % "      " left " x " top " x " right " x " Bottom " : width = " this.w ", height = " this.h
	}
	
	; 座標がこのモニタ範囲内にあるかどうか
	Contains(x, y)
	{		
		;OutputDebug % "   --> Contains(x,y) = " x " x " y " : This monitor size = " this.left " x " this.top  " x " this.right  " x " this.bottom
		if(x >= this.left && x < this.right && y >= this.top && y < this.bottom)
		{
			return true
		}
		return false
	}

	; http://noriok.hatenablog.com/entry/2012/02/19/233543
	Intersect(x, y, w, h)
	{
		sx := x < this.left ? this.left : x
		sy := y < this.top ? this.top : y
		ex := (x + w) < this.right ? (x + w) : this.right
		ey := (y + h) < this.bottom ? (y + h) : this.bottom 

		sw := ex - sx
		sh := ey - sy
		area := sw * sh

		this.Debug()
		OutputDebug, % "    " sx " x " sy " x " ex " x " ey
		OutputDebug, % "    sw = " sw ", sh = " sh

		if(sw > 0 && sh > 0)
		{
			OutputDebug, % "      on this monitor area : " area
		}
		
		return area
	}
	
	Debug()
	{		
		OutputDebug, % "  --> Monitor = " this.no
		OutputDebug, % "  " this.left " x " this.top " x " this.right " x " this.Bottom " : width = " this.w ", height = " this.h
	}
}

class Monitors
{	
	; this.list : モニタ一覧を格納している. GetMonitorInfo()で。

	; モニタ範囲を格納する
	__New()
	{
		; モニタを取得する
		this.GetMonitorInfo()
		
		; モニタの解像度が変わったらモニタ情報を取得し直す
		OnMessage(0x7E, ObjBindMethod(this, "WM_DISPLAYCHANGE"))
	}
	
	WM_DISPLAYCHANGE(wParam, lParam)
	{
		OutputDebug, % "--> Change resolution"
		this.GetMonitorInfo()
	}
	
	GetMonitorInfo()
	{
		; モニタ数を取得
		SysGet, count, MonitorCount

		OutputDebug, % "     GetMonitorInfo count = " count

		; モニタを格納するリストを生成
		this.list := Object()
				
		; モニタ数分ループを回して、モニタ範囲オブジェクトを生成しリストに格納する
		Loop, % count
		{
			SysGet,workarea,MonitorWorkArea,% A_Index		
			this.list.Push(new Monitor(A_Index, workarealeft,workareatop,workarearight,workareabottom))	
		}
	}
	
	; 指定したウィンドウがどのモニタに入っているか？
	Contains(aw)
	{		
		; ウィンドウ枠が画面外に出ていると、このモニタに入っている？という判断が間違えるので
		; （枠がモニタの外に出ていてこのモニタに入っていないと誤判別するので）		
		; 枠分オフセットする。
		x := aw.x + aw.offset_width
		y := aw.y + aw.offset_width

		for index, m in this.list
		{
			r := m.Contains(x,y)
			if(r == true)
			{
				OutputDebug, % "  on monitor no. = " m.no ", monitor size = " m.left " x " m.top " x " m.right " x " m.bottom 
				return m
			}
		}
		
		return false
	}
	
	; 指定した座標がどのモニタに入っているか？
	ContainsXY(x, y)
	{
		for index, m in this.list
		{
			r := m.Contains(x,y)
			if(r == true)
			{
				OutputDebug, % "  on monitor no. = " m.no ", monitor size = " m.left " x " m.top " x " m.right " x " m.bottom 
				return m
			}
		}
		
		return false
	}
	
	; 指定した座標がどのモニタに入っているか？
	Intersect(aw)
	{		
		; ウィンドウ枠が画面外に出ていると、このモニタに入っている？という判断が間違えるので
		; （枠がモニタの外に出ていてこのモニタに入っていないと誤判別するので）		
		; 枠分オフセットする。
		x := aw.x + aw.offset_width
		y := aw.y + aw.offset_height

		tmparea := 0
		tmpindex := 0
		for index, m in this.list
		{
			area := m.Intersect(x,y, aw.w, aw.h)

			; 最大値を更新しつつ、そのインデックスも更新する。
			if(area > tmparea)
			{
				tmpindex := A_Index
				tmparea := area
			}
		}

		OutputDebug, % "  on monitor no. = " tmpindex 
		
		return this.list[tmpindex]
	}

	; 指定したウィンドウがあるモニタの次のモニタを取得する
	NextMonitor(currentmonitor)
	{
		OutputDebug % "  --> NextMonitor no = " currentmonitor.Debug()
		
		; アクティブウィンドウがあるモニタを取得→無ければ終了
		if(currentmonitor = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
						
		; 上から順番に見ていく
		count := this.list.length()
		next := False
		Loop, % count
		{
			m := this.list[A_Index]
			
			if(m.no = currentmonitor.no)
			{
				next := True
				continue
			}

			if(next = True)
			{
				OutputDebug % "    -> NextMonitor no = " A_Index
				return m
			}
		}

		; なければ下から順番に見ていく
		i := count
		next := False
		Loop, % count
		{
			m := this.list[i]
			i--
			
			if(m.no = currentmonitor.no)
			{
				next := True
				continue
			}

			if(next = True)
			{
				OutputDebug % "    -> NextMonitor no = " (i + 1)
				return m
			}
		}

		return False
	}

}

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

class WinSplit
{
	
	; -------------------------------
	;
	; WinSplitクラス内部のメソッド
	;
	; -------------------------------

	__New(monitors, wincollection)
	{
		OutputDebug, -------------------

		; モニタ情報を格納するリストを設定
		this.monitors := monitors

		; Windows Collectionを設定
		this.wc := wincollection
		
		; アクションを格納するリストを生成
		this.action := Object()

		; アンドゥ用のアクティブウィンドウを格納するリストを生成
		this.undo := Object()

		; デフォルトのウィンドウサイズ変更サイズを設定
		this.WindowChangeSize := 30
		
		return this
	}
	
	Add(action)
	{
		this.action.Push(action)
		return this
	}
	
	GetAction(actname)
	{
		StringLower actname, actname

		; 実行するアクションを取得する
		action := false
		for index, a in this.action
		{
			if(a.name == actname)
			{
				action := a
				break
			}
		}
		OutputDebug, % "  action : " action.name
		
		return action
	}

	ClearActionCount(ignoreactionname)
	{
		OutputDebug, --> ClearActionCount

		; 実行するアクションを取得する
		for index, a in this.action
		{
			if(a.name != ignoreactionname)
			{
				a.InitCount()
			}
		}
	}

	GetActiveWindow()
	{		
		; アクティブなウィンドウとタイトル、サイズを取得
		WinGet,id,ID,A
		WinGetTitle, title, ahk_id %id%
		WinGetPos, ax, ay, aw, ah, ahk_id %id%
		
		; アクティブウィンドウのタイトルが空欄は、デスクトップかもしれないので何もしない
		if(title =)
			return false
		if(title = "Program Manager")
			return false
		RegExMatch(title, " - リモート デスクトップ", $)
		if($ !=)
			return false

		aw := new Window(id, title, ax, ay, aw, ah)
		aw.Debug()

		return aw
	}

	; -------------------------------
	;
	; ウィンドウ移動などのメソッド
	;
	; -------------------------------

	; アクティブウィンドウを最前面にする
	TopMostToggle()
	{		
		OutputDebug, --> TopMost
		
		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
			return false

		; トグルする
		aw.AlwaysOnTopToggle()
	}
	
	; 最大化→通常をトグルする
	Toggle()
	{
		OutputDebug, --> Toggle

		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
			return false

		; ウィンドウ状態をトグルする
		aw.Toggle()
	}

	; アクティブウィンドウを移動する
	MoveTo(actname, fit)
	{
		OutputDebug, % "--> MoveTo : " actname ", fit = " fit

		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
		{
			OutputDebug, % "    --> no active window"
			return false
		}
		
		; アクティブウィンドウがあるモニタを取得→無ければ終了
		am := this.monitors.Intersect(aw)
		if(am = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
			
		; 実行するアクションを取得する→無ければ終了
		action := this.GetAction(actname)
		if(action = false)
		{
			OutputDebug, % "    --> no action"
			return false
		}
		; その他アクションのシーケンス番号をリセットする
		this.ClearActionCount(action.name)

		; 実行するシーケンスを取得する→無ければ終了
		seq := action.GetSequence()
		if(seq = false)
		{
			OutputDebug, % "    --> no seq"
			return false
		}
		
		; 移動先を計算
		x := (am.w/100) * seq.x
		y := (am.h/100) * seq.y
		w := (am.w/100) * seq.w
		h := (am.h/100) * seq.h
		
		; ウィンドウをくっつける？
		if(seq.IsVariable())
		{
			; IsVariableの場合、隣のウィンドウにくっつける
			; WinCollectionでくっつける対象のウィンドウを取得する
			; まずGetWindowsでEnumWindowsで対象のウィンドウを全部取得する。
			; 次に、くっつけるウィンドウ(自分の次に列挙されたウィンドウ)を取得する。
			; 取得が出来たら、くっつける座標を計算する
			this.wc.getwindows()
			rw := this.wc.GetNextWindow(aw)

			OutputDebug, % "   Reference window --> "
			rw.Debug()	

			; リファレンスウィンドウがなければ、終了する			
			;   →移動しない場合は、次のシーケンスを実行する
			if(rw = )
			{
				OutputDebug, % "   Reference window none."
				this.MoveTo(actname, fit)
				return
			}

			; ウィンドウをくっつける座標を計算する
			if(action.IsRight())
			{				
				OutputDebug, % "   IsRight"
				if(seq.x == "*")
				{
					x := rw.x + rw.w - (rw.offset_width / 2)
				}

				if(seq.w == "*")
				{
					w := am.w - x
				}
				
				; Reference Windowが画面いっぱいだ→何もしない
				if(rw.x + rw.w >= am.right)
					return
			}

			else if(action.IsLeft())
			{
				OutputDebug, % "   IsLeft"
				if(seq.x == "*")
				{
					x := 0
				}

				if(seq.w == "*")
				{
					w := rw.x + (rw.offset_width / 2)
				}
				
				; Reference Window左端にくっついている→何もしない
				if(rw.x <= 0)
					return 
			}

			else if(action.IsUp())
			{
				OutputDebug, % "   IsUp"
				
				if(seq.y == "*")
				{
					y := 0
				}

				if(seq.h == "*")
				{
					h := rw.y
				}
				
				; Reference Window画面上端にくっついている→何もしない
				if(rw.y <= 0)
					return 
			}
			
			else if(action.IsDown())
			{
				OutputDebug, % "   IsDown"
				
				if(seq.y == "*")
				{
					y := rw.h
				}

				if(seq.h == "*")
				{
					h := am.h - rw.h
				}
				
				; Reference Window画面下端にくっついている→何もしない
				if(rw.h >= am.h)
					return 
			}		

			; 幅がなくなったら移動しない
			;   →移動しない場合は、次のシーケンスを実行する
			if(w < 0 || y < 0)
			{
				OutputDebug, % "   no area. w = " w ", y = " y
				this.MoveTo(actname, fit)
				return
			}
		}
		
		; ウィンドウのボーダーオフセットを加算する
		x := % x - (aw.offset_width / 2)
		w := % w + aw.offset_width
		h := % h + (aw.offset_width / 2)
		
		; モニタのオフセットを加算する(何処のモニタにいるのか加算する)
		x := x + am.left
		y := y + am.top
		
		; アクティブウィンドウを保存しておく
		this.undo.Insert(1, aw)

		; アクティブウィンドウが最大化されていたら解除する		
		aw.Restore()
		
		; 移動する		
		if(fit == true)
		{
			aw.WinRestorePlus(aw.id,x,y,w,h)
		}
		else
		{
			aw.WinRestorePlus(aw.id,x,y)
		}

		return true
	}
	
	; アクティブウィンドウのサイズを変更する
	ChangeWindowSize(direction, IncreaseOrDecrese)
	{
		OutputDebug, % "--> ChangeWindowSize : "  direction " : " IncreaseOrDecrese ", pixel : " this.WindowChangeSize
		pixel := this.WindowChangeSize

		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
			return false
			
		; アクティブウィンドウがあるモニタを取得→無ければ終了
		am := this.monitors.Intersect(aw)
		if(am = false)
			return false
		
		; アクティブウィンドウを保存しておく(リストの最初に)
		this.undo.Insert(1, aw)

		; アクティブウィンドウが最大化されていたら解除する		
		aw.Restore()

		; ウィンドウサイズ変更数値を計算する
		offsetX := 0
		offsetY := 0
		offsetW := 0
		offsetH := 0
		StringLower, direction, direction
		StringLower, IncreaseOrDecrese, IncreaseOrDecrese
		
		; プライマリモニタ以外にウィンドウがある場合、座標がマイナスになっている場合がある。
		; 座標がマイナスだと画面のはみ出し判定が面倒なので、ひとまずウィンドウのx,y座標を原点(0,0)にしてから
		; はみ出し判定をして、移動直前に原点を戻すことにする。
		monitorOffsetX := am.left * -1
		monitorOffsetY := am.top * -1
		x := aw.x + monitorOffsetX
		y := aw.y + monitorOffsetY
		w := aw.w
		h := aw.h 
		
		; ウィンドウがモニタからはみ出し判定をする際に、枠のサイズ(ウィンドウ領域とクライアントの差)があると
		; 計算が面倒なので、いったん無くしてあとから加える
		x := % x + (aw.offset_width / 2)
		w := % w - aw.offset_width
		h := % h - (aw.offset_width / 2)

		OutputDebug, % "  monitor offset = " monitorOffsetX " x " monitorOffsetY
		OutputDebug, % "  before size = " x " x " y " x " w  " x " h
 
		if(IncreaseOrDecrese == "increase")
		{
			if(InStr(direction, "up left") > 0)
			{
				offsetX := -pixel
				offsetY := -pixel
				offsetW := +pixel
				offsetH := +pixel
			}
			else if(InStr(direction, "down left") > 0)
			{
				offsetX := -pixel
				offsetW := +pixel
				offsetH := +pixel
			}
			else if(InStr(direction, "left") > 0)
			{
				offsetX := -pixel
				offsetW := +Pixel
			}
			else if(InStr(direction, "up right") > 0)
			{
				offsetY := -pixel
				offsetW := +pixel
				offsetH := +pixel
			}
			else if(InStr(direction, "down right") > 0)
			{
				offsetW := +pixel
				offsetH := +pixel
			}
			else if(InStr(direction, "right") > 0)
			{
				offsetW := +pixel
			}
			else if(InStr(direction, "up") > 0)
			{
				offsetY := -pixel
				offsetH := +pixel
			}		
			else if(InStr(direction, "down") > 0)
			{
				offsetH := +pixel
			}
			else if(InStr(direction, "middle") > 0)
			{
				offsetX := -pixel
				offsetY := -pixel
				offsetW := +pixel+pixel
				offsetH := +pixel+pixel
			}
			
			; 移動先座標の計算
			x := x + offsetX
			y := y + offsetY
			w := w + offsetW
			h := h + offsetH 
			
			OutputDebug, % "  size 1 = " x " x " y " x " w  " x " h

			; モニタ外に出ないように補正する。
			if(x < 0)
			{				
				; はみ出た幅を計算し、はみ出た分の幅を広げる
				ofw := Abs(x)
				x := 0
				w := % aw.w - (offsetX + ofw)
			}	
			
			OutputDebug, % "  size 2 = " x " x " y " x " w  " x " h

			if(y < 0)
			{
				; はみ出た高さを計算し、はみ出た分の高さを広げる
				ofh := Abs(y)
				y := 0
				h := % aw.h - (offsetY + ofh)
			}
			
			OutputDebug, % "  size 3 = " x " x " y " x " w  " x " h

			if(x + w > am.w)
			{
				w := am.w - x
			}
			
			OutputDebug, % "  size 4 = " x " x " y " x " w  " x " h

			if(y + h > am.h)
			{
				h := am.h - y
			}
		}
		
		if(IncreaseOrDecrese == "decrease")
		{
			if(InStr(direction, "up left") > 0)
			{
				offsetX := +pixel
				offsetY := +pixel
				offsetW := -pixel
				offsetH := -pixel
			}
			if(InStr(direction, "down left") > 0)
			{
				offsetX := +pixel
				offsetW := -pixel
				offsetH := -pixel
			}
			if(InStr(direction, "left") > 0)
			{
				offsetX := +pixel
				offsetW := -pixel
			}
			if(InStr(direction, "up right") > 0)
			{
				offsetY := +pixel
				offsetW := -pixel
				offsetH := -pixel
			}
			if(InStr(direction, "down right") > 0)
			{
				offsetW := -pixel
				offsetH := -pixel
			}
			if(InStr(direction, "right") > 0)
			{
				offsetW := -pixel
			}
			if(InStr(direction, "up") > 0)
			{
				offsetY := +pixel
				offsetH := -pixel
			}		
			if(InStr(direction, "down") > 0)
			{
				offsetH := -pixel
			}
			if(InStr(direction, "middle") > 0)
			{
				offsetX := +pixel
				offsetY := +pixel
				offsetW := -pixel-pixel
				offsetH := -pixel-pixel
			}
			
			; 移動先座標の計算
			x := x + offsetX
			y := y + offsetY
			w := w + offsetW
			h := h + offsetH 

			; ウィンドウが小さくなりすぎた時にウィンドウが移動しないように補正
			if(h < 10 or w < 120)
			{
				x := aw.x
				y := aw.y
				w := aw.w
				h := aw.h
			}
		}

		OutputDebug, % "  size 5 = " x " x " y " x " w  " x " h

		; ウィンドウのボーダーオフセットを加算する
		x := % x - (aw.offset_width / 2)
		w := % w + aw.offset_width
		h := % h + (aw.offset_width / 2)

		; マルチモニタ時の原点を戻す
		x := x - monitorOffsetX
		y := y - monitorOffsetY
		
		OutputDebug, % "  size 6 = " x " x " y " x " w  " x " h

		; サイズ変更する
		aw.WinRestorePlus(aw.id,x, y, w, h)
	}
	
	Do(direction)
	{
		OutputDebug, % "--> Do : " direction
		
		GetKeyState, key_shift, shift
		GetKeyState, key_ctrl, ctrl
		
		if(key_shift == "D" and key_ctrl == "D")
		{
			;this.MoveTo(direction, true)
			return
		}

		if(key_shift == "D")
		{
			this.ChangeWindowSize(direction, "decrease")
			return
		}
		
		if(key_ctrl == "D")
		{		
			;this.MoveTo(direction, false)
			this.ChangeWindowSize(direction, "increase")
			return
		}
		
		this.MoveTo(direction, true)	
		return
	}
	
	RunUndo()
	{		
		OutputDebug, % "Undo : " this.undo.length()

		; アンドゥすることがなければ→終了
		if(this.undo.length() < 1)
			return

		; 一つ前のウィンドウを取得する
		aw := this.undo[1]
		this.undo.Remove(1)
		OutputDebug, % "Undo : " aw.id ", title : " aw.title

		; ウィンドウ位置を戻す
		aw.WinRestorePlus()
	}

	MoveToNextMonitor()
	{	
		OutputDebug, % "--> MoveToNextMonitor"

		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
		{
			OutputDebug, % "    --> no active window"
			return false
		}
		
		; アクティブウィンドウがあるモニタを取得→無ければ終了
		currentmon := this.monitors.Intersect(aw)
		if(currentmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
		
		; アクティブウィンドウがある次にモニタを取得→無ければ終了
		targetmon := this.monitors.NextMonitor(currentmon)
		if(targetmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
				
		; プライマリモニタ以外にウィンドウがある場合、座標がマイナスになっている場合がある。
		; 座標がマイナスだと計算が面倒なので、ひとまずウィンドウのx,y座標を原点(0,0)にしてから
		; 移動先座標の計算をして、移動直前に原点を移動先モニタの原点に戻すことにする。
		monitorOffsetX := currentmon.left * -1
		monitorOffsetY := currentmon.top * -1
		x := aw.x + monitorOffsetX
		y := aw.y + monitorOffsetY
		w := aw.w
		h := aw.h

		; 現在のモニタでのウィンドウの座標と大きさのパーセンテージを取得する
		; 原点から30%のところにあり、モニタの10%幅だ、など。
		px := x / currentmon.w
		py := y / currentmon.h
		pw := w / currentmon.w
		ph := h / currentmon.h

		;OutputDebug, % "px = " px ", py = " py ", pw = " pw ", ph = " ph
		
		; 現在の割合から、移動先モニタの割合を計算する
		x := targetmon.w * px
		y := targetmon.h * py
		w := targetmon.w * pw
		h := targetmon.h * ph
		
		;OutputDebug, % "x = " x ", y = " y ", w = " w ", h = " h

		; モニタの原点を更新
		x := x + targetmon.left
		y := y + targetmon.top
		
		; 移動する。
		aw.WinRestorePlus(aw.id, x, y, w, h)
	}

	CursorMoveToNextMonitor()
	{			
		CoordMode,Mouse,Screen
		MouseGetPos, mx, my
		
		OutputDebug, % "--> CursorMoveToNextMonitor : " mx " x " my
		
		; カーソルがあるモニタを取得→無ければ終了
		currentmon := this.monitors.ContainsXY(mx, my)
		if(currentmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}	

		; アクティブウィンドウがある次にモニタを取得→無ければ終了
		targetmon := this.monitors.NextMonitor(currentmon)
		if(targetmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
		
		OutputDebug, % currentmon.left " x " currentmon.top

		; プライマリモニタ以外にウィンドウがある場合、座標がマイナスになっている場合がある。
		; 座標がマイナスだと計算が面倒なので、ひとまずウィンドウのx,y座標を原点(0,0)にしてから
		; 移動先座標の計算をして、移動直前に原点を移動先モニタの原点に戻すことにする。
		; →currentmon.left * 1の処理がそうだ。
		; 
		; 現在のモニタでのカーソル座標位置をパーセンテージで取得する
		; 中心ならpx = 0.5, py = 0.5、上から30%ならpy = 0.3等。
		; 原点から30%のところにある、など。
		cx := mx + (currentmon.left * -1)
		cy := my + (currentmon.top * -1)
		px := cx / currentmon.w
		py := cy / currentmon.h

		; 移動先モニタでのカーソル位置を計算する
		; 現在のカーソル位置が現在のモニタの中央なら、移動先も中央に移動する。
		tx := px * targetmon.w
		ty := py * targetmon.h
				
		; モニタの原点を戻す
		tx := tx + targetmon.left
		ty := ty + targetmon.top

		; カーソルを移動する
		targetmon.Debug()
		OutputDebug, % "    --> moveto " tx " x " ty
		MouseMove tx, ty, 0
	}

	ActiveNextWindow()
	{		
		OutputDebug, % "--> ActiveNextWindow()"

		; アクティブなウィンドウを取得
		aw := this.GetActiveWindow()
		if(aw = false)
			return False

		OutputDebug, % "  ActiveWindow : " aw.Title

		; 次のウィンドウを取得
		nw := this.wc.GetNextWindow(aw)
		if(nw = false)
			return False
		OutputDebug, % "  Next  Window : " nw.Title

		; 次のウィンドウをアクティブにする。
		nw.Debug()
		nw.Activate()

		; マウスカーソルをアクティブウィンドウの上に移動する
		nw.callcursor()		
	}

}

class INI
{

	__New()
	{
		return this
	}
	
	; INIファイルを読み込み、ActionクラスやSequenceクラスのインスタンスを生成する
	; 生成したActionクラスの配列を返す
	Read(winsplit)
	{
		; INIファイル読み込みの準備
		OutputDebug, --> Read INI
		OutputDebug, ScriptDir  : %A_ScriptDir%
		SetWorkingDir, %A_ScriptDir%\AHK-WinSplit
		OutputDebug, WorkingDir : %A_WorkingDir%

		; ■Configの読込
		IniRead, inivalue, AHK-WinSplit.ini, Config, WindowChangeSize
		if(inivalue != "ERROR")
		{
			winsplit.WindowChangeSize := inivalue
		}

		; ■アクションの読込
		; INIファイルから [Action-1]..., [Action-2]..., [Action-3]...
		; と読み込みエラーが発生したら(セクションが無かったら)停止する

		actions := []

		Loop
		{
			; セクション名を生成しセクションを読み込む
			secname = Action-%A_Index%			
			IniRead, name, AHK-WinSplit.ini, %secname%, name

			; セクションが無ければ終わり
			if(name == "ERROR")
				break

			; アクション名は小文字に統一
			StringLower, name, name
			OutputDebug, --> Actionname = %name% 
			
			; アクションを生成する
			act := new Action(name)
			actions.Insert(act)

			; キー(シーケンス)を取得する
			Loop
			{
				; キー名を生成しキーを読み込む
				keyname = Seq%A_Index%
				IniRead, val, AHK-WinSplit.ini, %secname%, %keyname% 
				if(val = "ERROR")
					break	
				OutputDebug, %secname% %keyname% %val%

				; 文字列を分解する
				strs := StrSplit(val, ",")

				; シーケンスを生成する
				seq := new Sequence(strs[1], strs[2], strs[3], strs[4])
				act.Add(seq)
			}	

		} ; end of Loop

		winsplit.action := actions

		return actions
	}

}

class WinCollection
{	
	__New(monitors)
	{		
		; モニタ情報を格納するリストを設定
		this.monitors := monitors

		; EnumWindowsCallBackがウィンドウハンドルを一時的に格納する配列
		;   EnumWindows->EnumWindowsCallBackが格納する
		this.handle := Object()

		; EnumWindowsを受けるコールバックを登録する
		; https://www.autohotkey.com/boards/viewtopic.php?t=6849
		if not this.EnumAddress
			this.EnumAddress := RegisterCallback(this.EnumWindowsCallBack,"Fast",,&this)

		; Due to fast-mode, this setting will go into effect for the callback too.
		DetectHiddenWindows On

		return this
	}
		
	EnumWindowsCallBack(hwnd, lParam)
	{		
		; https://www.autohotkey.com/boards/viewtopic.php?t=6849
		; 上記URLの解説では、callback第1パラメータがthisで渡ってくるので、EventInfoにthisを入れておいて
		; それをthisに代入するらしい。
		hwnd := this
		this := object(a_eventinfo)

		; 対象のウィンドウだったらwcにハンドルを格納する
		if(this.IsWindow(hwnd) == true)
			this.handle.Push(hwnd)
		
		; コールバックを続ける
		return true
	}

	GetNextWindow(w)
	{		
		OutputDebug, % "--> GetNextWindow()"

		; ウィンドウがあるモニタを取得
		currentMonitor := this.monitors.Intersect(w)

		; idの次のウィンドウを返す
		this.GetWindows()
		found := false
		Loop % this.wins.length()
		{		
			; Windowインスタンスを取得
			tw := this.wins[A_Index]

			; 属しているモニタが違う場合はスキップする
			tm := this.monitors.Intersect(tw)
			if(tm != currentMonitor)
				continue

			; フラグが立っていたら、そのウィンドウを返すが最小化されていたらさらに次にする。
			if(found == true)
			{
				if(tw.IsIconic())
					continue
				return tw
			}
			
			; 自分のウィンドウを見つけたらフラグを立てて次のループのウィンドウを返す
			if(tw.id == w.id)
			{
				found := true
				continue
			}
		}
	}

	GetWindows()
	{
		OutputDebug, % "--> GetWindows()"
		
		; 取得したウィンドウハンドルからウィンドウ情報を生成し格納する配列
		; ハンドル取得後以下のLoop内で格納する
		this.handle := Object()
		this.wins := Object()
		
		; ウィンドウハンドルを取得する
		; ハンドルの取得は、EnumWindows->EnumWindowsProc->IsWindowメソッドで行われる。
		; 1. EnumWindowsが呼ばれる。
		; 2. EnumWindowsCallBackコールバックが呼ばれる。ハンドルをthis.handleに格納していく。
		; 3. this.handleに格納が終わったら、ハンドルからWindowインスタンスを生成し、this.winsに格納する。
		; という流れで格納する。
		; GetWindowsメソッドが呼ばれるたびに this.handle、this.winsは初期化される。
		DllCall("EnumWindows", Ptr, this.EnumAddress, Ptr, 0)
		OutputDebug, % "  found windows : " this.handle.length()
		
		; 取得したウィンドウハンドルからWindowインスタンスを生成する
		Loop % this.handle.length()
		{		
			; Windowインスタンスを生成
			hwnd := this.handle[A_Index]
			w := Window.Make(hwnd)
			w.Debug()

			; 配列に格納する
			this.wins.Push(w)
		}

		return this
	}

	; 現在のウィンドウ情報を配列の指定したインデックスに格納する
	SaveWindows(index)
	{
		OutputDebug, % "--> SaveWindows()"
		
		; 取得したウィンドウハンドルからウィンドウ情報を生成し格納する配列
		; ハンドル取得後以下のLoop内で格納する
		this.win[index] := Object()
		
		; ウィンドウハンドルを取得する
		this.GetWindows()
		
		; 配列に格納する
		this.win[index] := this.wins

		/*
		タスクバーからアプリ一覧を取得する試み。
		試しに実装。ToolbarWindow32のハンドルが0。何でだろう？
		; http://hsp.tv/play/pforum.php?mode=pastwch&num=32771
		OutputDebug, % " save windows = " . this.win[this.selectedindex].length()

		r1 := DllCall("FindWindowEx", Ptr, 0 , Ptr, 0, "str", "Shell_TrayWnd", Ptr, 0)
		r2 := DllCall("FindWindowEx", Ptr, r1, Ptr, 0, "str", "TrayNotifyWnd", Ptr, 0)
		r3 := DllCall("FindWindowEx", Ptr, r1, Ptr, 0, "str", "ReBarWindow32", Ptr, 0)
		r4 := DllCall("FindWindowEx", Ptr, r3, Ptr, 0, "str", "MSTaskSwWClass", Ptr, 0)
		r5 := DllCall("FindWindowEx", Ptr, r4, Ptr, 0, "str", "ToolbarWindow32", Ptr, 0)

		OutputDebug, % r1 ", " r2 ", " r3 ", " r4 ", " r5
		*/	

		return this		
	}

	; 保存してあるウィンドウ配置を戻す
	LoadWindows(index)
	{
		OutputDebug, % "--> LoadWindows(), Wins = " this.win[this.selectedindex].length()

		; 格納番号を格納する
		this.selectedindex := index

		; 格納してあるウィンドウ情報を利用してウィンドウ位置を設定する
		Loop % this.win[this.selectedindex].length()
		{		
			; リストからWindowインスタンスを出してくる
			; 出すときはリストの最後から持ってくる。そうしないとzオーダーが逆になり、上のウィンドウが下になってしまう。
			w := this.win[this.selectedindex][this.win[this.selectedindex].length() - A_Index + 1]
			w.Debug()

			; ウィンドウを配置する
			w.RestorePos()
		}

		return this
	}

	IsWindow(hwnd)
	{
		; ウィンドウ状態を取得する
		r := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Uint", -16) ; GWL_STYLE
		exr := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Uint", -20) ; GWL_EXSTYLE

		;WinGetTitle, title, ahk_id %hwnd%
		;OutputDebug, % title

		; ウィンドウスタイル一覧
		; https://sites.google.com/site/autohotkeyjp/reference/misc/Styles

		; 可視状態ではない : WS_VISIBLE = 0x10000000
		if(!(r & 0x10000000))
			return false

		; 操作可能ではない : WS_DISABLED = 0x08000000
		if (r & 0x08000000)
			return false

		; ツールウインドウではない : WS_EX_TOOLWINDOW == 0x00000080			
		if (exr & 0x00000080)
			return false
		
		; 幅、高さが共に0だ
		; 中断中のUWPを除く(中断中のUWPはxとyが-32000)
		WinGetPos,x,y,w,h,ahk_id %hwnd%					
		if(w == 0 && h == 0)
			return false

		; WS_EX_APPWINDOW = 0x00040000
		; ここのコードを有効にすると何故かVisual Studioが非対称になってしまうので無効にする。
		;if(exr & 0x00040000)
		;	return false
		
		; 親がないウィンドウを除外		
		hParent = DllCall("GetParent", "Ptr", hwnd)
		if(hParent == 0)
			return false

		; 非表示の親を持つ、WS_POPUP属性のウインドウを除外する
		if(hParent != 0)
		{
			hParentr := DllCall("GetWindowLongPtr", "Ptr", hParent, "Uint", -16) ; GWL_STYLE
			hParentexr := DllCall("GetWindowLongPtr", "Ptr", hParent, "Uint", -20) ; GWL_EXSTYLE
			
			; 可視状態 : WS_VISIBLE = 0x10000000
			if ((hParentr & 0x10000000) == 0) 
			{	
				; 操作可能である : WS_DISABLED = 0x08000000
				if ((hParentr & 0x08000000) == 0)
				{		
					; WS_POPUP = 0x80000000
					if ((hParentr & 0x80000000) != 0)
					{	
						return false
					}
				}
			}
		}
		
		; UWPアプリ
		; "Windows.UI.Core.CoreWindow"という子ウィンドウを持たないウィンドウは除外したいが
		; 最小化しているUWPアプリは、この子ウィンドウを持たないので対象外になってしまう。
		; 
		; Tascherでは色々処理をしているが、ここでは簡略化してUWPで最小化されていたら対象とする。
		if(exr & 0x00200000)
		{			
			rFWE := DllCall("FindWindowEx", Ptr, hwnd, Ptr, 0, "str", "Windows.UI.Core.CoreWindow", Ptr, 0)
			;OutputDebug, % "FindWindowEx = " . title . ", hChild = " . rFWE
			if(rFWE == 0)
			{
				; 最小化されているウィンドウは対象にする
				if(r & 0x20000000)
					return true
				
				; その他は対象外
				return false
			}
		}
		
		return true

	} ; IsWindow

} ; WinCollection
