package rico

import "core:math"

SAMPLE_RATE :: 22050
TICK :: 183 
CHANNELS :: 8
MUSIC_CHANNELS :: 4
MAX_SFX :: 64
SFX_NOTES :: 32
MAX_PATTERNS :: 64
MAX_PITCH :: 95 
VOL_STEP :: 1.0 / 64 

Wave :: enum u8 {
	Sine, Triangle, Saw, Square,
	Pulse, Thin, Organ, Noise,
}

Effect :: enum u8 {
	None, Slide, Vibrato, Drop,
	Fade_In, Fade_Out, Arp_Fast, Arp_Slow,
}

Note :: struct {
	pitch: u8,
	wave: Wave,
	vol: u8,
	fx: Effect,
}

Sfx :: struct {
	notes: [SFX_NOTES]Note,
	speed: u8,
	loop_start, loop_end: u8,
}

Pattern_Flag :: enum u8 {
	Loop_Start, Loop_End, Stop,
}

Pattern_Flags :: bit_set[Pattern_Flag; u8]

Pattern :: struct {
	sfx: [MUSIC_CHANNELS]i8, 
	flags: Pattern_Flags,
}

Channel :: struct {
	sfx: int, 
	note: int,
	tick: int, 
	length: int, 
	wave: Wave,
	freq: f64,
	phase: f64,
	vol: f64,
	prev_pitch, prev_vol: f64,
	noise: u32,
	noise_val: f64,
}

Music_State :: struct {
	pattern: int, 
	left: int, 
}

reset_sound :: proc(mem: ^Memory) {
	for &s in mem.sfx {
		s = {speed = 16}
	}

	for &p in mem.patterns {
		p = {sfx = -1}
	}

	for &ch, i in mem.channels {
		ch = {sfx = -1, noise = 0x9e3779b9 + u32(i)}
	}

	mem.music = {pattern = -1}
}

sfx_note :: proc(mem: ^Memory, n, i: int, note: Note) {
	if n < 0 || n >= MAX_SFX || i < 0 || i >= SFX_NOTES {
		return
	}

	mem.sfx[n].notes[i] = {
		pitch = min(note.pitch, MAX_PITCH),
		wave = Wave(u8(note.wave) & 7),
		vol = min(note.vol, 7),
		fx = Effect(u8(note.fx) & 7),
	}
}

sfx_speed :: proc(mem: ^Memory, n, speed: int, loop_start := 0, loop_end := 0) {
	if n < 0 || n >= MAX_SFX {
		return
	}

	s := &mem.sfx[n]
	s.speed = u8(clamp(speed, 1, 255))
	s.loop_start = u8(clamp(loop_start, 0, SFX_NOTES))
	s.loop_end = u8(clamp(loop_end, 0, SFX_NOTES))
}

set_pattern :: proc(mem: ^Memory, p: int, sfx: [MUSIC_CHANNELS]int, flags: Pattern_Flags = {}) {
	if p < 0 || p >= MAX_PATTERNS {
		return
	}

	for n, i in sfx {
		mem.patterns[p].sfx[i] = i8(n) if n >= 0 && n < MAX_SFX else -1
	}

	mem.patterns[p].flags = flags
}

@(private)
start_channel :: proc(mem: ^Memory, ch: ^Channel, n, length: int) {
	first := mem.sfx[n].notes[0]

	ch.sfx = n
	ch.note = 0
	ch.tick = 0
	ch.length = length
	ch.prev_pitch = f64(first.pitch)
	ch.prev_vol = f64(first.vol) / 7
}

@(private)
audible_length :: proc(s: ^Sfx) -> int {
	last := SFX_NOTES
	for last > 1 && s.notes[last - 1].vol == 0 {
		last -= 1
	}
	return last
}

sfx :: proc(mem: ^Memory, n: int, channel := -1) {
	if n < 0 || n >= MAX_SFX || channel >= CHANNELS {
		return
	}

	c := channel
	if c < 0 {
		c = MUSIC_CHANNELS
		for i in MUSIC_CHANNELS..<CHANNELS {
			if mem.channels[i].sfx < 0 {
				c = i
				break
			}
			if mem.channels[i].note > mem.channels[c].note {
				c = i
			}
		}
	}

	start_channel(mem, &mem.channels[c], n, audible_length(&mem.sfx[n]))
}

sfx_stop :: proc(mem: ^Memory, channel := -1) {
	if channel >= 0 && channel < CHANNELS {
		mem.channels[channel].sfx = -1
		return
	}

	for i in MUSIC_CHANNELS..<CHANNELS {
		mem.channels[i].sfx = -1
	}
}

music :: proc(mem: ^Memory, p: int) {
	if p < 0 || p >= MAX_PATTERNS {
		music_stop(mem)
		return
	}

	start_pattern(mem, p)
}

music_stop :: proc(mem: ^Memory) {
	if mem.music.pattern < 0 {
		return
	}

	mem.music.pattern = -1
	for i in 0..<MUSIC_CHANNELS {
		mem.channels[i].sfx = -1
	}
}

@(private)
start_pattern :: proc(mem: ^Memory, p: int) {
	pat := &mem.patterns[p]
	ruler := -1

	for n, i in pat.sfx {
		ch := &mem.channels[i]

		if n < 0 {
			ch.sfx = -1
			continue
		}

		start_channel(mem, ch, int(n), SFX_NOTES)

		s := &mem.sfx[n]
		loops := s.loop_end > s.loop_start
		if ruler < 0 || (!loops && mem.sfx[ruler].loop_end > mem.sfx[ruler].loop_start) {
			ruler = int(n)
		}
	}

	if ruler < 0 {
		mem.music = {pattern = -1}
		return
	}

	mem.music.pattern = p
	mem.music.left = SFX_NOTES * int(mem.sfx[ruler].speed) * TICK
}

@(private)
next_pattern :: proc(mem: ^Memory) {
	p := mem.music.pattern
	flags := mem.patterns[p].flags

	switch {
	case .Stop in flags:
		music_stop(mem)
	case .Loop_End in flags:
		back := p
		for back > 0 && !(.Loop_Start in mem.patterns[back].flags) {
			back -= 1
		}
		start_pattern(mem, back)
	case p + 1 < MAX_PATTERNS:
		start_pattern(mem, p + 1)
	case:
		music_stop(mem)
	}
}

ARP := [3]f64{0, 4, 7}

@(private)
channel_sample :: proc(mem: ^Memory, ch: ^Channel) -> f64 {
	target := 0.0

	if ch.sfx >= 0 {
		s := &mem.sfx[ch.sfx]
		n := s.notes[ch.note]
		note_len := int(max(s.speed, 1)) * TICK
		t := f64(ch.tick) / f64(note_len)

		pitch := f64(n.pitch)
		vol := f64(n.vol) / 7

		switch n.fx {
		case .None:
		case .Slide:
			pitch = math.lerp(ch.prev_pitch, pitch, t)
			vol = math.lerp(ch.prev_vol, vol, t)
		case .Vibrato:
			pitch += 0.5 * math.sin(f64(ch.tick) / SAMPLE_RATE * math.TAU * 7)
		case .Drop:
			pitch *= 1 - t
		case .Fade_In:
			vol *= t
		case .Fade_Out:
			vol *= 1 - t
		case .Arp_Fast:
			pitch += ARP[(ch.tick / (TICK * 2)) % 3]
		case .Arp_Slow:
			pitch += ARP[(ch.tick / (TICK * 4)) % 3]
		}

		ch.wave = n.wave
		ch.freq = 440 * math.pow(2, (pitch - 57) / 12)
		target = vol

		ch.tick += 1
		if ch.tick >= note_len {
			ch.tick = 0
			ch.prev_pitch = f64(n.pitch)
			ch.prev_vol = f64(n.vol) / 7
			ch.note += 1

			if s.loop_end > s.loop_start && ch.note >= int(s.loop_end) {
				ch.note = int(s.loop_start)
			} else if ch.note >= ch.length {
				ch.sfx = -1
			}
		}
	}

	ch.vol += clamp(target - ch.vol, -VOL_STEP, VOL_STEP)
	if ch.vol <= 0 {
		ch.vol = 0
		return 0
	}

	out := wave_sample(ch) * ch.vol

	speed := 16.0 if ch.wave == .Noise else 1.0
	ch.phase += ch.freq * speed / SAMPLE_RATE
	if ch.phase >= 1 {
		ch.phase -= math.floor(ch.phase)

		ch.noise ~= ch.noise << 13
		ch.noise ~= ch.noise >> 17
		ch.noise ~= ch.noise << 5
		ch.noise_val = f64(ch.noise) / f64(max(u32)) * 2 - 1
	}

	return out
}

@(private)
tri :: proc(t: f64) -> f64 {
	return 1 - 4 * abs(t - 0.5)
}

@(private)
wave_sample :: proc(ch: ^Channel) -> f64 {
	t := ch.phase

	switch ch.wave {
	case .Sine:
		return math.sin(t * math.TAU)
	case .Triangle:
		return tri(t)
	case .Saw:
		return 2 * t - 1
	case .Square:
		return 1 if t < 0.5 else -1
	case .Pulse:
		return 1 if t < 0.25 else -1
	case .Thin:
		return 1 if t < 0.125 else -1
	case .Organ:
		return (tri(t) + tri(math.mod(t * 2, 1))) / 2
	case .Noise:
		return ch.noise_val
	}

	return 0
}

mix :: proc(mem: ^Memory, out: []f32) {
	for &sample in out {
		if mem.music.pattern >= 0 {
			if mem.music.left <= 0 {
				next_pattern(mem)
			}
			mem.music.left -= 1
		}

		v := 0.0
		for &ch in mem.channels {
			v += channel_sample(mem, &ch)
		}

		sample = f32(clamp(v * 0.25, -1, 1))
	}
}

sound_stop :: proc(mem: ^Memory) {
	mem.music.pattern = -1
	for &ch in mem.channels {
		ch.sfx = -1
	}
}
