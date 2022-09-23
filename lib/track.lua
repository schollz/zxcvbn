local Track={}

VTERM=1
SAMPLE=2

function Track:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Track:init()
  -- initialize parameters
  params:add_option(self.id.."track_type","type",{"sliced sample","melodic sample","infinite pad","midi","crow"},1)
  params:set_action(self.id.."track_type",function(x)
    -- rerun show/hiding
    self:select(self.selected)
  end)
  params:add_number(self.id.."ppq","ppq",1,8,4)
  -- sliced sample
  params:add_file(self.id.."sample_file","file",_path.audio.."break-ops")
  params:set_action(self.id.."sample_file",function(x)
    print("sample_file",x)
    if util.file_exists(x) and string.sub(x,-1)~="/" then
      self:load_sample(x)
    end
  end)
  params:add_number(self.id.."bpm","bpm",10,200,math.floor(clock.get_tempo()))
  params:add_option(self.id.."play_through","play through",{"until stop","until next slice"},1)

  params:add{type="binary",name="play",id=self.id.."track_play",behavior="toggle",action=function(v)
  end}


  local params_menu={
    {id="db",name="amp",min=-96,max=12,exp=false,div=1,default=0,unit="db"},
    {id="filter",name="filter",min=24,max=127,exp=false,div=0.5,default=127}, -- TODO: formatter for notes
    {id="probability",name="probability",min=0,max=100,exp=false,div=1,default=100,unit="%"},
    {id="attack",name="attack",min=1,max=10000,exp=false,div=1,default=1,unit="ms"},
    {id="release",name="release",min=1,max=10000,exp=false,div=1,default=5,unit="ms"},
    -- {id="send_main",name="main send",min=0,max=1,exp=false,div=0.01,default=1.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
  }
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=self.id..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
  end
  self.mods={
    v=function(x) params:set(self.id.."db",util.linlin(0,100,-96,12)) end,
    i=function(x) params:set(self.id.."filter",x+30) end,
    o=function(x) params:set(self.id.."probability") end,
  }
  

  self.params={shared={"ppq","track_type","track_play","db","filter","probability"}}
  self.params["sliced sample"]={"sample_file","bpm","play_through"} -- only show if midi is enabled
  self.params["melodic sample"]={"sample_file","attack","release"} -- only show if midi is enabled
  self.params["infinite pad"]={"attack","release"}

  -- initialize track data
  self.state=VTERM
  self.states={}
  table.insert(self.states,vterm_:new{id=self.id,on_save=function(x)
    self:parse_tli()
  end})
  table.insert(self.states,sample_:new{id=self.id})

end

function Track:dumps()
  local data={states={}}
  for i,v in ipairs(self.states) do
    data.states[i]=v:dumps()
  end
  data.state=self.state
  return json.encode(data)
end

function Track:loads(s)
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  for i,v in ipairs(data.states) do
    self.states[i]=self.states[i]:loads(v)
  end
  self.state=data.state
end

function Track:load_text(text)
  self.states[VTERM]:load_text(text)
end

function Track:parse_tli()
  local text=self.states[VTERM]:get_text()
  local tli_parsed=nil
  local ok,err=pcall(function()
    tli_parsed=tli:parse_tli(text,params:get(self.id.."track_type")==1)
  end)
  if not ok then
    show_message("error parsing",2)
    do return end
  end
  self.tli=tli_parsed
  tab.print(self.tli.meta)
  -- update the meta
  if self.tli.meta~=nil then
    for k,v in pairs(self.tli.meta) do
      if params.lookup[self.id..k]~=nil then
        local ok,err=pcall(function()
          print("setting "..k.." = "..v)
          params:set(self.id..k,v)
        end)
        if not ok then
          show_message("error setting "..k)
        end
      end
    end
    show_message("parsed",1)
  end
end

function Track:emit(beat,ppq)
  if params:get(self.id.."play")==0 or ppq~=params:get(self.id.."ppq") then
    do return end
  end
  if self.id==1 then
    print(beat,ppq)
    if self.tli~=nil and self.tli.track~=nil then
      local i=(beat-1)%#self.tli.track+1
      local t=self.tli.track[i]
      for k,v in pairs(t.mods) do 
        if self.mods[k]~=nil then 
          self.mods[k](v)
        end
      end
      for _,d in ipairs(t.off) do
        d.on=false
        self:play(d)
      end
      for _,d in ipairs(t.on) do
        d.on=true
        self:play(d)
      end
    end
  end
end

function Track:play(d)
  -- d={m=4,v=60}
  if d.m==nil then
    do return end
  end
  if params:get(self.id.."track_type")==1 and do.on then
    -- only triggers on note, uses duration to figure out how long
    self.states[SAMPLE]:play{
      on=d.on,
      id=self.id.."_"..d.m,
      ci=d.m,
      db=params:get(self.id.."db"),
      duration=d.duration*(clock.get_beat_sec()/params:get(self.id.."ppq")),
      rate=clock.get_tempo()/params:get(self.id.."bpm"),
      watch=(params:get("track")==self.id and self.state==SAMPLE) and 1 or 0,
      retrig=d.mods.r or 0,
      gate=d.q/100 or 0,
    }
  elseif params:string(self.id.."track_type")=="infinite pad" then 
    if d.on then 
      engine.note_on(d.m,params:get(self.id.."attack")/1000,params:get(self.id.."release")/1000))
    else
      engine.note_off(d.m)
    end
  end
end

function Track:select(selected)
  self.selected=selected
  -- first hide parameters
  for k,ps in pairs(self.params) do
    for _,p in ipairs(ps) do
      if selected and (k=="shared" or k==params:string(self.id.."track_type")) then
      else
        params:hide(self.id..p)
      end
    end
  end
  -- then show them (so that some things can share the same parameters)
  for k,ps in pairs(self.params) do
    for _,p in ipairs(ps) do
      if selected and (k=="shared" or k==params:string(self.id.."track_type")) then
        params:show(self.id..p)
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
  self.states[SAMPLE]:set_position(pos)
end

function Track:load_sample(path)
  -- self.state=SAMPLE
  self.states[SAMPLE]:load_sample(path,params:get(self.id.."track_type")==2)
end

-- base functions

function Track:keyboard(k,v)
  if k=="TAB" then
    if v==1 and params:get(self.id.."track_type")<3 then
      self.state=3-self.state
    end
  end
  self.states[self.state]:keyboard(k,v)
end

function Track:enc(k,d)
  self.states[self.state]:enc(k,d)
end

function Track:key(k,z)
  self.states[self.state]:key(k,z)
end

function Track:redraw()
  self.states[self.state]:redraw()
end

return Track
