local SequenceSample={}

function SequenceSample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function SequenceSample:init()
  self.cur=1
  self.samples={}
end

function SequenceSample:load(i,path)
  self.samples[i]=sample_:new({id=i,path=path})
end

function SequenceSample:select(i)
  if self.samples[i]~=nil then
    self.cur=i
  end
end

function SequenceSample:enc(k,d)
  self.samples[self.cur]:enc(k,d)
end

function SequenceSample:key(k,z)
  self.samples[self.cur]:key(k,z)
end

function SequenceSample:show_position(pos)
  self.samples[self.cur].show=1
  self.samples[self.cur].show_pos=pos
end

function SequenceSample:redraw()
  if self.cur==nil or self.samples[self.cur]==nil then
    do return end
  end
  return self.samples[self.cur]:redraw()
end

return SequenceSample
