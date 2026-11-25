package rico

Button :: enum u8 {
	Left, Right, Up, Down,
	A, B, X, Y,
	L, R, Start,
}

Buttons :: bit_set[Button; u16]

MAX_PLAYERS :: 4

REPEAT_DELAY :: 15
REPEAT_RATE :: 4

update_pad :: proc(mem: ^Memory, player: int, state: Buttons) {
	if player < 0 || player >= MAX_PLAYERS {
		return
	}

	mem.pad[player] = state
	for b in Button {
		if b in state {
			mem.pad_held[player][b] = min(mem.pad_held[player][b] + 1, max(u16))
		} else {
			mem.pad_held[player][b] = 0
		}
	}
}

btn :: proc(mem: ^Memory, b: Button, player := 0) -> bool {
	if player < 0 || player >= MAX_PLAYERS {
		return false
	}

	return b in mem.pad[player]
}

btnp :: proc(mem: ^Memory, b: Button, player := 0) -> bool {
	if player < 0 || player >= MAX_PLAYERS {
		return false
	}

	held := int(mem.pad_held[player][b])
	if held == 1 {
		return true
	}

	return held > REPEAT_DELAY && (held - 1 - REPEAT_DELAY) % REPEAT_RATE == 0
}
