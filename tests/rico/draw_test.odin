package rico_tests

import "core:testing"
import "rico16:rico"

@(test)
pset_pget :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.pset(mem, 10, 20, 7)
	testing.expect_value(t, rico.pget(mem, 10, 20), 7)
	testing.expect_value(t, rico.pget(mem, -1, 0), 0) 
	rico.pset(mem, 300, 0, 5) 

	rico.cls(mem, 3)
	testing.expect_value(t, rico.pget(mem, 255, 223), 3)
}

@(test)
line_rect :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.line(mem, 0, 0, 9, 9, 2)
	testing.expect_value(t, rico.pget(mem, 5, 5), 2)
	testing.expect_value(t, rico.pget(mem, 5, 6), 0)

	rico.rectfill(mem, 20, 20, 10, 10, 6)
	testing.expect_value(t, rico.pget(mem, 10, 10), 6)
	testing.expect_value(t, rico.pget(mem, 20, 20), 6)
	testing.expect_value(t, rico.pget(mem, 21, 20), 0)

	rico.rectfill(mem, -50, -50, 1000, 1000, 1)
	testing.expect_value(t, rico.pget(mem, 255, 223), 1)

	rico.rect(mem, 30, 30, 40, 40, 8)
	testing.expect_value(t, rico.pget(mem, 40, 35), 8)
	testing.expect_value(t, rico.pget(mem, 35, 35), 1)
}

@(test)
circles :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.circ(mem, 50, 50, 5, 9)
	testing.expect_value(t, rico.pget(mem, 55, 50), 9)
	testing.expect_value(t, rico.pget(mem, 50, 45), 9)
	testing.expect_value(t, rico.pget(mem, 50, 50), 0)

	rico.circfill(mem, 100, 100, 5, 11)
	testing.expect_value(t, rico.pget(mem, 100, 100), 11)
	testing.expect_value(t, rico.pget(mem, 105, 100), 11)
	testing.expect_value(t, rico.pget(mem, 106, 100), 0)

	rico.circfill(mem, 10, 10, 0, 3)
	testing.expect_value(t, rico.pget(mem, 10, 10), 3)
	testing.expect_value(t, rico.pget(mem, 11, 10), 0)
}
