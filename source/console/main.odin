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

		if pf.key_pressed(.Tab) {
			next := rico.Mode((int(mem.mode) + 1) %len(rico.Mode))
			rico.set_mode(mem, next)
		}

		for acc >= FRAME {
			frame += 1
			acc -= FRAME
		}

		w, h := rico.screen_size(mem)
		rico.cls(mem, 0)
		
		bw := w / 16
		for i in 0..<16 {
			rico.rectfill(mem, i * bw, 0, i * bw + bw - 1, h / 2, u8(i))
		}

		rico.rect(mem, 0, 0, w - 1, h - 1, 4)
		rico.line(mem, 0, h - 1, w - 1, h / 2, 12)

		rico.circfill(mem, w / 4, h * 3 / 4, 20, 11)
		rico.circ(mem, w * 3 / 4, h * 3 / 4, 20, 9)

		rico.pset(mem, frame % w, h * 3 / 4, 5)

		rico.to_rgb(mem, pixels)
		pf.present(pixels, w, h)

		free_all(context.temp_allocator)
	}
}
