local Sampler={}

function Sampler:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sampler:init()
  self.samples={}
end

function Sampler:load(path)
  self.samples[path]=sample_:new({path=path})
end

function Sampler:select(path)
  if self.samples[path]==nil then
    self:load(path)
    self.cur=path
  end
end

function Sampler:enc(k,d)
  self.samples[self.cur]:enc(k,d)
end

function Sampler:key(k,z)
  self.samples[self.cur]:key(k,z)
end

function Sampler:redraw()
  if self.cur==nil then
    do return end
  end
  return self.samples[self.cur]:redraw()
end

return Sampler
