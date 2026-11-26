package luabind_tests

import "core:strings"
import "core:testing"
import "rico16:luabind"
import "rico16:rico"

run :: proc(t: ^testing.T, mem: ^rico.Memory, cart: ^luabind.Cart, src: string) -> bool {
	rico.init(mem, .Standard)
	return luabind.load(cart, mem, transmute([]byte)src, "test")
}

@(test)
draws :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _draw()
			cls(3)
			pset(1.7, 2, 5)
			rectfill(10, 10, 12, 12, 9)
			print("A", 20, 20, 4)
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, rico.pget(mem, 0, 0), 3)
	testing.expect_value(t, rico.pget(mem, 1, 2), 5) 
	testing.expect_value(t, rico.pget(mem, 11, 11), 9)
	testing.expect_value(t, rico.pget(mem, 21, 21), 4)
	testing.expect_value(t, cart.err, "")
}

@(test)
init_update_btn :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	run(t, mem, &cart, `
		function _init() x = 10 end
		function _update()
			if btn(1) then x += 1 end
		end
		function _draw() cls() pset(x, 0, 7) end
	`)
	testing.expect(t, cart.err != "")

	ok := run(t, mem, &cart, `
		function _init() x = 10 end
		function _update()
			if btn(1) then x = x + 1 end
		end
		function _draw() cls() pset(x, 0, 7) end
	`)
	testing.expect(t, ok)

	rico.update_pad(mem, 0, {.Right})
	luabind.update(&cart)
	luabind.draw(&cart)
	testing.expect_value(t, rico.pget(mem, 11, 0), 7)
}

@(test)
errors_stop_the_cart :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _update() error("boom") end
		function _draw() pset(0, 0, 7) end
	`)
	testing.expect(t, ok)

	luabind.update(&cart)
	testing.expect(t, strings.contains(cart.err, "boom"))

	luabind.draw(&cart)
	testing.expect_value(t, rico.pget(mem, 0, 0), 0)

	run(t, mem, &cart, `function _draw() pset("left", 0) end`)
	luabind.draw(&cart)
	testing.expect(t, cart.err != "")
}
