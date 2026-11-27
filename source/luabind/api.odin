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
		{"spr", l_spr},
		{"sprx", l_sprx},
		{"sset", l_sset},
		{"sget", l_sget},
		{"sprpal", l_sprpal},
		{"pal", l_pal},
		{"palt", l_palt},
		{"palset", l_palset},
		{"map", l_map},
		{"mset", l_mset},
		{"mget", l_mget},
		{"mapsize", l_mapsize},
		{"camera", l_camera},
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

@(private)
opt_num :: proc "c" (L: ^lua.State, i: c.int, def: f64) -> f64 {
	return f64(lua.L_optnumber(L, i, lua.Number(def)))
}

@(private)
l_spr :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	flip_x := bool(lua.toboolean(L, 4))
	flip_y := bool(lua.toboolean(L, 5))
	rico.spr(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), flip_x, flip_y)

	return 0
}

@(private)
l_sprx :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	cx := f64(lua.L_checknumber(L, 2))
	cy := f64(lua.L_checknumber(L, 3))
	sx := opt_num(L, 5, 1)

	rico.sprx(get_mem(L), arg_int(L, 1), cx, cy, opt_num(L, 4, 0), sx, opt_num(L, 6, sx))

	return 0
}

@(private)
l_sset :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	rico.sset(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_col(L,3))

	return 0
}

@(private)
l_sget :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	lua.pushinteger(L, lua.Integer(rico.sget(get_mem(L), arg_int(L, 1), arg_int(L,2))))

	return 1
}

@(private)
l_sprpal :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	mem := get_mem(L)
	n := arg_int(L, 1)

	if n < 0 || n >= rico.MAX_SPRITES {
		lua.pushinteger(L, 0)
		return 1
	}

	if !lua.isnoneornil(L, 2) {
		rico.sprpal(mem, n, u8(arg_int(L, 2) & 15))
	}

	lua.pushinteger(L, lua.Integer(mem.sprite_pal[n]))
	return 1
}

@(private)
l_pal :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	mem := get_mem(L)

	if lua.gettop(L) == 0 {
		rico.pal_reset(mem)
		return 0
	}

	rico.pal(mem, u8(arg_int(L, 1) & 15), u8(arg_int(L, 2) & 15))
	return 0
}

@(private)
l_palt :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	mem := get_mem(L)

	if lua.gettop(L) == 0 {
		rico.palt_reset(mem)
		return 0
	}

	rico.palt(mem, u8(arg_int(L, 1) & 15), bool(lua.toboolean(L, 2)))

	return 0
}

@(private)
l_palset :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	rico.palset(get_mem(L), u8(arg_int(L, 1) & 15), u8(arg_int(L, 2) & 15), u32(arg_int(L, 3) & 0xffffff))

	return 0
}

@(private)
l_map :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	rico.draw_map(get_mem(L), arg_int(L, 1), opt_int(L, 2, 0), opt_int(L, 3, 0))

	return 0
}

@(private)
l_mset :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	rico.mset(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L, 3), arg_int(L, 4))
	return 0
}

@(private)
l_mget :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	lua.pushinteger(L, lua.Integer(rico.mget(get_mem(L), arg_int(L, 1), arg_int(L, 2), arg_int(L,3))))

	return 1
}

@(private)
l_mapsize :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()
	mem := get_mem(L)
	layer := arg_int(L, 1)

	if layer < 0 || layer >= rico.MAP_LAYERS {
		lua.pushinteger(L, 0)
		lua.pushinteger(L, 0)

		return 2
	}

	if !lua.isnoneornil(L, 2) {
		rico.map_size(mem, layer, arg_int(L, 2), arg_int(L,3))
	}

	lua.pushinteger(L, lua.Integer(mem.maps[layer].w))
	lua.pushinteger(L, lua.Integer(mem.maps[layer].h))

	return 2
}

@(private)
l_camera :: proc "c" (L: ^lua.State) -> c.int {
	context = runtime.default_context()

	rico.camera(get_mem(L), opt_int(L, 1, 0), opt_int(L, 2, 0))

	return 0
}
