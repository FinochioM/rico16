package luabind_tests

import "core:testing"
import "rico16:luabind"
import "rico16:rico"

@(test)
sprites_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _init()
			sset(16, 0, 5)
			sset(19, 1, 9)
		end
		function _draw()
			cls(2)
			spr(1, 10, 20)
			spr(1, 40, 20, true)
			sprx(1, 18, 68, 0.5)
			sprx(1, 100.5, 100.5, 0, 2)
			pset(0, 0, sget(19, 1))
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, cart.err, "")
	testing.expect_value(t, rico.pget(mem, 10, 20), 5)
	testing.expect_value(t, rico.pget(mem, 11, 20), 2)
	testing.expect_value(t, rico.pget(mem, 55, 20), 5)
	testing.expect_value(t, rico.pget(mem, 25, 75), 5)
	testing.expect_value(t, rico.pget(mem, 85, 85), 5)
	testing.expect_value(t, rico.pget(mem, 0, 0), 9)
}

@(test)
palettes_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _draw()
			cls()
			sset(16, 0, 5)
			palset(3, 5, 0x123456)
			sprpal(1, 3)
			spr(1, 0, 0)

			pal(5, 7)
			spr(1, 20, 0)

			pal()
			palt(0, false)
			spr(1, 40, 0)
			palt()

			pset(100, 0, sprpal(1))
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, cart.err, "")
	testing.expect_value(t, mem.palettes[3][5], 0x123456)
	testing.expect_value(t, rico.pget(mem, 0, 0), 3 << 4 | 5)
	testing.expect_value(t, rico.pget(mem, 20, 0), 3 << 4 | 7)
	testing.expect_value(t, rico.pget(mem, 41, 0), 3 << 4 | 0)
	testing.expect_value(t, rico.pget(mem, 100, 0), 3)
	testing.expect(t, 0 in mem.transparent)
}
