package main

import "core:os"
import "core:strings"
import "core:time"

Watch :: struct {
	paths: [3]string,
	last: [3]time.Time,
}

watch_start :: proc(w: ^Watch, path: string) {
	sheet, pals := art_paths(path)
	w.paths = {path, strings.clone(sheet), strings.clone(pals)}

	for p, i in w.paths {
		w.last[i], _ = os.modification_time_by_path(p)
	}
}

watch_stop :: proc(w: ^Watch) {
	delete(w.paths[1])
	delete(w.paths[2])
	w^ = {}
}

watch_changed :: proc(w: ^Watch) -> bool {
	changed := false

	for p, i in w.paths {
		if p == "" {
			continue
		}

		t, err := os.modification_time_by_path(p)
		if err != nil || t == w.last[i] {
			continue
		}

		w.last[i] = t
		changed = true
	}

	return changed
}
