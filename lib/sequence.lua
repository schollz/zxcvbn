local Sequence={}

function Sequence:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sequence:init()
    -- fx
    local zero_to_one={}
    local one_to_zero={}
    local one_to_sixteen={}
    for i=0,15 do 
        table.insert(zero_to_one,i/15)
        table.insert(one_to_sixteen,i+1)
        table.insert(one_to_zero,1-i/15)
    end
    self.fx_options={
        db={-96,-72,-64,-48,-24,-20,-16,-8,-6,-4,-2,0,2,4,6,8},
        decimate=zero_to_one,
        filter=one_to_zero,
        retrig=one_to_sixteen,
        stretch=zero_to_one,
        gate=zero_to_one,
        pitch={-8,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,8,10}
        other=one_to_sixteen,
    }
    self.fx_default={
        db=12,
        filter=1,
        retrig=1,
        gate=1,
        pitch=8,
        decimate=1,
        stretch=1,
        other=1,
    }
    self.fx={}
    for k,v in pairs(self.fx_default) do 
        self.fx[k]=v
    end
    self.fx_order={"db","filter","retrig","gate","pitch","decimate","stretch","other"}
end

function Sequence:emit()

end

return Sequence