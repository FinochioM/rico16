package platform

// extra key that won't be part of the pad in the future
Key :: enum u8 {
	Tab,
}

Pad_Button :: enum u8 {
	Left, Right, Up, Down,
	A, B, X, Y,
	L, R, Start,
}

Pad_State :: bit_set[Pad_Button; u16]

MAX_PADS :: 4

// this represents everything the console needs from the machine it runs on.
// backends would fill this in and the console picks one at compile time.
Interface :: struct #all_or_none {
	init: proc(title: string, width, height: int) -> bool,
	shutdown: proc(),
	process_events: proc() -> bool, // would be false when window close event gets called
	present: proc(pixels: []u32, width, height: int),
	time: proc() -> f64,
	key_pressed: proc(k: Key) -> bool,
	pad: proc(player:int) -> Pad_State,
}
