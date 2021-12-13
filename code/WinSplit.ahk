
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
		;aw.Debug()

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
			rw := this.wc.GetNextWindow(aw, true)

			OutputDebug, % "   Reference window --> " rw.title
			;rw.Debug()	

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

		; 次のウィンドウを取得 (同じモニタでなくてもよい)
		nw := this.wc.GetNextWindow(aw, false)
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