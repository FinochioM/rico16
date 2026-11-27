package luabind_tests

import "core:testing"
import "rico16:luabind"
import "rico16:rico"

@(test)
maps_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _init()
			sset(16, 0, 5)
			mapsize(1, 4, 4)
			mset(1, 2, 0, 1)
		end
		function _draw()
			cls(2)
			map(1)
			camera(-10, 0)
			map(1, 0, 16)
			camera()
			local w, h = mapsize(1)
			pset(0, 100, mget(1, 2, 0))
			pset(1, 100, w)
			pset(2, 100, h)
			pset(3, 100, mget(1, 9, 0))
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, cart.err, "")
	testing.expect_value(t, rico.pget(mem, 32, 0), 5)
	testing.expect_value(t, rico.pget(mem, 33, 0), 2)
	testing.expect_value(t, rico.pget(mem, 96, 0), 5)
	testing.expect_value(t, rico.pget(mem, 42, 16), 5)
	testing.expect_value(t, rico.pget(mem, 0, 100), 1)
	testing.expect_value(t, rico.pget(mem, 1, 100), 4)
	testing.expect_value(t, rico.pget(mem, 2, 100), 4)
	testing.expect_value(t, rico.pget(mem, 3, 100), 0)
	testing.expect_value(t, mem.camera, [2]int{0, 0})
}
