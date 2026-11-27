package luabind_tests

import "core:testing"
import "rico16:luabind"
import "rico16:rico"

@(test)
sound_from_lua :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	cart: luabind.Cart
	defer luabind.unload(&cart)

	ok := run(t, mem, &cart, `
		function _init()
			for i = 0, 31 do sfxset(0, i, 45, 1, 6) end
			sfxspeed(0, 4)
			sfxset(1, 0, 60, 3, 7, 3)
			sfxspeed(1, 2)
			pattern(0, 2, 0)
			music(0)
			sfx(1)
		end
		function _update()
			if btn(4) then sfx(-1) music(-1) end
		end
	`)
	testing.expect(t, ok)
	testing.expect_value(t, cart.err, "")

	testing.expect_value(t, mem.music.pattern, 0)
	testing.expect_value(t, mem.channels[0].sfx, 0)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS].sfx, 1)
	testing.expect_value(t, mem.sfx[1].notes[0].wave, rico.Wave.Square)
	testing.expect_value(t, mem.sfx[1].notes[0].fx, rico.Effect.Drop)
	testing.expect(t, .Loop_End in mem.patterns[0].flags)

	buf: [500]f32
	rico.mix(mem, buf[:])
	loud := false
	for s in buf {
		if s != 0 {
			loud = true
		}
	}
	testing.expect(t, loud, "music plays")

	rico.update_pad(mem, 0, {.A})
	luabind.update(&cart)
	testing.expect_value(t, mem.music.pattern, -1)
	testing.expect_value(t, mem.channels[0].sfx, -1)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS].sfx, -1)
}
