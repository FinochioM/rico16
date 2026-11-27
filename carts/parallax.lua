-- parallax: 3 map layers scrolling at different speeds
-- left/right: scroll, hold A: faster
-- the tiles here are test tiles made with sset, not real art

function tile(n, f)
  local ox, oy = (n % 16) * 16, (n // 16) * 16
  for y = 0, 15 do
    for x = 0, 15 do
      local c = f(x, y)
      if c then sset(ox + x, oy + y, c) end
    end
  end
end

function _init()
  -- far: mountains
  tile(1, function() return 6 end)
  tile(2, function(x, y) if y >= math.abs(x - 7.5) * 2 then return 6 end end)
  -- middle: hills
  tile(3, function() return 7 end)
  tile(4, function(x, y) if (x - 7.5) ^ 2 + (y - 16) ^ 2 < 100 then return 7 end end)
  -- near: ground and blocks
  tile(5, function(x, y) if (x * 7 + y * 3) % 11 == 0 then return 14 end return 13 end)
  tile(6, function(x, y) if y < 4 then return 9 elseif y == 4 then return 8 end return 13 end)
  tile(7, function(x, y) if x == 0 or y == 0 or x == 15 or y == 15 then return 2 end return 3 end)

  mapsize(0, 8, 14)
  for x = 0, 7 do
    if x % 2 == 0 then mset(0, x, 8, 2) end
    for y = 9, 13 do mset(0, x, y, 1) end
  end

  mapsize(1, 9, 14)
  for x = 0, 8 do
    if x % 3 == 0 then mset(1, x, 10, 4) end
    for y = 11, 13 do mset(1, x, y, 3) end
  end

  mapsize(2, 32, 14)
  for x = 0, 31 do
    mset(2, x, 12, 6)
    mset(2, x, 13, 5)
  end
  for x = 5, 7 do mset(2, x, 9, 7) end
  mset(2, 14, 10, 7)
  mset(2, 14, 11, 7)
  for x = 22, 25 do mset(2, x, 8, 7) end
  mset(2, 27, 11, 7)

  cx = 0
end

function _update()
  local speed = btn(4) and 6 or 2
  if btn(0) then cx = cx - speed end
  if btn(1) then cx = cx + speed end
end

function _draw()
  cls(4)

  camera()
  map(0, -cx // 4, 0)
  map(1, -cx // 2, 0)

  camera(cx, 0)
  map(2)

  camera()
  print("3 layers: far 1/4, middle 1/2, near 1/1", 4, 4, 0)
  print("x " .. cx, 4, 12, 0)
end
