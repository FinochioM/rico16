package rico_tests

import "core:testing"
import "rico16:rico"

@(test)
mset_mget :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.mset(mem, 2, 5, 7, 300)
	testing.expect_value(t, rico.mget(mem, 2, 5, 7), 300)
	testing.expect_value(t, rico.mget(mem, 1, 5, 7), 0)

	rico.mset(mem, 0, 127, 127, 1)
	testing.expect_value(t, rico.mget(mem, 0, 127, 127), 1)

	rico.mset(mem, 0, 128, 0, 1)
	rico.mset(mem, 4, 0, 0, 1)
	rico.mset(mem, 0, 0, 0, 512)
	testing.expect_value(t, rico.mget(mem, 0, 128, 0), 0)
	testing.expect_value(t, rico.mget(mem, 4, 0, 0), 0)
	testing.expect_value(t, rico.mget(mem, 0, 0, 0), 0)

	rico.map_size(mem, 0, 4, 2)
	testing.expect_value(t, rico.mget(mem, 0, 3, 1), 0)
	testing.expect_value(t, rico.mget(mem, 0, 127, 127), 0)
}

@(test)
draw_map_tiles :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)
	rico.sprpal(mem, 1, 2)

	rico.map_size(mem, 0, 4, 4)
	rico.mset(mem, 0, 1, 0, 1)
rico.cls(mem, 3)
	rico.draw_map(mem, 0, 0, 0)

	testing.expect_value(t, rico.pget(mem, 16, 0), 2 << 4 | 5)
	testing.expect_value(t, rico.pget(mem, 19, 1), 2 << 4 | 9)
	testing.expect_value(t, rico.pget(mem, 17, 0), 3)
	testing.expect_value(t, rico.pget(mem, 0, 0), 3)

	testing.expect_value(t, rico.pget(mem, 16 + 64, 0), 2 << 4 | 5)
	testing.expect_value(t, rico.pget(mem, 16 + 128, 64), 2 << 4 | 5)
}

@(test)
draw_map_offset :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.map_size(mem, 1, 4, 4)
	rico.mset(mem, 1, 1, 0, 1)

	rico.cls(mem)
	rico.draw_map(mem, 1, 10, 3)
	testing.expect_value(t, rico.pget(mem, 26, 3), 5)

	rico.cls(mem)
	rico.draw_map(mem, 1, -20, 0)
	testing.expect_value(t, rico.pget(mem, 60, 0), 5)
}

@(test)
camera_moves_everything :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)
	markers(mem)

	rico.cls(mem)
	rico.camera(mem, 10, 5)

	rico.pset(mem, 20, 20, 4)
	testing.expect_value(t, rico.pget(mem, 10, 15), 4)

	rico.rectfill(mem, 10, 5, 11, 6, 6)
	testing.expect_value(t, rico.pget(mem, 0, 0), 6)
	testing.expect_value(t, rico.pget(mem, 1, 1), 6)

	rico.spr(mem, 1, 50, 50)
	testing.expect_value(t, rico.pget(mem, 40, 45), 5)

	rico.sprx(mem, 1, 108, 105)
	testing.expect_value(t, rico.pget(mem, 90, 92), 5)

	rico.map_size(mem, 0, 2, 2)
	rico.mset(mem, 0, 1, 0, 1)
	rico.cls(mem)
	rico.draw_map(mem, 0, 0, 0)
	testing.expect_value(t, rico.pget(mem, 6, 0), 0)
	testing.expect_value(t, rico.pget(mem, 6, 27), 5)

	rico.camera(mem, 0, 0)
	rico.cls(mem)
	rico.pset(mem, 20, 20, 4)
	testing.expect_value(t, rico.pget(mem, 20, 20), 4)
}
