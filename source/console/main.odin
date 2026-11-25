package main

import "core:log"
import "rico16:platform"
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

	for pf.process_events() {
		free_all(context.temp_allocator)
	}
}
