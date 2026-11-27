-- drive: a mode 7 floor you can drive on
-- up/A: gas, down/B: brake, left/right: steer, L/R: camera height
-- the tiles and the track here are test stuff made in code, not real art

function tile(n, f)
  local ox, oy = (n % 16) * 16, (n // 16) * 16
  for y = 0, 15 do
    for x = 0, 15 do
      local c = f(x, y)
      if c then sset(ox + x, oy + y, c) end
    end
  end
end

GRASS, ROAD, EDGE, FINISH, HILL = 1, 2, 3, 4, 5
KART = 8

function _init()
  tile(GRASS, function(x, y) if (x * 5 + y * 3) % 13 == 0 then return 8 end return 9 end)
  tile(ROAD, function(x, y) if (x * 7 + y * 11) % 17 == 0 then return 3 end return 2 end)
  tile(EDGE, function(x, y) if (x // 4 + y // 4) % 2 == 0 then return 11 end return 5 end)
  tile(FINISH, function(x, y) if (x // 4 + y // 4) % 2 == 0 then return 1 end return 5 end)
  tile(HILL, function(x, y) if y >= math.abs(x - 7.5) * 2 then return 7 end end)
  tile(KART, function(x, y)
    if y < 6 or y > 13 then return nil end
    if (x < 3 or x > 12) and y > 7 then return 1 end
    if x >= 3 and x <= 12 then
      if y == 6 then return 12 end
      return 11
    end
  end)

  -- layer 0: a ring track, 64 x 64 tiles
  mapsize(0, 64, 64)
  for cy = 0, 63 do
    for cx = 0, 63 do
      local d = math.sqrt((cx - 31.5) ^ 2 + (cy - 31.5) ^ 2)
      local t = GRASS
      if d > 15 and d < 23 then t = ROAD end
      if (d > 14 and d <= 15) or (d >= 23 and d < 24) then t = EDGE end
      if t == ROAD and cx == 31 and cy < 32 then t = FINISH end
      mset(0, cx, cy, t)
    end
  end

  -- layer 1: hills on the horizon, one row
  mapsize(1, 16, 14)
  for cx = 0, 15 do
    if cx % 3 ~= 1 then mset(1, cx, 4, HILL) end
  end

  x, y = 31.5 * 16 - 8, 12.5 * 16
  angle = 0.25
  speed = 0
  height = 24
  horizon = 80
end

function _update()
  local on = mget(0, x // 16, y // 16)
  local top = (on == GRASS) and 1.2 or 3

  if btn(2) or btn(4) then speed = speed + 0.06 end
  if btn(3) or btn(5) then speed = speed - 0.1 end
  speed = speed * 0.98
  speed = math.max(-1, math.min(speed, top))

  local turn = 0.004 * math.min(math.abs(speed), 1.5)
  if speed < 0 then turn = -turn end
  if btn(0) then angle = angle + turn end
  if btn(1) then angle = angle - turn end

  if btn(8) then height = math.max(height - 0.5, 4) end
  if btn(9) then height = math.min(height + 0.5, 96) end

  local a = angle * 2 * math.pi
  x = x - math.sin(a) * speed
  y = y - math.cos(a) * speed
end

function _draw()
  cls(4)
  map(1, angle * 256, 0)
  mode7(0, x, y, angle, height, horizon)

  spr(KART, 120, 190)

  print("speed " .. math.floor(speed * 10) .. "  height " .. math.floor(height), 4, 4, 0)
end
