
class INI
{

	__New()
	{
		return this
	}
	
	; INIファイルを読み込み、ActionクラスやSequenceクラスのインスタンスを生成する
	; 生成したActionクラスの配列を返す
	Read(winsplit,filename)
	{
		; INIファイル読み込みの準備
		OutputDebug, --> Read INI
		OutputDebug, ScriptDir  : %A_ScriptDir%
		;SetWorkingDir, %A_ScriptDir%\AHK-WinSplit
		OutputDebug, WorkingDir : %A_WorkingDir%

		; 読み込むファイル名の設定
		if(filename == "")
		{
			SetWorkingDir, %A_ScriptDir%
			filename := "AHK-Winsplit.ini"
		}		
		OutputDebug, inifilename  : %filename%

		; ■Configの読込
		IniRead, inivalue, %filename%, Config, WindowChangeSize
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
			IniRead, name, %filename%, %secname%, name

			; セクションが無ければ終わり
			if(name == "ERROR")
				Break

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
				IniRead, val, %filename%, %secname%, %keyname% 
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
