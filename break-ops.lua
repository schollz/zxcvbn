-- tli
--
--
-- llllllll.co/t/break ops
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

function enc(k,d)
  vterm:enc(k,d)
end

function key(k,z)
  vterm:key(k,z)
end

function redraw()
  screen.clear()
  vterm:redraw()

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
