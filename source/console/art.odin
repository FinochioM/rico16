package main

import "core:log"
import "core:os"
import "core:strings"
import "rico16:rico"

art_paths :: proc(path: string) -> (sheet, pals: string) {
	base := strings.trim_suffix(path, ".lua")
	sheet = strings.concatenate({base, ".png"}, context.temp_allocator)
	pals = strings.concatenate({base, ".pal.png"}, context.temp_allocator)

	return
}

load_art :: proc(mem: ^rico.Memory, path: string) {
	sheet, pals := art_paths(path)

	rico.reset_palettes(mem)
	rico.pal_reset(mem)
	mem.sprites = {}
	mem.sprite_pal = {}

	rico.reset_maps(mem)
	rico.camera(mem, 0, 0)

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
