#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

#include AHK-WinSplit.ahk

ms := new Monitors()
wc := new WinCollection(ms)
ws := new WinSplit(ms, wc)
ws.action := new INI().Read(ws)

; アクティブなウィンドウとタイトル、サイズを取得
sc07B & 1::
aw := ws.GetActiveWindow()
Return

sc07B & u::ws.Do("Up Left")
sc07B & i::ws.Do("Up")
sc07B & o::ws.Do("Up Right")
sc07B & j::ws.Do("left")
sc07B & k::ws.Do("Middle")
sc07B & l::ws.Do("Right")
sc07B & m::ws.Do("Down Left")
sc07B & ,::ws.Do("Down")
sc07B & .::ws.Do("Down Right")
sc07B & space::ws.Do("Layout - SideBar+6Grid")

#IfWinActive,ahk_exe LabVIEW.exe
sc07B & u::ws.Do("LV-Up Left")
sc07B & i::ws.Do("LV-Up")
sc07B & o::ws.Do("LV-Up Right")
sc07B & j::ws.Do("LV-left")
sc07B & k::ws.Do("LV-Middle")
sc07B & l::ws.Do("LV-Right")
sc07B & m::ws.Do("LV-Down Left")
sc07B & ,::ws.Do("LV-Down")
sc07B & .::ws.Do("LV-Down Right")
#IfWinActive

sc07B & h::ws.TopMostToggle()
sc07B & @::ws.Toggle()
sc07B & z::ws.RunUndo()
sc07B & 7::wc.SaveWindows(1)
sc07B & 8::wc.LoadWindows(1)
sc07B & 0::ws.MoveToNextMonitor()
sc07B & -::ws.CursorMoveToNextMonitor()
sc07B & `;::ws.ActiveNextWindow()
