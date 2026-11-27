package cart

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "rico16:rico"

HEADER :: "rico16 cart 1"

SHEET_W :: rico.SHEET_COLS * rico.SPRITE_SIZE
SHEET_H :: rico.MAX_SPRITES / rico.SHEET_COLS * rico.SPRITE_SIZE
SHEET_ROWS :: rico.MAX_SPRITES / rico.SHEET_COLS

SECTIONS := [?]string {
	"__lua__", "__pal__", "__gfx__", "__sprpal__",
	"__map0__", "__map1__", "__map2__", "__map3__",
	"__sfx__", "__music__",
}

clear :: proc(mem: ^rico.Memory) {
	rico.reset_palettes(mem)
	rico.pal_reset(mem)
	mem.sprites = {}
	mem.sprite_pal = {}

	rico.reset_maps(mem)
	rico.reset_sound(mem)
	rico.camera(mem, 0, 0)
}

write :: proc(mem: ^rico.Memory, code: string, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)

	fmt.sbprintf(&sb, "%s\nmode %d\n", HEADER, int(mem.mode))

	strings.write_string(&sb, "__lua__\n")
	strings.write_string(&sb, code)

	if code != "" && !strings.has_suffix(code, "\n") {
		strings.write_byte(&sb, '\n')
	}

	write_pal(&sb, mem)
	write_gfx(&sb, mem)
	write_sprpal(&sb, mem)
	write_maps(&sb, mem)
	write_sfx(&sb, mem)
	write_music(&sb, mem)

	return strings.to_string(sb)
}

read :: proc(mem: ^rico.Memory, text: string, allocator := context.allocator) -> (code: string, ok: bool) {
	rest := text

	header, _ := strings.split_lines_iterator(&rest)
	if strings.trim_space(header) != HEADER {
		return
	}

	clear(mem)
	mem.mode = .Standard

	code_sb := strings.builder_make(allocator)
	section := ""
	row := 0

	for line in strings.split_lines_iterator(&rest) {
		if slice.contains(SECTIONS[:], line) {
			section = line
			row = 0
			continue
		}

		switch section {
			case "":
				read_header(mem, line)
			case "__lua__":
				strings.write_string(&code_sb, line)
				strings.write_byte(&code_sb, '\n')
			case "__pal__":
				read_pal(mem, line, row)
			case "__gfx__":
				read_gfx(mem, line, row)
			case "__sprpal__":
				read_sprpal(mem, line, row)
			case "__map0__", "__map1__", "__map2__", "__map3__":
				read_map(mem, int(section[5] - '0'), line, row)
			case "__sfx__":
				read_sfx(mem, line, row)
			case "__music__":
				read_music(mem, line, row)
		}

		row += 1
	}

	return strings.to_string(code_sb), true
}

HEX := "0123456789abcdef"

@(private)
hex :: proc(sb: ^strings.Builder, v, digits: int) {
	for i := digits - 1; i >= 0; i -= 1 {
		strings.write_byte(sb, HEX[(v >> uint(i * 4)) & 15])
	}
}

@(private)
unhex :: proc(s: string, at, digits: int) -> int {
	v := 0

	for i in at..<at + digits {
		d:= 0
		if i < len(s) {
			switch ch := s[i]; ch {
				case '0'..='9':
					d = int(ch - '0')
				case 'a'..='f':
					d = int(ch - 'a') + 10
				case 'A'..='F':
					d = int(ch - 'A') + 10
			}
		}

		v = v << 4 | d
	}

	return v
}

@(private)
read_header :: proc(mem: ^rico.Memory, line: string) {
	if !strings.has_prefix(line, "mode ") {
		return
	}

	if v, ok := strconv.parse_int(strings.trim_space(line[5:])); ok && v >= 0 && v < len(rico.Mode) {
		mem.mode = rico.Mode(v)
	}
}

@(private)
write_pal :: proc(sb: ^strings.Builder, mem: ^rico.Memory) {
	last := -1

	for p, i in mem.palettes {
		if p != rico.RICO_PALETTE {
			last = i
		}
	}

	if last < 0 {
		return
	}

	strings.write_string(sb, "__pal__\n")
	for p in mem.palettes[:last + 1] {
		for c in p {
			hex(sb, int(c), 6)
		}

		strings.write_byte(sb, '\n')
	}
}

@(private)
read_pal :: proc(mem: ^rico.Memory, line:string, row:int) {
	if row >= len(mem.palettes) {
		return
	}

	for c in 0..<min(len(line) / 6, 16) {
		mem.palettes[row][c] = u32(unhex(line, c * 6, 6))
	}
}

@(private)
write_gfx :: proc (sb:^strings.Builder, mem: ^rico.Memory) {
	last := -1

	for y in 0..<SHEET_H {
		for x in 0..<SHEET_W {
			if rico.sget(mem, x, y) != 0 {
				last = y
				break
			}
		}
	}

	if last < 0 {
		return
	}

	strings.write_string(sb, "__gfx__\n")

	for y in 0..=last {
		for x in 0..<SHEET_W {
			hex(sb, int(rico.sget(mem, x, y)), 1)
		}

		strings.write_byte(sb, '\n')
	}
}

@(private)
read_gfx :: proc(mem: ^rico.Memory, line:string, row: int) {
	for x in 0..<min(len(line), SHEET_W) {
		rico.sset(mem, x, row, u8(unhex(line, x, 1)))
	}
}

@(private)
write_sprpal :: proc(sb: ^strings.Builder, mem: ^rico.Memory) {
	last := -1

	for p, n in mem.sprite_pal {
		if p != 0 {
			last = n / rico.SHEET_COLS
		}
	}

	if last < 0 {
		return
	}

	strings.write_string(sb, "__sprpal__\n")
	for row in 0..=last {
		for col in 0..<rico.SHEET_COLS {
			hex(sb, int(mem.sprite_pal[row * rico.SHEET_COLS + col]), 1)
		}

		strings.write_byte(sb, '\n')
	}
}

@(private)
read_sprpal :: proc(mem: ^rico.Memory, line: string, row: int) {
	if row >= SHEET_ROWS {
		return
	}

	for col in 0..<min(len(line), rico.SHEET_COLS) {
		rico.sprpal(mem, row * rico.SHEET_COLS + col, u8(unhex(line, col, 1)))
	}
}

@(private)
write_maps :: proc(sb: ^strings.Builder, mem: ^rico.Memory) {
	for &m, layer in mem.maps {
		last := -1
		for y in 0..<m.h {
			for x in 0..<m.w {
				if m.tiles[y * rico.MAP_SIZE + x] != 0 {
					last = y
					break
				}
			}
		}

		if last < 0 && m.w == rico.MAP_SIZE && m.h == rico.MAP_SIZE {
			continue
		}

		fmt.sbprintf(sb, "__map%d__\n%d %d\n", layer, m.w, m.h)
		for y in 0..=last {
			for x in 0..<m.w {
				hex(sb, int(m.tiles[y * rico.MAP_SIZE + x]), 3)
			}
			strings.write_byte(sb, '\n')
		}
	}
}

@(private)
read_map :: proc(mem: ^rico.Memory, layer: int, line: string, row: int) {
	if row == 0 {
		size := strings.fields(line, context.temp_allocator)
		if len(size) == 2 {
			w, _ := strconv.parse_int(size[0])
			h, _ := strconv.parse_int(size[1])
			rico.map_size(mem, layer, w, h)
		}
		return
	}

	for x in 0..<len(line) / 3 {
		rico.mset(mem, layer, x, row - 1, unhex(line, x * 3, 3))
	}
}

@(private)
write_sfx :: proc(sb: ^strings.Builder, mem: ^rico.Memory) {
	last := -1
	for s, i in mem.sfx {
		if s != (rico.Sfx{speed = 16}) {
			last = i
		}
	}

	if last < 0 {
		return
	}

	strings.write_string(sb, "__sfx__\n")
	for s in mem.sfx[:last + 1] {
		hex(sb, int(s.speed), 2)
		hex(sb, int(s.loop_start), 2)
		hex(sb, int(s.loop_end), 2)

		for n in s.notes {
			hex(sb, int(n.pitch), 2)
			hex(sb, int(n.wave), 1)
			hex(sb, int(n.vol), 1)
			hex(sb, int(n.fx), 1)
		}
		strings.write_byte(sb, '\n')
	}
}

@(private)
read_sfx :: proc(mem: ^rico.Memory, line: string, row: int) {
	if row >= rico.MAX_SFX || len(line) < 6 {
		return
	}

	rico.sfx_speed(mem, row, unhex(line, 0, 2), unhex(line, 2, 2), unhex(line, 4, 2))

	for i in 0..<rico.SFX_NOTES {
		at := 6 + i * 5
		if at + 5 > len(line) {
			break
		}

		rico.sfx_note(mem, row, i, {
			pitch = u8(unhex(line, at, 2)),
			wave = rico.Wave(unhex(line, at + 2, 1)),
			vol = u8(unhex(line, at + 3, 1)),
			fx = rico.Effect(unhex(line, at + 4, 1)),
		})
	}
}

@(private)
write_music :: proc(sb: ^strings.Builder, mem: ^rico.Memory) {
	last := -1
	for p, i in mem.patterns {
		if p != (rico.Pattern{sfx = -1}) {
			last = i
		}
	}

	if last < 0 {
		return
	}

	strings.write_string(sb, "__music__\n")
	for p in mem.patterns[:last + 1] {
		hex(sb, int(transmute(u8)p.flags), 1)
		for n in p.sfx {
			hex(sb, int(u8(n)), 2)
		}
		strings.write_byte(sb, '\n')
	}
}

@(private)
read_music :: proc(mem: ^rico.Memory, line: string, row: int) {
	if row >= rico.MAX_PATTERNS || len(line) < 9 {
		return
	}

	flags := transmute(rico.Pattern_Flags)u8(unhex(line, 0, 1) & 7)
	sfx: [rico.MUSIC_CHANNELS]int
	for &n, i in sfx {
		n = unhex(line, 1 + i * 2, 2)
	}

	rico.set_pattern(mem, row, sfx, flags)
}
