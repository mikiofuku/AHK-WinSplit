
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

		;OutputDebug, % "     --> Monitor = " no
		;OutputDebug, % "      " left " x " top " x " right " x " Bottom " : width = " this.w ", height = " this.h
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

		;this.Debug()

		if(sw > 0 && sh > 0)
		{
			;OutputDebug, % "      on this monitor area : " area
		}
		
		return area
	}
	
	Debug()
	{		
		OutputDebug, % "  --> Monitor = " this.no
		OutputDebug, % "  " this.left " x " this.top " x " this.right " x " this.Bottom " : width = " this.w ", height = " this.h
		OutputDebug, % "    " sx " x " sy " x " ex " x " ey
		OutputDebug, % "    sw = " sw ", sh = " sh
	}
}