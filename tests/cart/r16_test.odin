package cart_tests

import "core:strings"
import "core:testing"
import "rico16:cart"
import "rico16:rico"

@(test)
round_trip :: proc(t: ^testing.T) {
	a := new(rico.Memory)
	defer free(a)
	b := new(rico.Memory)
	defer free(b)

	rico.init(a, .Wide)
	rico.palset(a, 3, 5, 0x123456)
	rico.sset(a, 0, 0, 7)
	rico.sset(a, 255, 300, 15)
	rico.sprpal(a, 17, 3)
	rico.map_size(a, 1, 20, 10)
	rico.mset(a, 1, 19, 9, 300)
	rico.mset(a, 0, 0, 0, 1)
	rico.sfx_note(a, 2, 31, {pitch = 57, wave = .Square, vol = 7, fx = .Arp_Fast})
	rico.sfx_speed(a, 2, 8, 4, 12)
	rico.set_pattern(a, 5, {2, -1, 3, -1}, {.Loop_End})

	code := "function _draw()\n\tcls(1)\nend\n"
	text := cart.write(a, code, context.temp_allocator)

	rico.init(b, .Standard)
	got, ok := cart.read(b, text, context.temp_allocator)

	testing.expect(t, ok)
	testing.expect_value(t, got, code)
	testing.expect_value(t, b.mode, rico.Mode.Wide)
	testing.expect(t, b.palettes == a.palettes, "palettes")
	testing.expect(t, b.sprites == a.sprites, "sprites")
	testing.expect(t, b.sprite_pal == a.sprite_pal, "sprite palettes")
	testing.expect(t, b.maps == a.maps, "maps")
	testing.expect(t, b.sfx == a.sfx, "sfx")
	testing.expect(t, b.patterns == a.patterns, "patterns")
}

@(test)
empty_cart_is_tiny :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)

	rico.init(mem, .Standard)
	text := cart.write(mem, "", context.temp_allocator)
	testing.expect_value(t, text, "rico16 cart 1\nmode 0\n__lua__\n")
}

@(test)
read_is_forgiving :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	_, ok := cart.read(mem, "-- just lua\nprint('hi')\n", context.temp_allocator)
	testing.expect(t, !ok, "needs the header")

	rico.sset(mem, 3, 3, 9)

	text := "rico16 cart 1\r\n__lua__\r\nx = 1\r\n__gfx__\r\n0a\r\n__sfx__\r\n10\r\n__future__\r\n"
	code, ok2 := cart.read(mem, text, context.temp_allocator)

	testing.expect(t, ok2)
	testing.expect(t, strings.has_prefix(code, "x = 1\n"))
	testing.expect_value(t, rico.sget(mem, 1, 0), 10)
	testing.expect_value(t, rico.sget(mem, 3, 3), 0)
	testing.expect_value(t, mem.sfx[0].speed, 16)
}
