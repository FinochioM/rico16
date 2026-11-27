-- sound test: music loops, buttons fire sfx on top
-- the tune and sfx here are throwaway test sounds
-- a: jump  b: laser  x: boom  y: coin  start: music on/off

names = {c = 0, d = 2, e = 4, f = 5, g = 7, a = 9, b = 11}

function pitch(s)
	local p = names[s:sub(1, 1)]
	local i = 2
	local m = s:sub(2, 2)
	if m == "#" then
		p = p + 1
		i = 3
	elseif m == "b" then
		p = p - 1
		i = 3
	end
	return p + 12 * tonumber(s:sub(i))
end

-- fills sfx n from a string of notes, "." is a rest
function song(n, wave, vol, fx, str, speed)
	local i = 0
	for tok in str:gmatch("%S+") do
		if tok == "." then
			sfxset(n, i, 0, wave, 0)
		else
			sfxset(n, i, pitch(tok), wave, vol, fx)
		end
		i = i + 1
	end
	sfxspeed(n, speed)
end

drums = "c1 . f6 . e3 . f6 . c1 . f6 . e3 . f6 . c1 . f6 . e3 . f6 . c1 c1 f6 . e3 . e3 f6"

function _init()
	song(0, 1, 6, 0, "c2 . c2 . c3 . c2 . g1 . g1 . g2 . g1 . ab1 . ab1 . ab2 . ab1 . bb1 . bb1 . bb2 . bb1 .", 12)
	song(1, 4, 4, 0, "c4 . eb4 . g4 . eb4 . d4 . . . bb3 . . . c4 . eb4 . ab4 . g4 . f4 . eb4 . d4 . . .", 12)
	song(2, 7, 3, 5, drums, 12)
	song(3, 1, 6, 0, "f1 . f1 . f2 . f1 . ab1 . ab1 . ab2 . ab1 . g1 . g1 . g2 . g1 . g1 . g1 . b1 . d2 .", 12)
	song(4, 4, 4, 2, "f4 . . . ab4 . g4 . f4 . eb4 . d4 . . . eb4 . f4 . g4 . . . . . . . . . . .", 12)

	pattern(0, 1, 0, 1, 2)
	pattern(1, 2, 3, 4, 2)

	song(10, 3, 5, 1, "c4 g4 c5", 3)
	song(11, 2, 5, 3, "c6 c5", 4)
	song(12, 7, 7, 5, "c3 c2", 10)
	song(13, 4, 4, 6, "e5 b5", 8)

	music(0)
	playing = true
	last = ""
	flash = 0
	t = 0
end

fire = {
	{4, 10, "jump"},
	{5, 11, "laser"},
	{6, 12, "boom"},
	{7, 13, "coin"},
}

function _update()
	t = t + 1
	for _, f in ipairs(fire) do
		if btnp(f[1]) then
			sfx(f[2])
			last = f[3]
			flash = 8
		end
	end

	if btnp(10) then
		playing = not playing
		music(playing and 0 or -1)
	end

	if flash > 0 then flash = flash - 1 end
end

function _draw()
	cls(1)
	print("SOUND TEST", 8, 8, 5)
	print("a: jump  b: laser  x: boom  y: coin", 8, 24, 4)
	print("start: music " .. (playing and "on" or "off"), 8, 34, 4)

	if playing then
		local beat = (t // 24) % 4
		for i = 0, 3 do
			rectfill(8 + i * 20, 56, 22 + i * 20, 70, i == beat and 12 or 2)
		end
	end

	if flash > 0 then
		rectfill(8, 84, 120, 100, 9)
	end
	print("last: " .. last, 12, 89, 0)
end
