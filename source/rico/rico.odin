package rico

Mode :: enum u8 {
	Standard, // 256x224
	Wide, //320x180
	Hires,// 512x448
}

MODE_SIZE := [Mode][2]int {
	.Standard = {256, 224},
	.Wide = {320, 180},
	.Hires = {512,448}
}

SCREEN_MAX_W :: 512
SCREEN_MAX_H :: 448

Memory :: struct {
	mode: Mode,
	palettes: [16][16]u32,
	draw_pal: [16]u8,
	transparent: Colors,
	camera: [2]int,
	sprites: [MAX_SPRITES][SPRITE_SIZE * SPRITE_SIZE]u8,
	sprite_pal: [MAX_SPRITES]u8,
	maps: [MAP_LAYERS]Map_Layer,
	screen: [SCREEN_MAX_W * SCREEN_MAX_H]u8,
	pad: [MAX_PLAYERS]Buttons,
	pad_held: [MAX_PLAYERS][Button]u16,
	font: [128]Glyph,
	sfx: [MAX_SFX]Sfx,
	patterns: [MAX_PATTERNS]Pattern,
	channels: [CHANNELS]Channel,
	music: Music_State,
}

init :: proc(mem: ^Memory, mode: Mode) {
	mem^ = {}
	mem.mode = mode

	reset_palettes(mem)
	pal_reset(mem)

	reset_maps(mem)
	reset_sound(mem)

	load_font(mem)
}

set_mode :: proc(mem: ^Memory, mode: Mode) {
	mem.mode = mode
	cls(mem)
}

screen_size :: proc(mem: ^Memory) -> (w, h: int) {
	s := MODE_SIZE[mem.mode]
	return s.x, s.y
}

to_rgb :: proc(mem: ^Memory, out: []u32) {
	w, h := screen_size(mem)

	for i in 0..< w * h {
		px := mem.screen[i]
		out[i] = mem.palettes[px >> 4][px & 15]
	}
}
