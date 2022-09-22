local Track={}

function Track:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Track:init()
  params:add_file(self.id.."sample_file","file",_path.audio.."break-ops")
  params:set_action(self.id.."sample_file",function(x)
    if util.file_exists(x) and string.sub(x,-1)~="/" then
      self:load_sample(x)
    end
  end)
  params:add{type="binary",name="play",id=self.id.."sample_play",behavior="toggle",action=function(v)
  end}
  params:add_option(self.id.."sample_division","division",possible_division_options,5)

  self.params={}
  self.params.share={"",""}
  self.params.midi={"",""} -- only show if midi is enabled
end

return Track
