local Track={}

function Track:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Track:init()
    self.cur=1
    self.seq={}
    for i=1,8 do 
        table.insert(self.seq,sequence:new())
    end    
end


return Track