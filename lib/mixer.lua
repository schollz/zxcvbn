local Mixer={}

function Mixer:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Mixer:init()
  self.minus={"Q","W","E","R","T","Y","U","I","O","P"}
  self.edited={0,0,0,0,0,0,0,0,0,0}
  self.levels={}
  for i=1,10 do
    self.levels[i]={-48.-48}
  end
end

function Mixer:set_levels(levels)
  local j=1
  for i=1,10 do
    if levels[j]~=nil and levels[j+1]~=nil then
      self.levels[i]={levels[j],levels[j+1]}
    end
    j=j+2
  end
end

function Mixer:keyboard(k,v)
  for i=1,10 do
    if tonumber(k)==i then
      params:delta(i..params:string("mixer_param"),v*params:get("mixer_factor"))
      self.edited[i]=15
    elseif self.minus[i]==k then
      params:delta(i..params:string("mixer_param"),-1*v*params:get("mixer_factor"))
      self.edited[i]=15
    end
  end
end

function Mixer:enc(k,d)
  if k==2 then
    params:delta("mixer_param",d)
  elseif k==3 then
    params:delta("mixer_factor",d)
  end
end

function Mixer:key(k,z)
end

function Mixer:redraw()
  screen.level(5)
  screen.rect(8,0,128,7)
  screen.fill()
  screen.level(0)
  screen.move(9,6)
  screen.text(string.format("%s x%d",params:string("mixer_param"),params:get("mixer_factor")))

  screen.level(5)
  screen.rect(0,8,6,66)
  screen.fill()
  screen.level(5)
  screen.rect(0,0,7,7)
  screen.fill()
  screen.level(0)
  screen.move(3,6)
  screen.text_center("m")

  local spacing=12
  local x_offset=9
  local show_val=false
  for i=1,10 do
    screen.move(x_offset+2+(i-1)*spacing,64)
    if self.edited[i]>0 then
      self.edited[i]=self.edited[i]-1
      screen.level(self.edited[i])
      screen.text_center(params:string(i..params:string("mixer_param")))
      show_val=true
    end
  end
  for i=1,10 do
    screen.level(9)
    local y=(1-params:get_raw(i..params:string("mixer_param")))*48+9
    screen.rect(x_offset+(i-1)*spacing,y,2,64-y-7)
    screen.fill()
    screen.level(3)
    if self.levels[i][1]~=nil then
      y=(1-util.linlin(-48,12,0,1,self.levels[i][1]))*48+9
      screen.rect(x_offset+3+(i-1)*spacing,y,2,64-y-7)
      screen.fill()
    end
    if self.levels[i][2]~=nil then
      y=(1-util.linlin(-48,12,0,1,self.levels[i][2]))*48+9
      screen.rect(x_offset+6+(i-1)*spacing,y,2,64-y-7)
      screen.fill()
    end
    if not show_val then
      screen.level(params:get("track")==i and 9 or 3)
      screen.move(x_offset+1+(i-1)*spacing,64)
      screen.text_center(i)
    end
  end
end

return Mixer
