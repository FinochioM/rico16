package luabind

import "core:c"
import "core:strings"
import lua "vendor:lua/5.4"
import "rico16:rico"

Cart :: struct {
	L: ^lua.State,
	mem: ^rico.Memory,
	err: string,
}

load :: proc(cart: ^Cart, mem: ^rico.Memory, source: []byte, name:string)-> bool {
	unload(cart)

	cart.mem = mem
	cart.L = lua.L_newstate()
	lua.L_openlibs(cart.L)
	register_api(cart.L, mem)

	cname := strings.clone_to_cstring(strings.concatenate({"@", name},
		context.temp_allocator), context.temp_allocator)

	if lua.L_loadbuffer(cart.L, raw_data(source), c.size_t(len(source)), cname) != .OK {
		set_error(cart)
		return false
	}

	if lua.pcall(cart.L, 0, 0, 0) != 0 {
		set_error(cart)
		return false
	}

	call(cart, "_init")
	return cart.err == ""
}

unload :: proc(cart: ^Cart) {
	if cart.L != nil {
		lua.close(cart.L)
	}

	delete(cart.err)
	cart^ = {}
}

update :: proc(cart: ^Cart) {
	call(cart, "_update")
}

draw :: proc(cart: ^Cart) {
	call(cart, "_draw")
}

call :: proc(cart: ^Cart, fn: cstring) {
	if cart.L == nil || cart.err != "" {
		return
	}

	if lua.getglobal(cart.L, fn) != c.int(lua.Type.FUNCTION) {
		lua.pop(cart.L, 1)
		return
	}

	if lua.pcall(cart.L, 0, 0, 0) != 0 {
		set_error(cart)
	}
}

@(private)
set_error :: proc(cart: ^Cart) {
	msg := lua.tostring(cart.L, -1)
	cart.err = strings.clone_from_cstring(msg if msg != nil else "unknown error")
	lua.pop(cart.L, 1)
}
