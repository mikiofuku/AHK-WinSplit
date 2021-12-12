
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
