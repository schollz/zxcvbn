local Tracker={}

function Tracker:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Tracker:init()
  self.ctrl_on=false
  self.shift_on=false
  self.alt_on=false
  self.meta_on=false
  self.norns_keyboard=0

  self.codes_keyboard={}
  for i,v in pairs(keyboard.codes) do
    self.codes_keyboard[v]=tonumber(i)
  end
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
  screen.level(5)
  screen.rect(0,8,6,66)
  screen.fill()
  screen.level(params:get(params:get("track").."play")==0 and 5 or 12)
  screen.rect(0,0,6,7)
  screen.fill()
  screen.level(params:get(params:get("track").."play")==0 and 1 or 0)
  screen.move(3,6)
  screen.text_center(params:get("track"))
  screen.level(params:get(params:get("track").."play")==0 and 3 or 0)
  for i,v in ipairs(tracks[params:get("track")].scroll) do
    screen.move(3,6+(i*8))
    screen.text_center(v)
  end
end

return Tracker
