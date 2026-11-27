package rico_tests

import "core:testing"
import "rico16:rico"

@(test)
mode7_line_steps :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.map_size(mem, 0, 4, 4)
	rico.mset(mem, 0, 1, 0, 1)

	rico.cls(mem, 3)
	rico.mode7_line(mem, 0, 5, 16, 0, 1, 0)
	testing.expect_value(t, rico.pget(mem, 0, 5), 5)
	testing.expect_value(t, rico.pget(mem, 1, 5), 3)
	testing.expect_value(t, rico.pget(mem, 0, 4), 3)

	rico.mode7_line(mem, 0, 6, 16, 1, 1.5, 0)
	testing.expect_value(t, rico.pget(mem, 2, 6), 9)

	rico.mode7_line(mem, 0, 7, 16 + 64, 0 - 64, 0, 1)
	testing.expect_value(t, rico.pget(mem, 0, 7), 5)
	testing.expect_value(t, rico.pget(mem, 1, 7), 3)
}

@(test)
mode7_floor :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	for y in 0..<16 {
		for x in 0..<16 {
			rico.sset(mem, 16 + x, y, 6)
			rico.sset(mem, 32 + x, y, 9)
		}
	}

	rico.map_size(mem, 0, 16, 16)
	for cy in 0..<16 {
		for cx in 0..<16 {
			rico.mset(mem, 0, cx, cy, 1)
		}
	}
	rico.mset(mem, 0, 4, 2, 2)

	rico.cls(mem, 3)
	rico.mode7(mem, 0, 72, 100, 0, 16, 100)
	testing.expect_value(t, rico.pget(mem, 10, 50), 3)
	testing.expect_value(t, rico.pget(mem, 10, 100), 3)
	testing.expect_value(t, rico.pget(mem, 10, 223), 6)

	testing.expect_value(t, rico.pget(mem, 128, 134), 9)

	rico.mode7(mem, 0, 72, 100, 0.5, 16, 100)
	testing.expect_value(t, rico.pget(mem, 128, 134), 6)
	rico.mode7(mem, 0, 72, 100, 0.25, 16, 100)
	testing.expect_value(t, rico.pget(mem, 128, 134), 6)
}
