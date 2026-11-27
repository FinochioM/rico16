package main

import "core:log"
import "core:os"
import "core:strings"
import "rico16:rico"
import "rico16:cart"

art_paths :: proc(path: string) -> (sheet, pals: string) {
	base := strings.trim_suffix(path, ".lua")
	sheet = strings.concatenate({base, ".png"}, context.temp_allocator)
	pals = strings.concatenate({base, ".pal.png"}, context.temp_allocator)

	return
}

load_art :: proc(mem: ^rico.Memory, path: string) {
	sheet, pals := art_paths(path)

	cart.clear(mem)

	if data, err := os.read_entire_file(pals, context.temp_allocator); err == nil {
		if rico.load_palettes(mem, data) {
			log.infof("palettes from %s", pals)
		} else {
			log.errorf("%s: not a palette png (16 px wide)", pals)
		}
	}

	if data, err := os.read_entire_file(sheet, context.temp_allocator); err == nil {
		if rico.load_sheet(mem, data) {
			log.infof("sprites from %s", sheet)
		} else {
			log.errorf("%s: cant read this png", sheet)
		}
	}
}

load_r16 :: proc(mem: ^rico.Memory, path: string) -> (code: string, ok: bool) {
	data, err := os.read_entire_file(path, context.temp_allocator)

	if err != nil {
		log.errorf("cant read %s: %v", path, err)
		return
	}

	code, ok = cart.read(mem, string(data), context.temp_allocator)

	if !ok {
		log.errorf("%s: not a rico16 cart", path)
	}

	return
}
