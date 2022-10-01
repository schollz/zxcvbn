local Tracker={}

function Tracker:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Tracker:init()

end

function Tracker:keyboard(k,v)
    tracks[params:get("track")]:keyboard(k,v)
end

function Tracker:enc(k,d)
    tracks[params:get("track")]:enc(k,d)
end

function Tracker:key(k,z)
    tracks[params:get("track")]:key(k,z)
end

function Tracker:redraw()
    tracks[params:get("track")]:redraw()

    screen.level(7)
    screen.rect(0,0,6,66)
    screen.fill()
    screen.level(0)
    screen.move(3,6)
    screen.text_center(params:get("track"))
    for i,v in ipairs(tracks[params:get("track")].scroll) do
      screen.move(3,6+(i*8))
      screen.text_center(v)
    end
  
end

return Tracker
