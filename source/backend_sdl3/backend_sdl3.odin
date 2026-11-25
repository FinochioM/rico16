package backend_sdl3

import "core:log"
import "core:strings"
import sdl "vendor:sdl3"
import "rico16:platform"

INTERFACE :: platform.Interface {
	init = init,
	shutdown = shutdown,
	process_events = process_events,
}

window: ^sdl.Window

init :: proc(title: string, width, height: int) -> bool {
	if !sdl.Init({.VIDEO}) {
		log.errorf("SDL_Init failed: %s", sdl.GetError())
		return false
	}

	ctitle := strings.clone_to_cstring(title, context.temp_allocator)
	window = sdl.CreateWindow(ctitle, i32(width), i32(height), {.RESIZABLE})
	if window == nil {
		log.errorf("SDL_CreateWindow failed: %s", sdl.GetError())
		return false
	}

	return true
}

shutdown :: proc() {
	sdl.DestroyWindow(window)
	sdl.Quit()
}

process_events :: proc() -> bool {
	e: sdl.Event

	for sdl.PollEvent(&e) {
		#partial switch e.type {
			case .QUIT:
				return false
		}
	}

	return true
}
