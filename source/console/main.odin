package main

import "core:log"
import "core:os"
import "core:slice"
import "core:strings"
import "rico16:luabind"
import "rico16:platform"
import "rico16:rico"
import "rico16:backend_sdl3"

#assert(len(platform.Pad_Button) == len(rico.Button))
#assert(size_of(platform.Pad_State) == size_of(rico.Buttons))
#assert(platform.MAX_PADS == rico.MAX_PLAYERS)

RICO_BACKEND :: #config(RICO_BACKEND, "sdl3")
AUDIO_AHEAD :: rico.SAMPLE_RATE * 4 / 60

when RICO_BACKEND == "sdl3" {
	backend :: backend_sdl3.INTERFACE
}

State :: enum {
	Boot, Shell, Running, Editor,
}

Console :: struct {
	state: State,
	shell: Shell,
	rom: ^rico.Memory, 
	ram: ^rico.Memory,
	code: string,
	path: string,
	game: luabind.Cart,
	watch: Watch,
	boot: int,
}

console_init :: proc(con: ^Console) {
	shell_init(&con.shell)

	con.rom = new(rico.Memory)
	con.ram = new(rico.Memory)
	rico.init(con.rom, .Standard)
	rico.init(con.ram, .Standard)
}

console_destroy :: proc(con: ^Console) {
	luabind.unload(&con.game)
	watch_stop(&con.watch)
	shell_destroy(&con.shell)

	delete(con.code)
	delete(con.path)
	free(con.rom)
	free(con.ram)
}

main :: proc() {
	context.logger = log.create_console_logger()

	pf: platform.Interface = backend

	if !pf.init("RICO-16", 1024, 896) {
		return
	}
	defer pf.shutdown()

	con := new(Console)
	defer free(con)

	console_init(con)
	defer console_destroy(con)

	has_audio := pf.audio_open(rico.SAMPLE_RATE)
	audio := make([]f32, AUDIO_AHEAD)
	defer delete(audio)

	if len(os.args) > 1 && load_rom(con, os.args[1]) {
		run_game(con)
	}

	pixels := make([]u32, rico.SCREEN_MAX_W * rico.SCREEN_MAX_H)
	defer delete(pixels)

	FRAME :: 1.0 / 60.0
	acc := 0.0
	last := pf.time()
	last_check := last

	for pf.process_events() {
		now := pf.time()
		acc += min(now - last, 0.25)
		last = now

		keys: platform.Keys
		for k in platform.Key {
			if pf.key_pressed(k) {
				keys += {k}
			}
		}
		typed := pf.text_input()

		switch con.state {
		case .Boot:
			if keys != {} || typed != "" {
				con.state = .Shell
			}
		case .Shell:
			if .Escape in keys {
				con.state = .Editor
			} else if line, ok := shell_input(&con.shell, typed, keys); ok {
				run_command(con, line)
			}
		case .Running:
			if .Escape in keys {
				con.state = .Shell
			} else if .Tab in keys {
				next := rico.Mode((int(con.ram.mode) + 1) % len(rico.Mode))
				rico.set_mode(con.ram, next)
			}
		case .Editor:
			if .Escape in keys {
				con.state = .Shell
			}
		}

		if con.path != "" && now - last_check > 0.5 {
			last_check = now
			if watch_changed(&con.watch) {
				reload(con)
			}
		}

		ticked := false

		for acc >= FRAME {
			if con.state == .Running {
				for p in 0..<rico.MAX_PLAYERS {
					rico.update_pad(con.ram, p, transmute(rico.Buttons)pf.pad(p))
				}
				luabind.update(&con.game)
			}

			if con.state == .Boot {
				con.boot += 1
				if con.boot >= BOOT_FRAMES {
					con.state = .Shell
				}
			}

			con.shell.blink += 1
			ticked = true
			acc -= FRAME
		}

		if has_audio {
			if need := AUDIO_AHEAD - pf.audio_queued(); need > 0 {
				if con.state == .Running {
					rico.mix(con.ram, audio[:need])
				} else {
					slice.zero(audio[:need])
				}
				pf.audio_push(audio[:need])
			}
		}

		screen := con.shell.mem

		switch con.state {
		case .Boot:
			draw_boot(screen, con.boot)
		case .Shell:
			shell_draw(&con.shell)
		case .Editor:
			draw_editor_stub(screen)
		case .Running:
			screen = con.ram
			if ticked {
				luabind.draw(&con.game)
				if con.game.err != "" {
					draw_error_scren(con.ram, con.game.err)
				}
			}
		}

		w, h := rico.screen_size(screen)
		rico.to_rgb(screen, pixels)
		pf.present(pixels, w, h)

		free_all(context.temp_allocator)
	}
}

reload :: proc(con: ^Console) {
	running := con.state == .Running
	log.infof("reloading %s", con.path)

	path := strings.clone(con.path, context.temp_allocator)
	if load_rom(con, path) && running {
		run_game(con)
	}
}
