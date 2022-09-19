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
  for i=1,4 do
    table.insert(self.samples,sample_:new{id=i})
  end
end

function SequenceSample:select(i)
  if next(self.samples[i])~=nil then
    self.cur=i
  end
end

function SequenceSample:emit(division,beat)
  for _,s in ipairs(self.samples) do
    s:emit(division,beat)
  end
end

function SequenceSample:get_sample()
  return self.samples[self.cur]
end

function SequenceSample:get_seq()
  return self.samples[self.cur]:get_seq()
end

function SequenceSample:set_focus(i,rec)
  self.samples[self.cur].focus=i
  self.samples[self.cur].record[i]=self.samples[self.cur].record[i]+(rec and 1 or-1)
end

function SequenceSample:set_start_stop(start,stop)
  self.samples[self.cur].seq[self.samples[self.cur].ordering[self.samples[self.cur].focus]].start=start
  self.samples[self.cur].seq[self.samples[self.cur].ordering[self.samples[self.cur].focus]].start=stop
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
  if self.cur==nil or next(self.samples[self.cur])==nil then
    do return end
  end
  return self.samples[self.cur]:redraw()
end

return SequenceSample
