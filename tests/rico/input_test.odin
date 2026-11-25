package rico_tests

import "core:testing"
import "rico16:rico"

@(test)
btn_btnp :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	testing.expect(t, !rico.btn(mem, .A))

	rico.update_pad(mem, 0, {.A})
	testing.expect(t, rico.btn(mem, .A))
	testing.expect(t, rico.btnp(mem, .A))
	testing.expect(t, !rico.btn(mem, .B))

	rico.update_pad(mem, 0, {.A})
	testing.expect(t, rico.btn(mem, .A))
	testing.expect(t, !rico.btnp(mem, .A))

	testing.expect(t, !rico.btn(mem, .A, 1))
	testing.expect(t, !rico.btn(mem, .A, 9))

	rico.update_pad(mem, 0, {})
	testing.expect(t, !rico.btn(mem, .A))
	testing.expect(t, !rico.btnp(mem, .A))
}

@(test)
btnp_repeat :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	fired: [dynamic]int
	defer delete(fired)

	for frame in 1..=23 {
		rico.update_pad(mem, 0, {.Left})
		if rico.btnp(mem, .Left) {
			append(&fired, frame)
		}
	}

	testing.expect_value(t, len(fired), 3)
	testing.expect_value(t, fired[0], 1)
	testing.expect_value(t, fired[1], rico.REPEAT_DELAY + 1)
	testing.expect_value(t, fired[2], rico.REPEAT_DELAY + 1 + rico.REPEAT_RATE)
}
