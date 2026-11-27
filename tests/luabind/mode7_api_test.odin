package luabind_tests

import "core:testing"
import "rico16:luabind"
import "rico16:rico"

@(test)
mode7_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _init()
			for y = 0, 15 do
				for x = 0, 15 do sset(16 + x, y, 6) end
			end
			sset(16, 0, 5)
			mapsize(0, 4, 4)
			for cy = 0, 3 do
				for cx = 0, 3 do mset(0, cx, cy, 1) end
			end
		end
		function _draw()
			cls(3)
			mode7(0, 32, 32, 0.125, 20, 100)
			mode7line(0, 10, 0, 0, 1, 0)
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, cart.err, "")
	testing.expect_value(t, rico.pget(mem, 50, 100), 3)
	testing.expect_value(t, rico.pget(mem, 50, 200), 6)
	testing.expect_value(t, rico.pget(mem, 0, 10), 5)
	testing.expect_value(t, rico.pget(mem, 1, 10), 6)
}
