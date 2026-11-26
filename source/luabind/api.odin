package luabind

import "base:runtime"
import "core:c"
import "core:math"
import lua "vendor:lua/5.4"
import "rico16:rico"

@(private)
register_api :: proc(L: ^lua.State, mem: ^rico.Memory) {
	fns := [?]struct {
		name: cstring,
		fn: lua.CFunction,
	} {
		{"cls", l_cls},
		{"pset", l_pset},
		{"pget", l_pget},
		{"line", l_line},
		{"rect", l_rect},
		{"rectfill", l_rectfill},
		{"circ", l_circ},
		{"circfill", l_circfill},
		{"print", l_print},
		{"btn", l_btn},
		{"btnp", l_btnp},
	}

	for f in fns {
		lua.pushlightuserdata(L, mem)
		lua.pushcclosure(L, f.fn, 1)
		lua.setglobal(L, f.name)
	}
}

@(private)
get_mem :: proc "c" (L: ^lua.State) -> ^rico.Memory {
	return (^rico.Memory)(lua.touserdata(L, lua.REGISTRYINDEX - 1))
}

@(private)
arg_int :: proc "c" (L: ^lua.State, i: c.int) -> int {
	return int(math.floor(f64(lua.L_checknumber(L, i))))
}

@(private)
opt_int :: proc "c" (L: ^lua.State, i: c.int, def: int) -> int {
	return int(math.floor(f64(lua.L_optnumber(L, i, lua.Number(def)))))
}

@(private)
arg_col :: proc "c" (L: ^lua.State, i: c.int) -> u8 {
	return u8(opt_int(L, i, 7) & 15)
}

@(private)
l_cls :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.cls(get_mem(L), u8(opt_int(L, 1, 0) & 15))
	return 0
}

@(private)
l_pset :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.pset(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_col(L, 3))
	return 0
}

@(private)
l_pget :: proc "c" (L: ^lua.State) ->c.int {
	context = runtime.default_context()
	lua.pushinteger(L, lua.Integer(rico.pget(get_mem(L), arg_int(L, 1), arg_int(L, 2))))
	return 1
}

@(private)
l_line :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.line(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_int(L, 4), arg_col(L, 5))
	return 0
}

@(private)
l_rect :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.rect(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_int(L,4), arg_col(L,5))
	return 0
}

@(private)
l_rectfill :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.rectfill(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_int(L, 4), arg_col(L,5))
	return 0
}

@(private)
l_circ :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.circ(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_col(L, 4))
	return 0
}

@(private)
l_circfill :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	rico.circfill(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_col(L, 4))
	return 0
}

@(private)
l_print :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	s := string(lua.L_tostring(L, 1, nil))
	x := rico.print(get_mem(L), s, opt_int(L, 2, 0), opt_int(L, 3, 0), arg_col(L, 4))
	lua.pushinteger(L, lua.Integer(x))
	return 1
}

@(private)
arg_button :: proc "c" (L: ^lua.State) -> (b: rico.Button, player: int, ok: bool) {
	i := arg_int(L, 1)
	if i < 0 || i >= len(rico.Button) {
		return
	}

	return rico.Button(i), opt_int(L, 2, 0), true
}

@(private)
l_btn :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	b, p, ok := arg_button(L)
	lua.pushboolean(L, b32(ok && rico.btn(get_mem(L), b, p)))
	return 1
}

@(private)
l_btnp :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	b, p, ok := arg_button(L)
	lua.pushboolean(L, b32(ok && rico.btnp(get_mem(L), b, p)))

	return 1
}
