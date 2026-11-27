package rico_tests

import "core:testing"
import "rico16:rico"

markers :: proc(mem: ^rico.Memory) {
	rico.sset(mem, 16, 0, 5)
	rico.sset(mem, 19, 1, 9)
}

@(test)
sset_sget :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.sset(mem, 17, 2, 6)
	testing.expect_value(t, rico.sget(mem, 17, 2), 6)
	testing.expect_value(t, mem.sprites[1][2 * rico.SPRITE_SIZE + 1], 6)

	rico.sset(mem, 255, 511, 4)
	testing.expect_value(t, mem.sprites[511][255], 4)

	rico.sset(mem, 256, 0, 4)
	testing.expect_value(t, rico.sget(mem, -1, 0), 0)
}

@(test)
spr_and_flips :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.cls(mem, 2)
	rico.spr(mem, 1, 10, 20)
	testing.expect_value(t, rico.pget(mem, 10, 20), 5)
	testing.expect_value(t, rico.pget(mem, 13, 21), 9)
	testing.expect_value(t, rico.pget(mem, 11, 20), 2)

	rico.spr(mem, 1, 40, 20, flip_x = true)
	testing.expect_value(t, rico.pget(mem, 55, 20), 5)
	testing.expect_value(t, rico.pget(mem, 52, 21), 9)

	rico.spr(mem, 1, 70, 20, flip_y = true)
	testing.expect_value(t, rico.pget(mem, 70, 35), 5)

	rico.spr(mem, 1, -3, -1)
	rico.spr(mem, 1, 250, 220)
	rico.spr(mem, 999, 0, 0)
}

@(test)
pal_and_palt :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.cls(mem, 2)
	rico.palt(mem, 0, false)
	rico.spr(mem, 1, 0, 0)
	testing.expect_value(t, rico.pget(mem, 1, 0), 0)

	rico.palt(mem, 5, true)
	rico.spr(mem, 1, 20, 0)
	testing.expect_value(t, rico.pget(mem, 20, 0), 2)
	testing.expect_value(t, rico.pget(mem, 21, 0), 0)

	rico.pal_reset(mem)
	rico.pal(mem, 5, 7)
	rico.cls(mem, 2)
	rico.spr(mem, 1, 0, 0)
	testing.expect_value(t, rico.pget(mem, 0, 0), 7)
	testing.expect_value(t, rico.pget(mem, 1, 0), 2)

	rico.pset(mem, 100, 100, 5)
	testing.expect_value(t, rico.pget(mem, 100, 100), 7)
}

@(test)
sprite_palette :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	testing.expect_value(t, mem.palettes[3][5], rico.RICO_PALETTE[5])

	rico.palset(mem, 3, 5, 0x123456)
	rico.sprpal(mem, 1, 3)
	rico.spr(mem, 1, 0, 0)
	testing.expect_value(t, rico.pget(mem, 0, 0), 3 << 4 | 5)

	pixels := make([]u32, rico.SCREEN_MAX_W * rico.SCREEN_MAX_H)
	defer delete(pixels)
	rico.to_rgb(mem, pixels)
	testing.expect_value(t, pixels[0], 0x123456)
	testing.expect_value(t, pixels[3], rico.RICO_PALETTE[0])
}

@(test)
sprx_rotates_and_scales :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.sprx(mem, 1, 18, 28)
	testing.expect_value(t, rico.pget(mem, 10, 20), 5)
	testing.expect_value(t, rico.pget(mem, 13, 21), 9)

	rico.cls(mem)
	rico.sprx(mem, 1, 18, 28, 0.25)
	testing.expect_value(t, rico.pget(mem, 10, 35), 5)
	testing.expect_value(t, rico.pget(mem, 10, 20), 0)

	rico.cls(mem)
	rico.sprx(mem, 1, 18, 28, 0.5)
	testing.expect_value(t, rico.pget(mem, 25, 35), 5)

	rico.cls(mem)
	rico.sprx(mem, 1, 50, 50, 0, 2, 2)
	testing.expect_value(t, rico.pget(mem, 34, 34), 5)
	testing.expect_value(t, rico.pget(mem, 35, 35), 5)
	testing.expect_value(t, rico.pget(mem, 36, 34), 0)

	rico.cls(mem)
	rico.sprx(mem, 1, 18, 28, 0, -1, 1)
	testing.expect_value(t, rico.pget(mem, 25, 20), 5)

	rico.sprx(mem, 1, 0, 0, 0, 0, 1)
	rico.sprx(mem, 1, -100, 900, 0.1, 50, 50)
}

@(test)
nearest_color :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	for c, i in rico.RICO_PALETTE {
		testing.expect_value(t, rico.nearest_color(mem, c), u8(i))
	}
	testing.expect_value(t, rico.nearest_color(mem, 0xc9c3d5), 4)
	testing.expect_value(t, rico.nearest_color(mem, 0x000000), 0)
}
