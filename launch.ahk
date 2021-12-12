#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
SetTitleMatchMode,2

#include AHK-WinSplit.ahk

ms := new Monitors()
wc := new WinCollection(ms)
ws := new WinSplit(ms, wc)
ws.action := new INI().Read(ws,"C:\Users\Mikio Fukushima\OneDrive\App\Winutl\Key\AutoHotKey\script\AHK-WinSplit - mikiohome.ini")

#IfWinActive,プロジェクトエクスプローラ ahk_exe LabVIEW.exe
sc07B & u::ws.Do("LVPRJ-Up Left")
sc07B & j::ws.Do("LVPRJ-left")
sc07B & m::ws.Do("LVPRJ-Down Left")
#IfWinActive

#IfWinActive,フロントパネル ahk_exe LabVIEW.exe
sc07B & u::ws.MoveTo("LVFP-Up Left", false)
sc07B & i::ws.MoveTo("LVFP-Up", false)
sc07B & o::ws.MoveTo("LVFP-Up Right", false)
sc07B & j::ws.MoveTo("LVFP-Left", false)
sc07B & k::ws.MoveTo("LVFP-Middle", false)
sc07B & l::ws.MoveTo("LVFP-Right", false)
sc07B & m::ws.MoveTo("LVFP-Down Left", false)
sc07B & ,::ws.MoveTo("LVFP-Down", false)
sc07B & .::ws.MoveTo("LVFP-Down Right", false)
#IfWinActive

#IfWinActive,ブロックダイアグラム ahk_exe LabVIEW.exe
sc07B & u::ws.Do("LVBLK-Up Left")
sc07B & i::ws.Do("LVBLK-Up")
sc07B & o::ws.Do("LVBLK-Up Right")
sc07B & j::ws.Do("LVBLK-left")
sc07B & k::ws.Do("LVBLK-Middle")
sc07B & l::ws.Do("LVBLK-Right")
sc07B & m::ws.Do("LVBLK-Down Left")
sc07B & ,::ws.Do("LVBLK-Down")
sc07B & .::ws.Do("LVBLK-Down Right")
#IfWinActive

#IFWinNotActive, - リモート デスクトップ
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
sc07B & h::ws.TopMostToggle()
sc07B & @::ws.Toggle()
sc07B & z::ws.RunUndo()
sc07B & 7::wc.SaveWindows(1)
sc07B & 8::wc.LoadWindows(1)
sc07B & 0::ws.MoveToNextMonitor()
sc07B & -::ws.CursorMoveToNextMonitor()
sc07B & `;::ws.ActiveNextWindow()
#IfWinNotActive


