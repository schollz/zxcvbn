
function redraw()
  screen.clear()
  screens[screen_ind]:redraw()

  screen.level(5)
  screen.rect(0,0,6,66)
  screen.fill()
  screen.level(params:get(params:get("track").."mute")==1 and 4 or 0)
  screen.move(3,6)
  screen.text_center(params:get("track"))
  for i,v in ipairs(tracks[params:get("track")].scroll) do
    screen.move(3,6+(i*8))
    screen.text_center(v)
  end

  draw_message()
  screen.update()
end
