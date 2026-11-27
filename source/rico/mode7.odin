package rico

import "core:math"

mode7_line :: proc(mem: ^Memory, layer, y: int, wx, wy, dx, dy: f64) {
	if layer < 0 || layer >= MAP_LAYERS {
		return
	}

	w, h := screen_size(mem)
	if y < 0 || y >= h {
		return
	}

	m := &mem.maps[layer]

	for sx in 0 ..<w {
		u := int(math.floor(wx + dx * f64(sx)))
		v := int(math.floor(wy + dy * f64(sx)))

		if c, p, ok := map_texel(mem, m, u, v); ok {
			plot(mem, sx, y, c, p)
		}
	}
}

mode7 :: proc(mem: ^Memory, layer:int, x, y, angle, height: f64, horizon: int) {
	if height <= 0 {
		return
	}

	w, h := screen_size(mem)
	focal := f64(w) / 2

	a := angle * math.TAU
	fx, fy := -math.sin(a), -math.cos(a)
	rx, ry := -fy, fx

	for sy in max(horizon + 1, 0)..<h {
		dist := height * focal / (f64(sy - horizon) - 0.5)
		step := dist / focal

		cx := x + fx * dist
		cy := y + fy * dist
		left := -f64(w) / 2 + 0.5

		mode7_line(mem, layer, sy, cx + rx * step * left, cy + ry * step * left, rx * step, ry * step)
	}
}
