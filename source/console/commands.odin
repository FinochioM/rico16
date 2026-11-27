package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "rico16:cart"
import "rico16:luabind"

HELP := [?]string {
	"load <cart>: load a .r16 or .lua cart",
	"run: run the loaded cart",
	"resume: go back to the currently running cart",
	"save [name]: save the cart as .r16",
	"ls: list carts and folders",
	"cd [folder]: change folder",
	"cls: clear the shell/screen",
	"esc: shell, editors and tools",
}

run_command :: proc(con: ^Console, line: string) {
	args := strings.fields(line, context.temp_allocator)
	if len(args) == 0 {
		return
	}

	arg := args[1] if len(args) > 1 else ""
	sh := &con.shell

	switch args[0] {
	case "help":
		for h in HELP {
			shell_print(sh, h)
		}
	case "load":
		if arg == "" {
			shell_print(sh, "load what?", BAD)
		} else {
			load_rom(con, arg)
		}
	case "run":
		run_game(con)
	case "resume":
		if con.game.L == nil {
			shell_print(sh, "nothing to resume", BAD)
		} else {
			con.state = .Running
		}
	case "save":
		save_rom(con, arg)
	case "ls":
		list_dir(con)
	case "cd":
		change_dir(con, arg)
	case "cls":
		shell_clear(sh)
	case:
		shell_print(sh, fmt.tprintf("unknown command: %s", args[0]), BAD)
	}
}

find_cart :: proc(name: string) -> string {
	if os.is_file(name) {
		return name
	}

	for ext in ([]string{".r16", ".lua"}) {
		p := strings.concatenate({name, ext}, context.temp_allocator)
		if os.is_file(p) {
			return p
		}
	}

	return ""
}

load_rom :: proc(con: ^Console, name: string) -> bool {
	sh := &con.shell

	found := find_cart(name)
	if found == "" {
		shell_print(sh, fmt.tprintf("can't find %s", name), BAD)
		return false
	}

	path, err := os.get_absolute_path(found, context.allocator)
	if err != nil {
		shell_print(sh, fmt.tprintf("can't open %s", found), BAD)
		return false
	}

	code: string

	if strings.has_suffix(path, ".r16") {
		c, ok := load_r16(con.rom, path)
		if !ok {
			shell_print(sh, fmt.tprintf("%s is not a rico16 cart", found), BAD)
			delete(path)
			return false
		}
		code = c
	} else {
		src, rerr := os.read_entire_file(path, context.temp_allocator)
		if rerr != nil {
			shell_print(sh, fmt.tprintf("can't read %s", found), BAD)
			delete(path)
			return false
		}
		con.rom.mode = .Standard
		load_art(con.rom, path)
		code = string(src)
	}

	delete(con.code)
	con.code = strings.clone(code)

	delete(con.path)
	con.path = path

	watch_stop(&con.watch)
	watch_start(&con.watch, con.path)

	_, file := os.split_path(path)
	shell_print(sh, fmt.tprintf("loaded %s (%d tokens)", file, luabind.count_tokens(code)), GOOD)
	return true
}

run_game :: proc(con: ^Console) -> bool {
	if con.path == "" {
		shell_print(&con.shell, "nothing loaded", BAD)
		return false
	}

	con.ram^ = con.rom^
	luabind.load(&con.game, con.ram, transmute([]byte)con.code, con.path)
	con.state = .Running

	return true
}

save_rom :: proc(con: ^Console, name: string) {
	sh := &con.shell

	target := name if name != "" else con.path
	if target == "" {
		shell_print(sh, "save as what? save <name>", BAD)
		return
	}

	switch {
	case strings.has_suffix(target, ".png"):
		shell_print(sh, "png carts aren't in yet", BAD)
		return
	case strings.has_suffix(target, ".lua"):
		target = strings.concatenate({strings.trim_suffix(target, ".lua"), ".r16"}, context.temp_allocator)
	case !strings.has_suffix(target, ".r16"):
		target = strings.concatenate({target, ".r16"}, context.temp_allocator)
	}

	text := cart.write(con.rom, con.code, context.temp_allocator)
	if err := os.write_entire_file(target, text); err != nil {
		shell_print(sh, fmt.tprintf("can't write %s: %v", target, err), BAD)
		return
	}

	if path, err := os.get_absolute_path(target, context.allocator); err == nil {
		delete(con.path)
		con.path = path

		watch_stop(&con.watch)
		watch_start(&con.watch, con.path)
	}

	_, file := os.split_path(target)
	shell_print(sh, fmt.tprintf("saved %s (%d bytes)", file, len(text)), GOOD)
}

list_dir :: proc(con: ^Console) {
	infos, err := os.read_all_directory_by_path(".", context.temp_allocator)
	if err != nil {
		shell_print(&con.shell, fmt.tprintf("can't list: %v", err), BAD)
		return
	}

	slice.sort_by(infos, proc(a, b: os.File_Info) -> bool {
		return a.name < b.name
	})

	for fi in infos {
		if strings.has_prefix(fi.name, ".") {
			continue
		}

		if fi.type == .Directory {
			shell_print(&con.shell, strings.concatenate({fi.name, "/"}, context.temp_allocator), PROMPT)
		} else if strings.has_suffix(fi.name, ".r16") || strings.has_suffix(fi.name, ".lua") {
			shell_print(&con.shell, fi.name, BRIGHT)
		}
	}
}

change_dir :: proc(con: ^Console, dir: string) {
	if dir != "" {
		if err := os.set_working_directory(dir); err != nil {
			shell_print(&con.shell, fmt.tprintf("no folder %s", dir), BAD)
			return
		}
	}

	if wd, err := os.get_working_directory(context.temp_allocator); err == nil {
		shell_print(&con.shell, wd)
	}
}
