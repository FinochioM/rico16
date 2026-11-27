-- spin: sprite 0 from spin.png turns and grows
-- left/right: turn speed, up/down: size
-- A: sprite palette 0 or 1 (palette 1 comes from spin.pal.png)
-- B: shift the colors with pal()

function _init()
  a = 0
  speed = 0.005
  size = 3
  p = 0
  shift = 0
end

function _update()
  if btn(0) then speed = speed - 0.0005 end
  if btn(1) then speed = speed + 0.0005 end
  if btn(2) then size = math.min(size + 0.05, 8) end
  if btn(3) then size = math.max(size - 0.05, 0.25) end
  if btnp(4) then
    p = 1 - p
    sprpal(0, p)
  end
  if btnp(5) then shift = (shift + 1) % 15 end
  a = a + speed
end

function _draw()
  cls(1)

  for c = 1, 15 do
    pal(c, (c - 1 + shift) % 15 + 1)
  end

  local s = size * (1 + 0.15 * math.sin(a * 20))
  sprx(0, 128, 120, a, s)
  spr(0, 8, 20)
  spr(0, 28, 20, true)
  spr(0, 48, 20, false, true)
  pal()

  print("palette " .. p .. "  shift " .. shift .. "  speed " .. speed, 4, 4, 5)
  print("spr, flip x, flip y", 8, 40, 3)
end
