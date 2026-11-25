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

	mem.screen[y * w + x] = col & 15
}

pget :: proc(mem: ^Memory, x, y: int) -> u8 {
	w, h := screen_size(mem)

	if x < 0 || y < 0 || x >= w || y >= h {
		return 0
	}

	return mem.screen[y * w + x]
}
