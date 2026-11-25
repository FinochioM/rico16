package main

import "core:log"
import "rico16:platform"
import "rico16:rico"
import "rico16:backend_sdl3"

RICO_BACKEND :: #config(RICO_BACKEND, "sdl3")

when RICO_BACKEND == "sdl3" {
	backend :: backend_sdl3.INTERFACE
}

main :: proc() {
	context.logger = log.create_console_logger()

	pf: platform.Interface = backend

	if !pf.init("RICO-16", 1024, 896) {
		return
	}
	defer pf.shutdown()

	mem := new(rico.Memory)
	defer free(mem)

	rico.init(mem, .Standard)

	pixels := make([]u32, rico.SCREEN_MAX_W * rico.SCREEN_MAX_H)
	defer delete(pixels)

	w, h := rico.screen_size(mem)
	for y in 0..< h {
		for x in 0..< w {
			mem.screen[y * w + x] = u8(x * 16 / w)
		}
	}

	for pf.process_events() {
		rico.to_rgb(mem, pixels)
		pf.present(pixels, w, h)

		free_all(context.temp_allocator)
	}
}
