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
	time = time,
	key_pressed = key_pressed,
	pad = pad,
}

window: ^sdl.Window
renderer: ^sdl.Renderer
texture: ^sdl.Texture
tex_w, tex_h: int
pressed: bit_set[platform.Key]
gamepads: [platform.MAX_PADS] ^sdl.Gamepad

STICK_DEADZONE :: 12000

init :: proc(title: string, width, height: int) -> bool {
	if !sdl.Init({.VIDEO, .GAMEPAD}) {
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
	for gp in gamepads {
		if gp != nil {
			sdl.CloseGamepad(gp)
		}
	}

	if texture != nil {
		sdl.DestroyTexture(texture)
	}
	sdl.DestroyRenderer(renderer)

	sdl.DestroyWindow(window)
	sdl.Quit()
}

process_events :: proc() -> bool {
	e: sdl.Event

	pressed = {}

	for sdl.PollEvent(&e) {
		#partial switch e.type {
			case .QUIT:
				return false
			case .KEY_DOWN:
				if !e.key.repeat && e.key.scancode == .TAB {
					pressed += {.Tab}
				}
			case .GAMEPAD_ADDED:
				open_gamepad(e.gdevice.which)
			case .GAMEPAD_REMOVED:
				close_gamepad(e.gdevice.which)
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

time :: proc() -> f64 {
	return f64(sdl.GetTicksNS()) / 1e9
}

key_pressed :: proc(k: platform.Key) -> bool {
	return k in pressed
}

open_gamepad :: proc(id: sdl.JoystickID) {
	for &slot in gamepads {
		if slot == nil {
			slot = sdl.OpenGamepad(id)
			log.infof("gamepad connected: %s", sdl.GetGamepadName(slot))
			return
		}
	}
}

close_gamepad :: proc(id: sdl.JoystickID) {
	for &slot in gamepads {
		if slot != nil && sdl.GetGamepadID(slot) == id {
			sdl.CloseGamepad(slot)
			slot = nil
		}
	}
}

pad :: proc(player: int) -> platform.Pad_State {
	s: platform.Pad_State

	if player < 0 || player >= platform.MAX_PADS {
		return s
	}

	if player == 0 {
		keys := sdl.GetKeyboardState(nil)
		if keys[sdl.Scancode.LEFT] {s+= {.Left}}
		if keys[sdl.Scancode.RIGHT] {s+= {.Right}}
		if keys[sdl.Scancode.UP] {s+= {.Up}}
		if keys[sdl.Scancode.DOWN] {s+= {.Down}}
		if keys[sdl.Scancode.X] {s+= {.A}}
		if keys[sdl.Scancode.Z] {s+= {.B}}
		if keys[sdl.Scancode.S] {s+= {.X}}
		if keys[sdl.Scancode.A] {s+= {.Y}}
		if keys[sdl.Scancode.Q] {s+= {.L}}
		if keys[sdl.Scancode.W] {s+= {.R}}
		if keys[sdl.Scancode.RETURN] {s+= {.Start}}
	}

	gp := gamepads[player]
	if gp == nil {
		return s
	}

	//we follow snes layout for now
	if sdl.GetGamepadButton(gp, .DPAD_LEFT) {s += {.Left}}
	if sdl.GetGamepadButton(gp, .DPAD_RIGHT) {s += {.Right}}
	if sdl.GetGamepadButton(gp, .DPAD_UP) {s += {.Up}}
	if sdl.GetGamepadButton(gp, .DPAD_DOWN) {s += {.Down}}
	if sdl.GetGamepadButton(gp, .EAST) {s += {.A}}
	if sdl.GetGamepadButton(gp, .SOUTH) {s += {.B}}
	if sdl.GetGamepadButton(gp, .NORTH) {s += {.X}}
	if sdl.GetGamepadButton(gp, .WEST) {s += {.Y}}
	if sdl.GetGamepadButton(gp, .LEFT_SHOULDER) {s += {.L}}
	if sdl.GetGamepadButton(gp, .RIGHT_SHOULDER) {s += {.R}}
	if sdl.GetGamepadButton(gp, .START) {s += {.Start}}

	lx := sdl.GetGamepadAxis(gp, .LEFTX)
	ly := sdl.GetGamepadAxis(gp, .LEFTY)

	if lx < -STICK_DEADZONE { s+={.Left}}
	if lx > STICK_DEADZONE {s +={.Right}}
	if ly < -STICK_DEADZONE {s+={.Up}}
	if ly > STICK_DEADZONE {s+={.Down}}

	return s
}
