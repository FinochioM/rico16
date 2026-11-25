package backend_sdl3

import "core:log"
import "core:strings"
import sdl "vendor:sdl3"
import "rico16:platform"

INTERFACE :: platform.Interface {
	init = init,
	shutdown = shutdown,
	process_events = process_events,
	present = present,
}

window: ^sdl.Window
renderer: ^sdl.Renderer
texture: ^sdl.Texture
tex_w, tex_h: int

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

	renderer = sdl.CreateRenderer(window, nil)
	if renderer == nil {
		log.errorf("SDL_CreateRenderer failed %s", sdl.GetError())
		return false
	}

	sdl.SetRenderVSync(renderer, 1)

	return true
}

shutdown :: proc() {
	if texture != nil {
		sdl.DestroyTexture(texture)
	}
	sdl.DestroyRenderer(renderer)

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

present :: proc(pixels: []u32, width, height: int) {
	if texture == nil || tex_w != width || tex_h != height {
		if texture != nil {
			sdl.DestroyTexture(texture)
		}

		texture = sdl.CreateTexture(renderer, .XRGB8888, .STREAMING, i32(width), i32(height))
		sdl.SetTextureScaleMode(texture, .NEAREST)
		sdl.SetRenderLogicalPresentation(renderer, i32(width), i32(height), .INTEGER_SCALE)

		tex_w, tex_h = width, height
	}

	sdl.UpdateTexture(texture, nil, raw_data(pixels), i32(width * 4))

	sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
	sdl.RenderClear(renderer)
	sdl.RenderTexture(renderer, texture, nil, nil)
	sdl.RenderPresent(renderer)
}
