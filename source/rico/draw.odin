package rico

import "core:slice"

cls :: proc(mem: ^Memory, col: u8 = 0) {
	w, h := screen_size(mem)
	slice.fill(mem.screen[:w * h], col & 15)
}

pset :: proc(mem: ^Memory, x, y: int, col: u8) {
	w, h := screen_size(mem)

	if x < 0 || y < 0 || x >= w || y >= h {
		return
	}

	mem.screen[y * w + x] = mem.draw_pal[col & 15]
}

pget :: proc(mem: ^Memory, x, y: int) -> u8 {
	w, h := screen_size(mem)

	if x < 0 || y < 0 || x >= w || y >= h {
		return 0
	}

	return mem.screen[y * w + x]
}

line :: proc(mem: ^Memory, x0, y0, x1, y1: int, col: u8) {
	x, y := x0, y0
	dx := abs(x1 - x0)
	dy := -abs(y1 - y0)
	sx := 1 if x0 < x1 else -1
	sy := 1 if y0 < y1 else - 1
	err := dx + dy

	for {
		pset(mem, x, y, col)
		if x == x1 && y == y1 {
			break
		}
		e2 := 2 * err
		if e2 >= dy {
			err += dy
			x += sx
		}
		if e2 <= dx {
			err += dx
			y += sy
		}
	}
}

rect :: proc(mem: ^Memory, x0, y0, x1, y1: int, col: u8) {
	line(mem, x0, y0, x1, y0, col)
	line(mem, x0, y1, x1, y1, col)
	line(mem, x0, y0, x0, y1, col)
	line(mem, x1, y0, x1, y1, col)
}

rectfill :: proc(mem: ^Memory, x0, y0, x1, y1:int, col: u8) {
	w, h := screen_size(mem)

	ax := max(min(x0, x1), 0)
	bx := min(max(x0, x1), w - 1)
	ay := max(min(y0, y1), 0)
	by := min(max(y0, y1), h - 1)

	if ax > bx || ay > by {
		return
	}
	
	c := mem.draw_pal[col & 15]
	for y in ay ..=by {
		slice.fill(mem.screen[y * w + ax:y * w + bx + 1], c)
	}
}

circ :: proc(mem: ^Memory, cx, cy, r:int, col:u8) {
	if r < 0 {
		return
	}

	x, y := r, 0
	err := 1 - r

	for x >= y {
		pset(mem, cx + x, cy + y, col)
		pset(mem, cx - x, cy + y, col)
		pset(mem, cx + x, cy - y, col)
		pset(mem, cx - x, cy - y, col)
		pset(mem, cx + y, cy + x, col)
		pset(mem, cx - y, cy + x, col)
		pset(mem, cx + y, cy - x, col)
		pset(mem, cx - y, cy - x, col)


		y += 1
		if err < 0 {
			err += 2 * y + 1
		} else {
			x -= 1
			err += 2 * (y - x) + 1
		}
	}
}

circfill :: proc(mem: ^Memory, cx, cy, r:int, col:u8) {
	if r < 0 {
		return
	}

	x, y := r, 0
	err := 1 - r

	for x >= y {
		rectfill(mem, cx - x, cy + y, cx + x, cy + y, col)
		rectfill(mem, cx - x, cy - y, cx + x, cy -y, col)
		rectfill(mem, cx - y, cy + x, cx + y, cy + x, col)
		rectfill(mem, cx - y, cy -x, cx + y, cy - x, col)

		y += 1

		if err < 0 {
			err += 2 * y + 1
		} else {
			x -= 1
			err += 2 * (y - x) + 1
		}
	}
}
