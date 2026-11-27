package main

import "core:strings"
import "rico16:rico"

draw_error_scren :: proc(mem: ^rico.Memory, err: string) {
	w, h := rico.screen_size(mem)

	rico.pal_reset(mem)
	rico.camera(mem, 0, 0)

	rico.cls(mem, 1)
	rico.rectfill(mem, 0, 0, w - 1, 10, 11)
	rico.print(mem, "CART STOPPED", 4, 2, 5)

	y := 16

	for line in wrap(mem, err, w - 8) {
		if y > h - 20 {
			break
		}

		rico.print(mem, line, 4, y, 4)
		y += rico.LINE_HEIGHT
	}

	rico.print(mem, "fix the cart and save, it reloads by itself", 4, h - 10, 3)
}

wrap :: proc(mem: ^rico.Memory, text: string, width: int) -> []string {
	lines := make([dynamic]string, context.temp_allocator)

	rest := text

	for para in strings.split_lines_iterator(&rest) {
		line := para

		for rico.text_width(mem, line) > width {
			fit := 1
			for fit < len(line) && rico.text_width(mem, line[:fit + 1]) <= width {
				fit += 1
			}

			if space := strings.last_index_byte(line[:fit], ' '); space > 0 {
				fit = space + 1
			}

			append(&lines, line[:fit])
			line = line[fit:]
		}

		append(&lines, line)
	}

	return lines[:]
}
