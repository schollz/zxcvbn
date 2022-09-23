local Track={}

function Track:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Track:init()
  -- initialize parameters
  params:add_option(self.id.."track_type","type",{"sliced sample","melodic sample","midi","crow","engine"},1)
  params:set_action(self.id.."track_type",function(x)
    -- rerun show/hiding
    self:select(self.selected)
  end)
  -- sliced sample
  params:add_file(self.id.."sample_file","file",_path.audio.."break-ops")
  params:set_action(self.id.."sample_file",function(x)
    print("sample_file",x)
    if util.file_exists(x) and string.sub(x,-1)~="/" then
      self:load_sample(x)
    end
  end)
  params:add_number(self.id.."sample_bpm","source bpm",10,200,math.floor(clock.get_tempo()))
  params:add_option(self.id.."play_through","play through",{"until stop","until next slice"},1)

  params:add{type="binary",name="play",id=self.id.."track_play",behavior="toggle",action=function(v)
  end}
  params:add_option(self.id.."track_division","division",possible_division_options,5)

  self.params={shared={"track_type","track_play","track_division"}}
  self.params["sliced sample"]={"sample_file","sample_bpm","play_through"} -- only show if midi is enabled
  self.params["melodic sample"]={"sample_file"} -- only show if midi is enabled

  -- initialize track data
  self.state="vterm"
  self.vterm=vterm_:new()
  self.sample=sample_:new()
end

function Track:select(selected)
  self.selected=selected
  for k,ps in pairs(self.params) do
    for _,p in ipairs(ps) do
      if selected and (k=="shared" or k==params:string(self.id.."track_type")) then
        params:show(self.id..p)
      else
        params:hide(self.id..p)
      end
    end
  end
  debounce_fn["menu"]={
    1,function()
      _menu.rebuild_params()
    end
  }
end

function Track:set_position(pos)
  self.sample:set_position(pos)
end

function Track:load_sample(path)
  self.sample:load_sample(path,params:get(self.id.."track_type")==2)
  self.state="sample"
end

-- base functions

function Track:keyboard(k,v)
  self[self.state]:keyboard(k,v)
end

function Track:enc(k,d)
  self[self.state]:enc(k,d)
end

function Track:key(k,z)
  self[self.state]:key(k,z)
end

function Track:redraw()
  self[self.state]:redraw()
end

return Track
