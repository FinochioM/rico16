-- hello: a ball bounces around. push it with the d-pad, A changes its color

function _init()
  x, y = 128, 112
  dx, dy = 1.5, 1
  col = 12
end

function _update()
  if btn(0) then dx = dx - 0.1 end
  if btn(1) then dx = dx + 0.1 end
  if btn(2) then dy = dy - 0.1 end
  if btn(3) then dy = dy + 0.1 end
  if btnp(4) then col = col % 15 + 1 end

  x = x + dx
  y = y + dy
  if x < 8 then dx = math.abs(dx) end
  if x > 247 then dx = -math.abs(dx) end
  if y < 8 then dy = math.abs(dy) end
  if y > 215 then dy = -math.abs(dy) end
end

function _draw()
  cls(0)
  circfill(x, y, 8, col)
  print("hello from lua!", 4, 4, 5)
end
