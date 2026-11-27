package rico

RICO_PALETTE :: [16]u32 {
	0x1a1625, 0x2e2a3f, 0x4a4560, 0x7a7391,
	0xc9c3d6, 0xf2ece4, 0x5c6f8f, 0x2f4a52,
	0x4f7a7a, 0x8db3a8, 0x6b3d5c, 0xb0607a,
	0xe39a9a, 0x8a5a44, 0xc98f5e, 0xe3c78f,
}

Colors :: bit_set[0..<16; u16]

reset_palettes :: proc(mem: ^Memory) {
	for &p in mem.palettes {
		p = RICO_PALETTE
	}
}

palset :: proc(mem: ^Memory, p, c: u8, rgb: u32) {
	mem.palettes[p & 15][c & 15] = rgb & 0xffffff
}

pal :: proc(mem: ^Memory, c0, c1:u8) {
	mem.draw_pal[c0 & 15] = c1 & 15
}

palt :: proc(mem: ^Memory, c: u8, transparent: bool) {
	if transparent {
		mem.transparent += {int(c & 15)}
	} else {
		mem.transparent -= {int(c & 15)}
	}
}

palt_reset :: proc(mem: ^Memory) {
	mem.transparent = {0}
}

pal_reset :: proc(mem: ^Memory) {
	for i in 0..<16 {
		mem.draw_pal[i] = u8(i)
	}

	palt_reset(mem)
}

nearest_color :: proc(mem: ^Memory, rgb: u32) -> u8 {
	r, g, b := int(rgb >> 16 & 0xff), int(rgb >> 8 & 0xff), int(rgb & 0xff)
	best, best_d := 0, max(int)

	for c, i in mem.palettes[0] {
		dr := int(c >> 16 & 0xff) - r
		dg := int(c >> 8 & 0xff) - g
		db := int(c & 0xff) - b
		d := dr * dr + dg * dg + db * db

		if d < best_d {
			best, best_d = i, d
		}
	}

	return u8(best)
}
