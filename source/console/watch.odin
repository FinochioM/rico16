package main

import "core:os"
import "core:time"

Watch :: struct {
	path: string,
	last: time.Time,
}

watch_start :: proc(w: ^Watch, path: string) {
	w.path = path
	w.last, _ = os.modification_time_by_path(path)
}

watch_changed :: proc(w: ^Watch) -> bool {
	t, err := os.modification_time_by_path(w.path)
	if err != nil || t ==  w.last {
		return false
	}

	w.last = t

	return true
}
