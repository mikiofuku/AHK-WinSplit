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

#include %A_ScriptDir%\code\Action.ahk
#include %A_ScriptDir%\code\Sequence.ahk
#include %A_ScriptDir%\code\Monitor.ahk
#include %A_ScriptDir%\code\Monitors.ahk
#include %A_ScriptDir%\code\Window.ahk
#include %A_ScriptDir%\code\WinCollection.ahk
#include %A_ScriptDir%\code\INI.ahk
#include %A_ScriptDir%\code\WinSplit.ahk

