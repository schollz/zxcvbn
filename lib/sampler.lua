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
    end
end

function Sampler:redraw()
    if self.selected==nil then 
        do return end 
    end
    self.samples[self.cur]:redraw()
end

return Sampler