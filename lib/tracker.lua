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

end

return Tracker
