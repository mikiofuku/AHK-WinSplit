; + Shift
; ^ Control
; ! Alt
; # Windows

; https://so-zou.jp/software/tool/system/auto-hot-key/basic-usage/functions.htm
; http://ahkwiki.net/Objects
; https://poimono.exblog.jp/19210175/
; http://eternalwindows.jp/winbase/window/window13.html
; https://odashi.hatenablog.com/entry/20110911/1315730376
; https://riptutorial.com/ja/autohotkey/example/15621/�P���Ȕz��̍쐬�Ə�����

; ToDo
;	Save windows position
; 	Win10���z�f�X�N�g�b�v�ɑΉ�����
;		https://blog.tmyt.jp/entry/2015/09/14/193840
;		�L�[���[�h : windows10 ���z�f�X�N�g�b�v �E�B���h�E�ʒu api

class Action
{
	__New(name)
	{
		this.name := name
		this.count := 1
		
		; �V�[�P���X���i�[���郊�X�g�𐶐�
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
		; �V�[�P���X���擾����
		s := false
		s := this.seq[this.count]
		
		; �g�O���ԍ����C���N�������g����
		this.count := this.count + 1
		
		; �g�O���ԍ����i�[���Ă���seq�����傫���Ȃ�����1�ɖ߂�
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
	; ���j�^�͈͂��i�[����
	__New(no,left,top,right,bottom)
	{
		this.no     := no
		this.left   := left
		this.top    := top
		this.right  := right
		this.bottom := bottom

		; ���Ƌt�����v�Z
		; �v���C�}���X�N���[���̍�����W�� 0,0��OS�S�̂̌��_�ɂȂ�B
		; �Z�J���_���X�N���[�����v���C�}���X�N���[�������ɂ���ꍇ�A-1920,0,0,1024���ƂȂ�Bs
		this.w := right - left
		this.h := bottom - top

		OutputDebug, % "     --> Monitor = " no
		OutputDebug, % "      " left " x " top " x " right " x " Bottom " : width = " this.w ", height = " this.h
	}
	
	; ���W�����̃��j�^�͈͓��ɂ��邩�ǂ���
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
	; ���j�^�͈͂��i�[����
	__New()
	{
		; ���j�^���擾����
		this.GetMonitorInfo()
		
		; ���j�^�̉𑜓x���ς�����烂�j�^�����擾������
		OnMessage(0x7E, ObjBindMethod(this, "WM_DISPLAYCHANGE"))
	}
	
	WM_DISPLAYCHANGE(wParam, lParam)
	{
		OutputDebug, % "--> Change resolution"
		this.GetMonitorInfo()
	}
	
	GetMonitorInfo()
	{
		; ���j�^�����擾
		SysGet, count, MonitorCount

		OutputDebug, % "     GetMonitorInfo count = " count

		; ���j�^���i�[���郊�X�g�𐶐�
		this.list := Object()
				
		; ���j�^�������[�v���񂵂āA���j�^�͈̓I�u�W�F�N�g�𐶐������X�g�Ɋi�[����
		Loop, % count
		{
			SysGet,workarea,MonitorWorkArea,% A_Index		
			this.list.Push(new Monitor(A_Index, workarealeft,workareatop,workarearight,workareabottom))	
		}
	}
	
	; �w�肵���E�B���h�E���ǂ̃��j�^�ɓ����Ă��邩�H
	Contains(aw)
	{		
		; �E�B���h�E�g����ʊO�ɏo�Ă���ƁA���̃��j�^�ɓ����Ă���H�Ƃ������f���ԈႦ��̂�
		; �i�g�����j�^�̊O�ɏo�Ă��Ă��̃��j�^�ɓ����Ă��Ȃ��ƌ딻�ʂ���̂Łj		
		; �g���I�t�Z�b�g����B
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
	
	; �w�肵�����W���ǂ̃��j�^�ɓ����Ă��邩�H
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
	
	; �w�肵�����W���ǂ̃��j�^�ɓ����Ă��邩�H
	Intersect(aw)
	{		
		; �E�B���h�E�g����ʊO�ɏo�Ă���ƁA���̃��j�^�ɓ����Ă���H�Ƃ������f���ԈႦ��̂�
		; �i�g�����j�^�̊O�ɏo�Ă��Ă��̃��j�^�ɓ����Ă��Ȃ��ƌ딻�ʂ���̂Łj		
		; �g���I�t�Z�b�g����B
		x := aw.x + aw.offset_width
		y := aw.y + aw.offset_width

		tmparea := 0
		tmpindex := 0
		for index, m in this.list
		{
			area := m.Intersect(x,y, aw.w, aw.h)

			; �ő�l���X�V���A���̃C���f�b�N�X���X�V����B
			if(area > tmparea)
			{
				tmpindex := A_Index
				tmparea := area
			}
		}

		OutputDebug, % "  on monitor no. = " tmpindex 
		
		return this.list[tmpindex]
	}

	; �w�肵���E�B���h�E�����郂�j�^�̎��̃��j�^���擾����
	NextMonitor(aw)
	{
		OutputDebug % "  --> NextMonitor no = " aw.title
		
		; �A�N�e�B�u�E�B���h�E�����郂�j�^���擾��������ΏI��
		am := this.Intersect(aw)
		if(am = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
						
		; �ォ�珇�ԂɌ��Ă���
		count := this.list.length()
		next := False
		Loop, % count
		{
			m := this.list[A_Index]
			
			if(m.no = am.no)
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

		; �Ȃ���Ή����珇�ԂɌ��Ă���
		i := count
		next := False
		Loop, % count
		{
			m := this.list[i]
			i--
			
			if(m.no = am.no)
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
	
	; �w�肵���n���h����Window�I�u�W�F�N�g������ĕԂ�
	Make(id)
	{		
		; �A�N�e�B�u�ȃE�B���h�E�ƃ^�C�g���A�T�C�Y���擾
		WinGetTitle, title, ahk_id %id%
		WinGetPos, ax, ay, aw, ah, ahk_id %id%
		
		return new Window(id, title, ax, ay, aw, ah)
	}

	; �R���X�g���N�^
	__New(id, title, x, y, w, h)
	{
		OutputDebug, % "  --> Make Window"
		this.id := id
		this.title := title
		this.x := x
		this.y := y
		this.w := w
		this.h := h

		; �E�B���h�E�̃p�X���擾����
		WinGet, path, ProcessPath, ahk_id %id%
		this.path := path
		
		; �E�B���h�E�̃{�[�_�[�I�t�Z�b�g���擾����
		r := this.GetWindowBorderOffset(this.id)
		this.offset_width := r[1]
		this.offset_height := r[2]

		; �R�}���h�v�����v�g�E�B���h�E�̏ꍇ�́A�T�C�Y��15�ɌŒ肷��B
		if(InStr(this.path, "cmd.exe", False))
		{
			this.offset_width := 15
		}
		
		; �E�B���h�E��Ԃ��i�[���Ă���
		this.r := DllCall("GetWindowLongPtr", "Ptr", this.id, "Uint", -16) ; GWL_STYLE
		this.exr := DllCall("GetWindowLongPtr", "Ptr", this.id, "Uint", -20) ; GWL_EXSTYLE
		this.Zoomed := this.IsZoomed()
		this.Iconic := this.IsIconic()
		this.HugApp := this.IsHungAppWindow()
		this.Enabled := this.IsWindowEnabled()
		this.TopMost := this.IsTopMost()
	}

	; �w�肵���n���h���̃E�B���h�E�̃{�[�_�[���擾���ݒ肷��
	GetWindowBorderOffset(id)
	{
		; �E�B���h�E�̃T�C�Y���擾
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
		OutputDebug, % "    Window pos : " wLeft " , " wTop  " , " wRight " , " wBottom " : " wWidth " x " wHeight
		
		; �E�B���h�E�̃N���C�A���g�̈���擾
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

		; �̈�̍� = �{�[�_�[���v�Z����
		bw := wWidth - cWidth
		bh := wHeight - cHeight
		OutputDebug % "    Window border : " bw " x " bh

		return [bw, bh]
	}

	; -------------------------------
	;
	; �E�B���h�E���擾���\�b�h
	;
	; -------------------------------

	; �ő剻���Ă��邩�ǂ����擾����
	IsZoomed()
	{		
		r := DllCall("IsZoomed", "UInt", this.id)
		return r == 1 ? true : false
	}
	
	; �ŏ������Ă��邩�ǂ����擾����
	IsIconic()
	{		
		r := DllCall("IsIconic", "UInt", this.id)
		return r == 1 ? true : false
	}
	
	; �����Ȃ����H�擾����
	IsHungAppWindow()
	{
		r := DllCall("IsHungAppWindow", "UInt", this.id)
		return r == 1 ? true : false
	}

	; �L���ȃE�B���h�E���H�擾����
	IsWindowEnabled()
	{
		r := DllCall("IsWindowEnabled", "UInt", this.id)
		return r == 1 ? true : false
	}

	; ��ɍőO�ʂ��H�擾����
	IsTopMost()
	{		
		; �A�N�e�B�u�E�B���h�E���őO�ʂ��ǂ������ׂ�
		; GetWindowLong��GWL_EXSTYLE(�g���E�B���h�E�X�^�C��)�̖߂�l���A
		;   WS_EX_TOPMOST == 0x8
		; ���܂܂�Ă�����őO��
		id := this.id
		WinGet,exstyle, ExStyle, ahk_id %id%
		return exstyle & 0x8 == 0x8 ? true : false
	}

	; -------------------------------
	;
	; �E�B���h�E�ړ��Ȃǂ̃��\�b�h
	;
	; -------------------------------

	; �A�N�e�B�u�E�B���h�E���ő剻�������͍ŏ�������Ă������������	
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

	; �E�B���h�E����ɑS��
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

	; �A�N�e�B�u�E�B���h�E�̍ő剻���ʏ���g�O������	
	Toggle()
	{		
		; �A�N�e�B�u�E�B���h�E���ő剻����Ă������������		
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

		; ���X�A�ŏ�������Ă�����ŏ�������
		if(this.Iconic == 1)
		{	
			WinMinimize, % "ahk_id" this.id
			processed := true
		}

		; ���X�A�ő剻����Ă�����ő剻����
		else if(this.Zoomed == 1)
		{	
			WinMaximize, % "ahk_id" this.id
			processed := true
		}

		; ���X�A���ʂŁA�ŏ�������Ă����灨��������
		else if(this.Iconic == 0 && this.IsIconic() == 1)
		{
			this.Restore()
			processed := true
		}

		; ���X�A���ʂŁA�ő剻����Ă����灨��������
		else if(this.Zoomed == 0 && this.IsZoomed() == 1)
		{
			this.Restore()	
			processed := true
		}
		
		; �őO�ʂȂ�őO�ʂɂ���
		if(this.TopMost == 1)
		{
			this.AlwaysOnTop(true)
		}

		; �S�ʂɈړ�����
		id := this.id
		WinSet, Top,,ahk_id %id%

		; �ړ�����
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
	; WinSplit�N���X�����̃��\�b�h
	;
	; -------------------------------

	__New(monitors, wincollection)
	{
		OutputDebug, -------------------

		; ���j�^�����i�[���郊�X�g��ݒ�
		this.monitors := monitors

		; Windows Collection��ݒ�
		this.wc := wincollection
		
		; �A�N�V�������i�[���郊�X�g�𐶐�
		this.action := Object()

		; �A���h�D�p�̃A�N�e�B�u�E�B���h�E���i�[���郊�X�g�𐶐�
		this.undo := Object()

		; �f�t�H���g�̃E�B���h�E�T�C�Y�ύX�T�C�Y��ݒ�
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

		; ���s����A�N�V�������擾����
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

		; ���s����A�N�V�������擾����
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
		; �A�N�e�B�u�ȃE�B���h�E�ƃ^�C�g���A�T�C�Y���擾
		WinGet,id,ID,A
		WinGetTitle, title, ahk_id %id%
		WinGetPos, ax, ay, aw, ah, ahk_id %id%
		
		; �A�N�e�B�u�E�B���h�E�̃^�C�g�����󗓂́A�f�X�N�g�b�v��������Ȃ��̂ŉ������Ȃ�
		if(title =)
			return false
		if(title = "Program Manager")
			return false
		RegExMatch(title, " - �����[�g �f�X�N�g�b�v", $)
		if($ !=)
			return false

		aw := new Window(id, title, ax, ay, aw, ah)
		aw.Debug()

		return aw
	}

	; -------------------------------
	;
	; �E�B���h�E�ړ��Ȃǂ̃��\�b�h
	;
	; -------------------------------

	; �A�N�e�B�u�E�B���h�E���őO�ʂɂ���
	TopMostToggle()
	{		
		OutputDebug, --> TopMost
		
		; �A�N�e�B�u�ȃE�B���h�E���擾
		aw := this.GetActiveWindow()
		if(aw = false)
			return false

		; �g�O������
		aw.AlwaysOnTopToggle()
	}
	
	; �ő剻���ʏ���g�O������
	Toggle()
	{
		OutputDebug, --> Toggle

		; �A�N�e�B�u�ȃE�B���h�E���擾
		aw := this.GetActiveWindow()
		if(aw = false)
			return false

		; �E�B���h�E��Ԃ��g�O������
		aw.Toggle()
	}

	; �A�N�e�B�u�E�B���h�E���ړ�����
	MoveTo(actname, fit)
	{
		OutputDebug, % "--> MoveTo : " actname ", fit = " fit

		; �A�N�e�B�u�ȃE�B���h�E���擾
		aw := this.GetActiveWindow()
		if(aw = false)
		{
			OutputDebug, % "    --> no active window"
			return false
		}
		
		; �A�N�e�B�u�E�B���h�E�����郂�j�^���擾��������ΏI��
		am := this.monitors.Intersect(aw)
		if(am = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
			
		; ���s����A�N�V�������擾���遨������ΏI��
		action := this.GetAction(actname)
		if(action = false)
		{
			OutputDebug, % "    --> no action"
			return false
		}
		; ���̑��A�N�V�����̃V�[�P���X�ԍ������Z�b�g����
		this.ClearActionCount(action.name)

		; ���s����V�[�P���X���擾���遨������ΏI��
		seq := action.GetSequence()
		if(seq = false)
		{
			OutputDebug, % "    --> no seq"
			return false
		}
		
		; �ړ�����v�Z
		x := (am.w/100) * seq.x
		y := (am.h/100) * seq.y
		w := (am.w/100) * seq.w
		h := (am.h/100) * seq.h
		
		; �E�B���h�E����������H
		if(seq.IsVariable())
		{
			; IsVariable�̏ꍇ�A�ׂ̃E�B���h�E�ɂ�������
			; WinCollection�ł�������Ώۂ̃E�B���h�E���擾����
			; �܂�GetWindows��EnumWindows�őΏۂ̃E�B���h�E��S���擾����B
			; ���ɁA��������E�B���h�E(�����̎��ɗ񋓂��ꂽ�E�B���h�E)���擾����B
			; �擾���o������A����������W���v�Z����
			this.wc.getwindows()
			rw := this.wc.GetNextWindow(aw)

			OutputDebug, % "   Reference window --> "
			rw.Debug()	

			; ���t�@�����X�E�B���h�E���Ȃ���΁A�I������			
			;   ���ړ����Ȃ��ꍇ�́A���̃V�[�P���X�����s����
			if(rw = )
			{
				OutputDebug, % "   Reference window none."
				this.MoveTo(actname, fit)
				return
			}

			; �E�B���h�E������������W���v�Z����
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
				
				; Reference Window����ʂ����ς������������Ȃ�
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
				
				; Reference Window���[�ɂ������Ă��遨�������Ȃ�
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
				
				; Reference Window��ʏ�[�ɂ������Ă��遨�������Ȃ�
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
				
				; Reference Window��ʉ��[�ɂ������Ă��遨�������Ȃ�
				if(rw.h >= am.h)
					return 
			}		

			; �����Ȃ��Ȃ�����ړ����Ȃ�
			;   ���ړ����Ȃ��ꍇ�́A���̃V�[�P���X�����s����
			if(w < 0 || y < 0)
			{
				OutputDebug, % "   no area. w = " w ", y = " y
				this.MoveTo(actname, fit)
				return
			}
		}
		
		; �E�B���h�E�̃{�[�_�[�I�t�Z�b�g�����Z����
		x := % x - (aw.offset_width / 2)
		w := % w + aw.offset_width
		h := % h + (aw.offset_width / 2)
		
		; ���j�^�̃I�t�Z�b�g�����Z����(�����̃��j�^�ɂ���̂����Z����)
		x := x + am.left
		y := y + am.top
		
		; �A�N�e�B�u�E�B���h�E��ۑ����Ă���
		this.undo.Insert(1, aw)

		; �A�N�e�B�u�E�B���h�E���ő剻����Ă������������		
		aw.Restore()
		
		; �ړ�����		
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
	
	; �A�N�e�B�u�E�B���h�E�̃T�C�Y��ύX����
	ChangeWindowSize(direction, IncreaseOrDecrese)
	{
		OutputDebug, % "--> ChangeWindowSize : "  direction " : " IncreaseOrDecrese ", pixel : " this.WindowChangeSize
		pixel := this.WindowChangeSize

		; �A�N�e�B�u�ȃE�B���h�E���擾
		aw := this.GetActiveWindow()
		if(aw = false)
			return false
			
		; �A�N�e�B�u�E�B���h�E�����郂�j�^���擾��������ΏI��
		am := this.monitors.Intersect(aw)
		if(am = false)
			return false
		
		; �A�N�e�B�u�E�B���h�E��ۑ����Ă���(���X�g�̍ŏ���)
		this.undo.Insert(1, aw)

		; �A�N�e�B�u�E�B���h�E���ő剻����Ă������������		
		aw.Restore()

		; �E�B���h�E�T�C�Y�ύX���l���v�Z����
		offsetX := 0
		offsetY := 0
		offsetW := 0
		offsetH := 0
		StringLower, direction, direction
		StringLower, IncreaseOrDecrese, IncreaseOrDecrese
		
		; �v���C�}�����j�^�ȊO�ɃE�B���h�E������ꍇ�A���W���}�C�i�X�ɂȂ��Ă���ꍇ������B
		; ���W���}�C�i�X���Ɖ�ʂ̂͂ݏo�����肪�ʓ|�Ȃ̂ŁA�ЂƂ܂��E�B���h�E��x,y���W�����_(0,0)�ɂ��Ă���
		; �͂ݏo����������āA�ړ����O�Ɍ��_��߂����Ƃɂ���B
		monitorOffsetX := am.left * -1
		monitorOffsetY := am.top * -1
		x := aw.x + monitorOffsetX
		y := aw.y + monitorOffsetY
		w := aw.w
		h := aw.h 
		
		; �E�B���h�E�����j�^����͂ݏo�����������ۂɁA�g�̃T�C�Y(�E�B���h�E�̈�ƃN���C�A���g�̍�)�������
		; �v�Z���ʓ|�Ȃ̂ŁA�������񖳂����Ă��Ƃ��������
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
			
			; �ړ�����W�̌v�Z
			x := x + offsetX
			y := y + offsetY
			w := w + offsetW
			h := h + offsetH 
			
			OutputDebug, % "  size 1 = " x " x " y " x " w  " x " h

			; ���j�^�O�ɏo�Ȃ��悤�ɕ␳����B
			if(x < 0)
			{				
				; �͂ݏo�������v�Z���A�͂ݏo�����̕����L����
				ofw := Abs(x)
				x := 0
				w := % aw.w - (offsetX + ofw)
			}	
			
			OutputDebug, % "  size 2 = " x " x " y " x " w  " x " h

			if(y < 0)
			{
				; �͂ݏo���������v�Z���A�͂ݏo�����̍������L����
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
			
			; �ړ�����W�̌v�Z
			x := x + offsetX
			y := y + offsetY
			w := w + offsetW
			h := h + offsetH 

			; �E�B���h�E���������Ȃ肷�������ɃE�B���h�E���ړ����Ȃ��悤�ɕ␳
			if(h < 10 or w < 120)
			{
				x := aw.x
				y := aw.y
				w := aw.w
				h := aw.h
			}
		}

		OutputDebug, % "  size 5 = " x " x " y " x " w  " x " h

		; �E�B���h�E�̃{�[�_�[�I�t�Z�b�g�����Z����
		x := % x - (aw.offset_width / 2)
		w := % w + aw.offset_width
		h := % h + (aw.offset_width / 2)

		; �}���`���j�^���̌��_��߂�
		x := x - monitorOffsetX
		y := y - monitorOffsetY
		
		OutputDebug, % "  size 6 = " x " x " y " x " w  " x " h

		; �T�C�Y�ύX����
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
			this.MoveTo(direction, false)
			;this.ChangeWindowSize(direction, "increase")
			return
		}
		
		this.MoveTo(direction, true)	
		return
	}
	
	RunUndo()
	{		
		OutputDebug, % "Undo : " this.undo.length()

		; �A���h�D���邱�Ƃ��Ȃ���΁��I��
		if(this.undo.length() < 1)
			return

		; ��O�̃E�B���h�E���擾����
		aw := this.undo[1]
		this.undo.Remove(1)
		OutputDebug, % "Undo : " aw.id ", title : " aw.title

		; �E�B���h�E�ʒu��߂�
		aw.WinRestorePlus()
	}

	MoveToNextMonitor()
	{	
		OutputDebug, % "--> MoveToNextMonitor"

		; �A�N�e�B�u�ȃE�B���h�E���擾
		aw := this.GetActiveWindow()
		if(aw = false)
		{
			OutputDebug, % "    --> sno active window"
			return false
		}
		
		; �A�N�e�B�u�E�B���h�E�����郂�j�^���擾��������ΏI��
		currentmon := this.monitors.Intersect(aw)
		if(currentmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
		
		; �A�N�e�B�u�E�B���h�E�����鎟�Ƀ��j�^���擾��������ΏI��
		targetmon := this.monitors.NextMonitor(aw)
		if(targetmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
				
		; �v���C�}�����j�^�ȊO�ɃE�B���h�E������ꍇ�A���W���}�C�i�X�ɂȂ��Ă���ꍇ������B
		; ���W���}�C�i�X���ƌv�Z���ʓ|�Ȃ̂ŁA�ЂƂ܂��E�B���h�E��x,y���W�����_(0,0)�ɂ��Ă���
		; �ړ�����W�̌v�Z�����āA�ړ����O�Ɍ��_���ړ��惂�j�^�̌��_�ɖ߂����Ƃɂ���B
		monitorOffsetX := currentmon.left * -1
		monitorOffsetY := currentmon.top * -1
		x := aw.x + monitorOffsetX
		y := aw.y + monitorOffsetY
		w := aw.w
		h := aw.h

		; ���݂̃��j�^�ł̃E�B���h�E�̍��W�Ƒ傫���̃p�[�Z���e�[�W���擾����
		; ���_����30%�̂Ƃ���ɂ���A���j�^��10%�����A�ȂǁB
		px := x / currentmon.w
		py := y / currentmon.h
		pw := w / currentmon.w
		ph := h / currentmon.h

		;OutputDebug, % "px = " px ", py = " py ", pw = " pw ", ph = " ph
		
		; ���݂̊�������A�ړ��惂�j�^�̊������v�Z����
		x := targetmon.w * px
		y := targetmon.h * py
		w := targetmon.w * pw
		h := targetmon.h * ph
		
		;OutputDebug, % "x = " x ", y = " y ", w = " w ", h = " h

		; ���j�^�̌��_���X�V
		x := x + targetmon.left
		y := y + targetmon.top
		
		; �ړ�����B
		aw.WinRestorePlus(aw.id, x, y, w, h)
	}

	CursorMoveToNextMonitor()
	{	
		OutputDebug, % "--> CursorMoveToNextMonitor"
		
		MouseGetPos, mx, my
		
		; �J�[�\�������郂�j�^���擾��������ΏI��
		currentmon := this.monitors.ContainsXY(mx, my)
		if(currentmon = false)
		{
			OutputDebug, % "    --> no monitor"
			return false
		}
		
		

	}

}

class INI
{

	__New()
	{
		return this
	}
	
	; INI�t�@�C����ǂݍ��݁AAction�N���X��Sequence�N���X�̃C���X�^���X�𐶐�����
	; ��������Action�N���X�̔z���Ԃ�
	Read(winsplit)
	{
		; INI�t�@�C���ǂݍ��݂̏���
		OutputDebug, --> Read INI
		OutputDebug, ScriptDir  : %A_ScriptDir%
		SetWorkingDir, %A_ScriptDir%\AHK-WinSplit
		OutputDebug, WorkingDir : %A_WorkingDir%

		; ��Config�̓Ǎ�
		IniRead, inivalue, AHK-WinSplit.ini, Config, WindowChangeSize
		if(inivalue != "ERROR")
		{
			winsplit.WindowChangeSize := inivalue
		}

		; ���A�N�V�����̓Ǎ�
		; INI�t�@�C������ [Action-1]..., [Action-2]..., [Action-3]...
		; �Ɠǂݍ��݃G���[������������(�Z�N�V����������������)��~����

		actions := []

		Loop
		{
			; �Z�N�V�������𐶐����Z�N�V������ǂݍ���
			secname = Action-%A_Index%			
			IniRead, name, AHK-WinSplit.ini, %secname%, name

			; �Z�N�V������������ΏI���
			if(name == "ERROR")
				break

			; �A�N�V�������͏������ɓ���
			StringLower, name, name
			OutputDebug, --> Actionname = %name% 
			
			; �A�N�V�����𐶐�����
			act := new Action(name)
			actions.Insert(act)

			; �L�[(�V�[�P���X)���擾����
			Loop
			{
				; �L�[���𐶐����L�[��ǂݍ���
				keyname = Seq%A_Index%
				IniRead, val, AHK-WinSplit.ini, %secname%, %keyname% 
				if(val = "ERROR")
					break	
				OutputDebug, %secname% %keyname% %val%

				; ������𕪉�����
				strs := StrSplit(val, ",")

				; �V�[�P���X�𐶐�����
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
		; ���j�^�����i�[���郊�X�g��ݒ�
		this.monitors := monitors

		; EnumWindowsCallBack���E�B���h�E�n���h�����ꎞ�I�Ɋi�[����z��
		;   EnumWindows->EnumWindowsCallBack���i�[����
		this.handle := Object()

		; EnumWindows���󂯂�R�[���o�b�N��o�^����
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
		; ��LURL�̉���ł́Acallback��1�p�����[�^��this�œn���Ă���̂ŁAEventInfo��this�����Ă�����
		; �����this�ɑ������炵���B
		hwnd := this
		this := object(a_eventinfo)

		; �Ώۂ̃E�B���h�E��������wc�Ƀn���h�����i�[����
		if(this.IsWindow(hwnd) == true)
			this.handle.Push(hwnd)
		
		; �R�[���o�b�N�𑱂���
		return true
	}

	GetNextWindow(w)
	{		
		OutputDebug, % "--> GetNextWindow()"

		; �E�B���h�E�����郂�j�^���擾
		currentMonitor := this.monitors.Intersect(w)

		; id�̎��̃E�B���h�E��Ԃ�
		found := false
		Loop % this.wins.length()
		{		
			; Window�C���X�^���X���擾
			tw := this.wins[A_Index]

			; �����Ă��郂�j�^���Ⴄ�ꍇ�̓X�L�b�v����
			tm := this.monitors.Intersect(tw)
			if(tm != currentMonitor)
				continue

			; �t���O�������Ă�����A���̃E�B���h�E��Ԃ����ŏ�������Ă����炳��Ɏ��ɂ���B
			if(found == true)
			{
				if(tw.IsIconic())
					continue
				return tw
			}
			
			; �����̃E�B���h�E����������t���O�𗧂ĂĎ��̃��[�v�̃E�B���h�E��Ԃ�
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
		
		; �擾�����E�B���h�E�n���h������E�B���h�E���𐶐����i�[����z��
		; �n���h���擾��ȉ���Loop���Ŋi�[����
		this.handle := Object()
		this.wins := Object()
		
		; �E�B���h�E�n���h�����擾����
		; �n���h���̎擾�́AEnumWindows->EnumWindowsProc->IsWindow���\�b�h�ōs����B
		; 1. EnumWindows���Ă΂��B
		; 2. EnumWindowsCallBack�R�[���o�b�N���Ă΂��B�n���h����this.handle�Ɋi�[���Ă����B
		; 3. this.handle�Ɋi�[���I�������A�n���h������Window�C���X�^���X�𐶐����Athis.wins�Ɋi�[����B
		; �Ƃ�������Ŋi�[����B
		; GetWindows���\�b�h���Ă΂�邽�т� this.handle�Athis.wins�͏����������B
		DllCall("EnumWindows", Ptr, this.EnumAddress, Ptr, 0)
		OutputDebug, % "  found windows : " this.handle.length()
		
		; �擾�����E�B���h�E�n���h������Window�C���X�^���X�𐶐�����
		Loop % this.handle.length()
		{		
			; Window�C���X�^���X�𐶐�
			hwnd := this.handle[A_Index]
			w := Window.Make(hwnd)
			w.Debug()

			; �z��Ɋi�[����
			this.wins.Push(w)
		}

		return this
	}

	; ���݂̃E�B���h�E����z��̎w�肵���C���f�b�N�X�Ɋi�[����
	SaveWindows(index)
	{
		OutputDebug, % "--> SaveWindows()"
		
		; �擾�����E�B���h�E�n���h������E�B���h�E���𐶐����i�[����z��
		; �n���h���擾��ȉ���Loop���Ŋi�[����
		this.win[index] := Object()
		
		; �E�B���h�E�n���h�����擾����
		this.GetWindows()
		
		; �z��Ɋi�[����
		this.win[index] := this.wins

		/*
		�^�X�N�o�[����A�v���ꗗ���擾���鎎�݁B
		�����Ɏ����BToolbarWindow32�̃n���h����0�B���ł��낤�H
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

	; �ۑ����Ă���E�B���h�E�z�u��߂�
	LoadWindows(index)
	{
		OutputDebug, % "--> LoadWindows(), Wins = " this.win[this.selectedindex].length()

		; �i�[�ԍ����i�[����
		this.selectedindex := index

		; �i�[���Ă���E�B���h�E���𗘗p���ăE�B���h�E�ʒu��ݒ肷��
		Loop % this.win[this.selectedindex].length()
		{		
			; ���X�g����Window�C���X�^���X���o���Ă���
			; �o���Ƃ��̓��X�g�̍Ōォ�玝���Ă���B�������Ȃ���z�I�[�_�[���t�ɂȂ�A��̃E�B���h�E�����ɂȂ��Ă��܂��B
			w := this.win[this.selectedindex][this.win[this.selectedindex].length() - A_Index + 1]
			w.Debug()

			; �E�B���h�E��z�u����
			w.RestorePos()
		}

		return this
	}

	IsWindow(hwnd)
	{
		; �E�B���h�E��Ԃ��擾����
		r := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Uint", -16) ; GWL_STYLE
		exr := DllCall("GetWindowLongPtr", "Ptr", hwnd, "Uint", -20) ; GWL_EXSTYLE

		;WinGetTitle, title, ahk_id %hwnd%
		;OutputDebug, % title

		; �E�B���h�E�X�^�C���ꗗ
		; https://sites.google.com/site/autohotkeyjp/reference/misc/Styles

		; ����Ԃł͂Ȃ� : WS_VISIBLE = 0x10000000
		if(!(r & 0x10000000))
			return false

		; ����\�ł͂Ȃ� : WS_DISABLED = 0x08000000
		if (r & 0x08000000)
			return false

		; �c�[���E�C���h�E�ł͂Ȃ� : WS_EX_TOOLWINDOW == 0x00000080			
		if (exr & 0x00000080)
			return false
		
		; ���A����������0��
		; ���f����UWP������(���f����UWP��x��y��-32000)
		WinGetPos,x,y,w,h,ahk_id %hwnd%					
		if(w == 0 && h == 0)
			return false

		; WS_EX_APPWINDOW = 0x00040000
		; �����̃R�[�h��L���ɂ���Ɖ��̂�Visual Studio����Ώ̂ɂȂ��Ă��܂��̂Ŗ����ɂ���B
		;if(exr & 0x00040000)
		;	return false
		
		; �e���Ȃ��E�B���h�E�����O		
		hParent = DllCall("GetParent", "Ptr", hwnd)
		if(hParent == 0)
			return false

		; ��\���̐e�����AWS_POPUP�����̃E�C���h�E�����O����
		if(hParent != 0)
		{
			hParentr := DllCall("GetWindowLongPtr", "Ptr", hParent, "Uint", -16) ; GWL_STYLE
			hParentexr := DllCall("GetWindowLongPtr", "Ptr", hParent, "Uint", -20) ; GWL_EXSTYLE
			
			; ����� : WS_VISIBLE = 0x10000000
			if ((hParentr & 0x10000000) == 0) 
			{	
				; ����\�ł��� : WS_DISABLED = 0x08000000
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
		
		; UWP�A�v��
		; "Windows.UI.Core.CoreWindow"�Ƃ����q�E�B���h�E�������Ȃ��E�B���h�E�͏��O��������
		; �ŏ������Ă���UWP�A�v���́A���̎q�E�B���h�E�������Ȃ��̂őΏۊO�ɂȂ��Ă��܂��B
		; 
		; Tascher�ł͐F�X���������Ă��邪�A�����ł͊ȗ�������UWP�ōŏ�������Ă�����ΏۂƂ���B
		if(exr & 0x00200000)
		{			
			rFWE := DllCall("FindWindowEx", Ptr, hwnd, Ptr, 0, "str", "Windows.UI.Core.CoreWindow", Ptr, 0)
			;OutputDebug, % "FindWindowEx = " . title . ", hChild = " . rFWE
			if(rFWE == 0)
			{
				; �ŏ�������Ă���E�B���h�E�͑Ώۂɂ���
				if(r & 0x20000000)
					return true
				
				; ���̑��͑ΏۊO
				return false
			}
		}
		
		return true

	} ; IsWindow

} ; WinCollection

ms := new Monitors()
wc := new WinCollection(ms)
ws := new WinSplit(ms, wc)
ws.action := new INI().Read(ws)
