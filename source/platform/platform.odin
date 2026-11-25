package platform

// extra key that won't be part of the pad in the future
Key :: enum u8 {
	Tab,
}

// this represents everything the console needs from the machine it runs on.
// backends would fill this in and the console picks one at compile time.
Interface :: struct #all_or_none {
	init: proc(title: string, width, height: int) -> bool,
	shutdown: proc(),
	process_events: proc() -> bool, // would be false when window close event gets called
	present: proc(pixels: []u32, width, height: int),
	time: proc() -> f64,
	key_pressed: proc(k: Key) -> bool,
}
