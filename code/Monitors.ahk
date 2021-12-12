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