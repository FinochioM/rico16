package main

// this file is a throwaway, its just to test if the pad works and if everything is well

import "core:fmt"
import "core:strings"
import "rico16:rico"

ON :: 12
OFF :: 2

lit :: proc(mem: ^rico.Memory, b: rico.Button) -> u8 {
	return ON if rico.btn(mem, b) else OFF
}

face_button :: proc(mem: ^rico.Memory, x, y: int, label: string, b: rico.Button) {
	rico.circfill(mem, x, y, 6, lit(mem, b))
	rico.print(mem, label, x - 1, y - 2, 0)
}

centered :: proc(mem: ^rico.Memory, s: string, cx, y: int, col: u8) {
	rico.print(mem, s, cx - rico.text_width(mem,s) / 2, y, col)
}

held_names :: proc(mem: ^rico.Memory, player: int) -> string {
	sb := strings.builder_make(context.temp_allocator)
	for b in rico.Button {
		if rico.btn(mem, b, player) {
			fmt.sbprintf(&sb, "%v ", b)
		}
	}
	return strings.to_string(sb)
}

draw_pad_tester :: proc(mem: ^rico.Memory, counter: int) {
	w, h := rico.screen_size(mem)
	cx, cy := w / 2, h / 2 - 10

	rico.cls(mem, 0)
	centered(mem, "PAD TESTER", cx, 8, 5)

	rico.rectfill(mem, cx - 80, cy - 30, cx + 80, cy + 30, 1)
	rico.circfill(mem, cx - 80, cy, 30, 1)
	rico.circfill(mem, cx + 80, cy, 30, 1)

	rico.rectfill(mem, cx - 100, cy - 44, cx - 60, cy - 37, lit(mem, .L))
	rico.rectfill(mem, cx + 60, cy - 44, cx + 100, cy - 37, lit(mem, .R))

	dx := cx - 80
	rico.rectfill(mem, dx - 18, cy - 6, dx - 7, cy + 6, lit(mem, .Left))
	rico.rectfill(mem, dx + 7, cy - 6, dx + 18, cy + 6, lit(mem, .Right))
	rico.rectfill(mem, dx - 6, cy - 18, dx + 6, cy - 7, lit(mem, .Up))
	rico.rectfill(mem, dx - 6, cy + 7, dx + 6, cy + 18, lit(mem, .Down))

	fx := cx + 80
	face_button(mem, fx + 14, cy, "A", .A)
	face_button(mem, fx, cy + 14, "B", .B)
	face_button(mem, fx, cy - 14, "X", .X)
	face_button(mem, fx - 14, cy, "Y", .Y)

	rico.rectfill(mem, cx - 10, cy + 10, cx + 10, cy + 14, lit(mem, .Start))
	centered(mem, "start", cx, cy + 18, 3)

	for p in 1..<rico.MAX_PLAYERS {
		rico.print(mem, fmt.tprintf("p%d: %s", p + 1, held_names(mem, p)), 8, h - 54 + (p - 1) * 7, 3)
	}

	rico.print(mem, fmt.tprintf("btnp up/down: %d", counter), 8, h - 28, 4)
	rico.print(mem, "keys: arrows x z s a q w enter  tab: mode", 8, h - 12, 3)
}
