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

	FRAME :: 1.0 / 60.0
	frame := 0
	acc := 0.0
	last := pf.time()

	for pf.process_events() {
		now := pf.time()
		acc += min(now - last, 0.25)
		last = now

		for acc >= FRAME {
			frame += 1
			acc -= FRAME
		}

		w, h := rico.screen_size(mem)
		rico.cls(mem, 0)

		for y in 0..< h / 2 {
			for x in 0..< w {
				rico.pset(mem, x, y, u8(x * 16 / w))
			}
		}

		rico.pset(mem, frame % w, h * 3 / 4, 5)

		rico.to_rgb(mem, pixels)
		pf.present(pixels, w, h)

		free_all(context.temp_allocator)
	}
}
