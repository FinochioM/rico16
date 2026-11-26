package luabind_tests

import "core:strings"
import "core:testing"
import "rico16:luabind"
import "rico16:rico"

@(test)
counts_tokens :: proc(t: ^testing.T) {
	testing.expect_value(t, luabind.count_tokens("x = 1"), 3)
	testing.expect_value(t, luabind.count_tokens(`print("hi", 1, 2)`), 5)
	testing.expect_value(t, luabind.count_tokens("local a = b.c -- a comment"), 4)
	testing.expect_value(t, luabind.count_tokens("function f() end"), 3)
	testing.expect_value(t, luabind.count_tokens("--[[ long\ncomment ]] x = [[s]] .. 'q'"), 5)
	testing.expect_value(t, luabind.count_tokens("a = 0x1f + 1.5e-3"), 5)
	testing.expect_value(t, luabind.count_tokens("a ~= t[1]"), 5)
	testing.expect_value(t, luabind.count_tokens(""), 0)
}

@(test)
too_many_tokens :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	src := strings.repeat("x = 1\n", 6000)
	defer delete(src)

	ok := run(t, mem, &cart, src)
	testing.expect(t, !ok)
	testing.expect_value(t, cart.tokens, 18000)
	testing.expect(t, strings.contains(cart.err, "too many tokens"))
}

@(test)
no_files_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _draw()
			if io == nil and os == nil and require == nil and dofile == nil and loadfile == nil then
				pset(0, 0, 7)
			end
			-- the safe libraries are still there
			pset(1, 0, math.floor(string.len("abc")))
		end
	`)
	testing.expect(t, ok)

	luabind.draw(&cart)
	testing.expect_value(t, cart.err, "")
	testing.expect_value(t, rico.pget(mem, 0, 0), 7)
	testing.expect_value(t, rico.pget(mem, 1, 0), 3)
}
