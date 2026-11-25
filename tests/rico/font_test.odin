package rico_tests

import "core:testing"
import "rico16:rico"

@(test)
print_glyphs :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	end := rico.print(mem, "A", 10, 10, 5)
	testing.expect_value(t, end, 14)
	testing.expect_value(t, rico.pget(mem, 11, 11), 5)
	testing.expect_value(t, rico.pget(mem, 10, 11), 0)
	testing.expect_value(t, rico.pget(mem, 10, 12), 5)
	testing.expect_value(t, rico.pget(mem, 11, 10), 0)

	rico.cls(mem)
	rico.print(mem, "A\nB", 0, 0, 7)
	testing.expect_value(t, rico.pget(mem, 0, rico.LINE_HEIGHT + 1), 7)

	rico.cls(mem)
	rico.print(mem, " ", 0, 0, 3)
	for y in 0..<6 {
		for x in 0..<6 {
			testing.expect_value(t, rico.pget(mem, x, y), 0)
		}
	}

	testing.expect_value(t, rico.text_width("é"), rico.text_width("?"))

	rico.print(mem, "clip", -2, -2, 1)
	rico.print(mem, "clip", 254, 220, 1)
}

@(test)
text_width :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)

	rico.init(mem, .Standard)

	testing.expect_value(t, rico.text_width(""), 0)
	testing.expect_value(t, rico.text_width("A"), 3)
	testing.expect_value(t, rico.text_width("AA"), 7)
	testing.expect_value(t, rico.text_width("A\nAA"), 7)
	testing.expect_value(t, rico.text_width("M"), 5)
}
