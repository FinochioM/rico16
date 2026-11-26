package main

import "core:log"
import "core:os"
import "rico16:luabind"
import "rico16:platform"
import "rico16:rico"
import "rico16:backend_sdl3"

#assert(len(platform.Pad_Button) == len(rico.Button))
#assert(size_of(platform.Pad_State) == size_of(rico.Buttons))
#assert(platform.MAX_PADS == rico.MAX_PLAYERS)

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

	cart: luabind.Cart
	defer luabind.unload(&cart)
	has_cart := len(os.args) > 1

	if has_cart {
		path := os.args[1]
		src, err := os.read_entire_file(path, context.allocator)

		if err != nil {
			log.errorf("can't read %s: %v", path, err)
			return
		}

		luabind.load(&cart, mem, src, path)

		delete(src)
	}

	pixels := make([]u32, rico.SCREEN_MAX_W * rico.SCREEN_MAX_H)
	defer delete(pixels)

	FRAME :: 1.0 / 60.0
	frame := 0
	counter := 0
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

		ticked := false

		for acc >= FRAME {
			for p in 0..<rico.MAX_PLAYERS {
				rico.update_pad(mem, p, transmute(rico.Buttons)pf.pad(p))
			}

			if has_cart {
				luabind.update(&cart)
			} else {
				if rico.btnp(mem, .Up) {
					counter += 1
				}

				if rico.btnp(mem, .Down) {
					counter -= 1
				}
			}

			ticked = true	
			frame += 1
			acc -= FRAME
		}

		w, h := rico.screen_size(mem)
		
		if !has_cart {
			draw_pad_tester(mem, counter)
		} else if ticked {
			luabind.draw(&cart)
			if cart.err != "" {
				//show an error screen, print for now
				rico.cls(mem, 1)
				rico.print(mem, "cart stopped", 4, 4, 12)
				rico.print(mem, cart.err, 4, 14, 4)
			}
		}

		rico.to_rgb(mem, pixels)
		pf.present(pixels, w, h)

		free_all(context.temp_allocator)
	}
}
