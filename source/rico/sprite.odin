package rico

import "core:image/png"
import "core:math"

SPRITE_SIZE :: 16
MAX_SPRITES :: 512
SHEET_COLS :: 16

sset :: proc(mem: ^Memory, x, y: int, c: u8) {
	if x < 0 || y < 0 || x >= SHEET_COLS * SPRITE_SIZE || y >= MAX_SPRITES / SHEET_COLS * SPRITE_SIZE {
		return
	}

	n := (y / SPRITE_SIZE) * SHEET_COLS + x / SPRITE_SIZE
	mem.sprites[n][(y % SPRITE_SIZE) * SPRITE_SIZE + x % SPRITE_SIZE] = c & 15
}

sget :: proc(mem: ^Memory, x, y: int) -> u8 {
	if x < 0 || y < 0 || x >= SHEET_COLS * SPRITE_SIZE || y >= MAX_SPRITES / SHEET_COLS * SPRITE_SIZE {
		return 0
	}

	n := (y / SPRITE_SIZE) * SHEET_COLS + x / SPRITE_SIZE
	return mem.sprites[n][(y % SPRITE_SIZE) * SPRITE_SIZE + x % SPRITE_SIZE]
}

sprpal :: proc(mem: ^Memory, n: int, p: u8) {
	if n < 0 || n >= MAX_SPRITES {
		return
	}

	mem.sprite_pal[n] = p & 15
}

@(private)
plot :: proc(mem: ^Memory, x, y: int, c, p: u8) {
	if int(c) in mem.transparent {
		return
	}

	w, h := screen_size(mem)
	if x < 0 || y < 0 || x >= w || y >= h {
		return
	}

	mem.screen[y * w + x] = p << 4 | mem.draw_pal[c]
}

spr :: proc(mem: ^Memory, n, x, y: int, flip_x := false, flip_y := false) {
	if n < 0 || n >= MAX_SPRITES {
		return
	}

	s := &mem.sprites[n]
	p := mem.sprite_pal[n]

	for sy in 0..<SPRITE_SIZE {
		v := SPRITE_SIZE - 1 - sy if flip_y else sy

		for sx in 0..<SPRITE_SIZE {
			u := SPRITE_SIZE - 1 - sx if flip_x else sx

			plot(mem, x + sx, y + sy, s[v * SPRITE_SIZE + u], p)
		}
	}
}

sprx :: proc(mem: ^Memory, n: int, cx, cy: f64, angle: f64 = 0, scale_x: f64 = 1, scale_y: f64 = 1) {
	if n < 0 || n >= MAX_SPRITES || scale_x == 0 || scale_y == 0 {
		return
	}

	s := &mem.sprites[n]
	p := mem.sprite_pal[n]

	a := angle * math.TAU
	cs, sn := math.cos(a), math.sin(a)

	if abs(cs) < 1e-9 {cs = 0}
	if abs(sn) < 1e-9 {sn = 0}

	HALF :: f64(SPRITE_SIZE) / 2
	r := HALF * math.SQRT_TWO * max(abs(scale_x), abs(scale_y)) + 1

	w, h := screen_size(mem)

	x0 := max(int(math.floor(cx - r)), 0)
	x1 := min(int(math.ceil(cx + r)), w - 1)
	y0 := max(int(math.floor(cy - r)), 0)
	y1 := min(int(math.ceil(cy + r)), h - 1)

	for y in y0..=y1 {
		for x in x0..=x1 {
			dx := f64(x) + 0.5 - cx
			dy := f64(y) + 0.5 - cy

			u := (dx * cs - dy * sn) / scale_x + HALF
			v := (dx * sn + dy * cs) / scale_y + HALF

			if u < 0 || v < 0 || u >= SPRITE_SIZE || v >= SPRITE_SIZE {
				continue
			}

			plot(mem, x, y, s[int(v) * SPRITE_SIZE + int(u)], p)
		}
	}
}

load_sheet :: proc(mem: ^Memory, data: []byte) -> bool {
	img, err := png.load_from_bytes(data, {.alpha_add_if_missing})

	if err != nil {
		return false
	}
	defer png.destroy(img)

	if img.channels != 4 || img.depth != 8 {
		return false
	}

	px := img.pixels[:]

	for n in 0..<MAX_SPRITES {
		ox := (n % SHEET_COLS) * SPRITE_SIZE
		oy := (n / SHEET_COLS) * SPRITE_SIZE
		mem.sprites[n] = {}

		if ox + SPRITE_SIZE > img.width || oy + SPRITE_SIZE > img.height {
			continue
		}

		for y in 0..<SPRITE_SIZE {
			for x in 0..<SPRITE_SIZE {
				i := ((oy + y) * img.width + ox + x) * 4
				if px[i + 3] < 128 {
					continue
				}

				rgb := u32(px[i]) << 16 | u32(px[i + 1]) << 8 | u32(px[i + 2])
				mem.sprites[n][y * SPRITE_SIZE + x] = nearest_color(mem, rgb)
			}
		}
	}

	return true
}

load_palettes :: proc(mem: ^Memory, data: []byte) -> bool {
	img, err := png.load_from_bytes(data, {.alpha_add_if_missing})
	if err != nil {
		return false
	}
	defer png.destroy(img)

	if img.channels != 4 || img.depth != 8 || img.width < 16 {
		return false
	}

	px := img.pixels[:]

	for p in 0..<min(img.height, 16) {
		for c in 0..<16 {
			i := (p*img.width + c) * 4
			mem.palettes[p][c] = u32(px[i]) << 16 | u32(px[i + 1]) << 8 | u32(px[i + 2])
		}
	}

	return true
}
