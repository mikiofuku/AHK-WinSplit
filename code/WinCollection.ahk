
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

	GetNextWindow(w, samemonitor)
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
			if(samemonitor == true && tm != currentMonitor)
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
