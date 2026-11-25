package rico

import "core:image/png"

// main font for now is everyday-slight by vexed
FONT_CELL :: 6
FONT_PITCH :: 7
LINE_HEIGHT :: 7
SPACE_WIDTH :: 3

@(rodata)
FONT_PNG := #load("../../assets/fonts/everyday-slight.png")

//how everyday slight is organized, same pattern
//each row of the sheet, positioned left to right
FONT_LAYOUT := [?]string {
	"ABCDEFGH", "IJKLMNOP", "QRSTUVWX", "YZ",
	"abcdefgh", "ijklmnop", "qrstuvwx", "yz",
	"01234567", "89",
	" !\"#$%&'", "()*+,-./", ":;<=>?[]", "\\^_`{}|~",
	"@\x7f",
}

Glyph :: struct {
	rows: [FONT_CELL]u8,
	width: int,
}

load_font :: proc(mem: ^Memory) {
	img, err := png.load_from_bytes(FONT_PNG, {.alpha_add_if_missing})
	assert(err == nil && img.channels == 4 && img.depth == 8, "bad font png")

	defer png.destroy(img)

	for line, row in FONT_LAYOUT {
		for c, col in line {
			g := &mem.font[c]
			for y in 0..<FONT_CELL {
				for x in 0..<FONT_CELL {
					px := col * FONT_PITCH + 1 + x
					py := row * FONT_PITCH + 1 + y

					i := (py * img.width + px) * 4


					if img.pixels[i + 3] == 255 && img.pixels[i] < 128 {
						g.rows[y] |= 1 << uint(x)
						g.width = max(g.width, x + 1)
					}
				}
			}
		}
	}

	//empty a space thats marked by the sheet
	mem.font[' '] = {width = SPACE_WIDTH}
}

glyph :: proc(mem: ^Memory, r: rune, x, y: int, col: u8) -> int {
	c := r
	if c < 0 || c > 127 || mem.font[c].width == 0 {
		c = '?'
	}

	g := mem.font[c]
	for bits, row in g.rows {
		for column in 0..<FONT_CELL {
			if bits & (1 << uint(column)) != 0 {
				pset(mem, x + column, y + row, col)
			}
		}
	}

	return g.width
}

print :: proc(mem: ^Memory, s: string, x, y: int, col: u8) -> int {
	cx, cy := x, y

	for r in s {
		if r == '\n' {
			cx = x
			cy += LINE_HEIGHT
			continue
		}

		cx += glyph(mem, r, cx, cy, col) + 1
	}

	return cx
}

text_width :: proc(mem: ^Memory, s: string) -> int {
	longest, n := 0,0

	for r in s {
		if r == '\n' {
			n = 0
			continue
		}

		c := r

		if c < 0 || c > 127 || mem.font[c].width == 0 {
			c = '?'
		}

		n += mem.font[c].width + 1
		longest = max(longest, n)
	}

	return max(longest - 1, 0)
}
