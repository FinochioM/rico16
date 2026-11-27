package main

import "core:strings"
import "rico16:platform"
import "rico16:rico"

TEXT :: 4
BRIGHT :: 5
GOOD :: 9
BAD :: 12
PROMPT :: 15
MAX_LINES :: 100
BOOT_FRAMES :: 90

Line :: struct {
	text: string,
	col: u8,
}

Shell :: struct {
	mem: ^rico.Memory,
	lines: [dynamic]Line,
	input: [dynamic]u8,
	history: [dynamic]string,
	hist_pos: int,
	blink: int,
}

shell_init :: proc(sh: ^Shell) {
	sh.mem = new(rico.Memory)
	rico.init(sh.mem, .Standard)

	shell_print(sh, "RICO-16", BRIGHT)
	shell_print(sh, "type help")
}

shell_destroy :: proc(sh: ^Shell) {
	shell_clear(sh)
	delete(sh.lines)

	for h in sh.history {
		delete(h)
	}

	delete(sh.history)
	delete(sh.input)

	free(sh.mem)
}

shell_print :: proc(sh: ^Shell, text: string, col: u8 = TEXT) {
	w, _ := rico.screen_size(sh.mem)

	for l in wrap(sh.mem, text, w - 4) {
		append(&sh.lines, Line{strings.clone(l), col})
	}

	for len(sh.lines) > MAX_LINES {
		delete(sh.lines[0].text)
		ordered_remove(&sh.lines, 0)
	}
}

shell_clear :: proc(sh: ^Shell) {
	for l in sh.lines {
		delete(l.text)
	}

	clear(&sh.lines)
}

shell_input :: proc(sh: ^Shell, typed: string, keys: platform.Keys) -> (line: string, ok: bool) {
	for ch in typed {
		if ch >= ' ' && ch <= '~' {
			append(&sh.input, u8(ch))
		}
	}

	if .Backspace in keys && len(sh.input) > 0 {
		pop(&sh.input)
	}

	if .Up in keys && sh.hist_pos > 0 {
		sh.hist_pos -= 1
		set_input(sh, sh.history[sh.hist_pos])
	}

	if .Down in keys && sh.hist_pos < len(sh.history) {
		sh.hist_pos += 1
		set_input(sh, sh.history[sh.hist_pos] if sh.hist_pos < len(sh.history) else "")
	}

	if .Enter not_in keys {
		return
	}

	line = strings.clone(string(sh.input[:]), context.temp_allocator)
	clear(&sh.input)

	shell_print(sh, strings.concatenate({"> ", line}, context.temp_allocator), PROMPT)

	if line != "" {
		append(&sh.history, strings.clone(line))
	}

	sh.hist_pos = len(sh.history)

	return line, true
}

set_input :: proc(sh: ^Shell, s:string) {
	clear(&sh.input)
	append(&sh.input, s)
}

shell_draw :: proc(sh: ^Shell) {
	mem := sh.mem
	_, h := rico.screen_size(mem)

	rico.cls(mem, 0)

	rows := (h - 4) / rico.LINE_HEIGHT - 1
	start := max(len(sh.lines) - rows, 0)
	y := 2

	for l in sh.lines[start:] {
		rico.print(mem, l.text, 2, y, l.col)
		y += rico.LINE_HEIGHT
	}

	x := rico.print(mem, ">", 2, y, PROMPT) + 2
	x = rico.print(mem, string(sh.input[:]), x, y, BRIGHT)

	if sh.blink / 20 % 2 == 0 {
		rico.rectfill(mem, x, y, x + 3, y + 5, PROMPT)
	}
}

draw_boot :: proc(mem: ^rico.Memory, frames: int) {
	w, h := rico.screen_size(mem)
	title := "RICO-16"

	rico.cls(mem, 0)
	rico.print(mem, title, w / 2 - rico.text_width(mem, title) / 2, h / 2 - 8, BRIGHT)
	rico.rectfill(mem, w / 2 - 40, h / 2 + 4, w / 2 - 40 + frames * 80 / BOOT_FRAMES, h / 2 + 6, GOOD)
}

draw_editor_stub :: proc(mem: ^rico.Memory) {
	rico.cls(mem, 1)
	rico.print(mem, "EDITORS", 4, 4, BRIGHT)

	rico.print(mem, "nothing here yet", 4, 16, TEXT)
	rico.print(mem, "esc: back to the shell", 4, 26, 3)
}
