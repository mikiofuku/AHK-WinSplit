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
