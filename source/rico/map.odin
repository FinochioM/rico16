package rico

MAP_LAYERS :: 4
MAP_SIZE :: 128

Map_Layer :: struct {
	w, h: int,
	tiles: [MAP_SIZE * MAP_SIZE]u16,
}

reset_maps :: proc(mem: ^Memory) {
	for &m in mem.maps {
		m.w, m.h = MAP_SIZE, MAP_SIZE
		m.tiles = {}
	}
}

map_size :: proc(mem: ^Memory, layer, w, h:int) {
	if layer < 0 || layer >= MAP_LAYERS {
		return
	}

	mem.maps[layer].w = clamp(w, 1, MAP_SIZE)
	mem.maps[layer].h = clamp(h, 1, MAP_SIZE)
}

mset :: proc(mem: ^Memory, layer, cx, cy, n:int) {
	if layer < 0 || layer >= MAP_LAYERS || n < 0 || n >= MAX_SPRITES {
		return
	}

	m := &mem.maps[layer]
	if cx < 0 || cy < 0 || cx >= m.w || cy >= m.h {
		return
	}

	m.tiles[cy * MAP_SIZE + cx] = u16(n)
}

mget :: proc(mem: ^Memory, layer, cx, cy: int) -> int {
	if layer < 0 || layer >= MAP_LAYERS {
		return 0
	}

	m := &mem.maps[layer]
	if cx < 0 || cy < 0 || cx >= m.w || cy >= m.h {
		return 0
	}

	return int(m.tiles[cy * MAP_SIZE + cx])
}

@(private)
map_texel :: proc(mem: ^Memory, m: ^Map_Layer, wx, wy: int) -> (c, p: u8, ok: bool) {
	px := wx %% (m.w * SPRITE_SIZE)
	py := wy %% (m.h * SPRITE_SIZE)

	n := m.tiles[(py / SPRITE_SIZE) * MAP_SIZE + px / SPRITE_SIZE]
	if n == 0 {
		return
	}

	c = mem.sprites[n][(py % SPRITE_SIZE) * SPRITE_SIZE + px % SPRITE_SIZE]

	return c, mem.sprite_pal[n], true
}

draw_map :: proc(mem: ^Memory, layer, x, y: int) {
	if layer < 0 || layer >= MAP_LAYERS {
		return
	}

	m := &mem.maps[layer]
	w, h := screen_size(mem)

	ox := x - mem.camera.x
	oy := y - mem.camera.y

	for sy in 0..<h {
		for sx in 0..<w {
			if c, p, ok := map_texel(mem, m, sx - ox, sy - oy); ok {
				plot(mem, sx, sy, c, p)
			}
		}
	}
}
