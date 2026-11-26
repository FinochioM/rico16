function _init()
  x, y = 128, 112
  col = 12
end

function _update()
  if btn(0) then x = x - 2 end
  if btn(1) then x = x + 2 end
  if btn(2) then y = y - 2 end
  if btn(3) then y = y + 2 end
  if btnp(4) then col = col % 15 + 1 end
end

function _draw()
  cls(0)
  circfill(x, y, 8, col)
  print("hello from lua!", 4, 4, 5)
  print("x " .. x .. "  y " .. y, 4, 12, 3)
end
