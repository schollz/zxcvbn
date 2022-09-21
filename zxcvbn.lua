-- zxcvbn
--
--
-- llllllll.co/t/zxcvbn
--
--
--
--    ▼ instructions below ▼

vterm_=include("lib/vterm")

function init()
  vterm=vterm_:new()
  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
end

function keyboard.code(k,v)
  vterm:keyboard(k,v)
end

function enc(k,d)
  vterm:enc(k,d)
end

function key(k,z)
  vterm:key(k,z)
end

function show_message(message,seconds)
  seconds=seconds or 2
  show_message_clock=10*seconds
  show_message_text=message
end

function draw_message()
  if show_message_clock~=nil and show_message_text~=nil and show_message_clock>0 and show_message_text~="" then
    show_message_clock=show_message_clock-1
    screen.blend_mode(0)
    local x=64
    local y=28
    local w=screen.text_extents(show_message_text)+8
    screen.rect(x-w/2,y,w,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    screen.update()
    screen.blend_mode(13)
    screen.rect(x-w/2,y,w,9)
    screen.level(10)
    screen.fill()
    screen.blend_mode(0)
    screen.level(0)
    screen.rect(x-w/2,y,w,10)
    screen.stroke()
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
  end
end

function redraw()
  screen.clear()
  vterm:redraw()

  screen.level(7)
  screen.rect(122,0,8,66)
  screen.fill()
  screen.level(0)
  screen.move(125,8)
  screen.text_center("8")

  draw_message()

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
