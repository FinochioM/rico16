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
