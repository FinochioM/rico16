package rico_tests

import "core:testing"
import "rico16:rico"

fill_sfx :: proc(mem: ^rico.Memory, n, pitch: int, wave: rico.Wave, vol, speed: int) {
	for i in 0..<rico.SFX_NOTES {
		rico.sfx_note(mem, n, i, {pitch = u8(pitch), wave = wave, vol = u8(vol)})
	}
	rico.sfx_speed(mem, n, speed)
}

@(test)
silent_when_idle :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	buf: [1000]f32
	rico.mix(mem, buf[:])

	for s in buf {
		testing.expect_value(t, s, 0)
	}
}

@(test)
square_has_the_right_pitch :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	fill_sfx(mem, 0, 57, .Square, 7, 16)
	rico.sfx(mem, 0)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS].sfx, 0)

	buf: [rico.SAMPLE_RATE / 10 + 200]f32
	rico.mix(mem, buf[:])

	rises := 0
	for i in 201..<len(buf) {
		if buf[i - 1] < 0 && buf[i] > 0 {
			rises += 1
		}
	}

	testing.expect(t, rises >= 43 && rises <= 45, "about 44 cycles of A4 in 0.1 s")
}

@(test)
sfx_stops_after_last_note :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	rico.sfx_note(mem, 3, 0, {pitch = 40, wave = .Triangle, vol = 5})
	rico.sfx_speed(mem, 3, 1)
	rico.sfx(mem, 3)

	buf: [rico.TICK + 100]f32
	rico.mix(mem, buf[:])

	ch := mem.channels[rico.MUSIC_CHANNELS]
	testing.expect_value(t, ch.sfx, -1)
	testing.expect_value(t, buf[len(buf) - 1], 0)

	rico.sfx(mem, 3)
	rico.sfx(mem, 3)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS + 1].sfx, 3)

	rico.sfx_stop(mem)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS].sfx, -1)
	testing.expect_value(t, mem.channels[rico.MUSIC_CHANNELS + 1].sfx, -1)
}

@(test)
sfx_loops :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	fill_sfx(mem, 1, 50, .Saw, 4, 1)
	rico.sfx_speed(mem, 1, 1, 2, 4)
	rico.sfx(mem, 1, 6)

	buf: [rico.TICK * 9]f32
	rico.mix(mem, buf[:])

	ch := mem.channels[6]
	testing.expect_value(t, ch.sfx, 1)
	testing.expect_value(t, ch.note, 3)
}

@(test)
music_follows_patterns :: proc(t: ^testing.T) {
	mem := new(rico.Memory)
	defer free(mem)
	rico.init(mem, .Standard)

	fill_sfx(mem, 0, 45, .Square, 3, 1)
	fill_sfx(mem, 1, 52, .Triangle, 5, 1)
	rico.set_pattern(mem, 0, {0, 1, -1, -1}, {.Loop_Start})
	rico.set_pattern(mem, 1, {1, -1, -1, -1}, {.Loop_End})
	rico.set_pattern(mem, 2, {0, -1, -1, -1}, {.Stop})

	PATTERN :: rico.SFX_NOTES * rico.TICK

	rico.music(mem, 0)
	testing.expect_value(t, mem.music.pattern, 0)
	testing.expect_value(t, mem.channels[1].sfx, 1)

	buf := make([]f32, PATTERN + 1)
	defer delete(buf)

	rico.mix(mem, buf)
	testing.expect_value(t, mem.music.pattern, 1)
	testing.expect_value(t, mem.channels[0].sfx, 1)
	testing.expect_value(t, mem.channels[1].sfx, -1)

	rico.mix(mem, buf[:PATTERN])
	testing.expect_value(t, mem.music.pattern, 0)

	rico.music(mem, 2)
	rico.mix(mem, buf)
	testing.expect_value(t, mem.music.pattern, -1)
	testing.expect_value(t, mem.channels[0].sfx, -1)

	rico.music(mem, 1)
	rico.music(mem, -1)
	testing.expect_value(t, mem.music.pattern, -1)
	testing.expect_value(t, mem.channels[0].sfx, -1)
}
