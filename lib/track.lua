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
  params:add_option(self.id.."track_type","type",{"sliced sample","melodic sample","midi","crow","engine"},1)
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

  self.params={shared={"ppq","track_type","track_play"}}
  self.params["sliced sample"]={"sample_file","bpm","play_through"} -- only show if midi is enabled
  self.params["melodic sample"]={"sample_file"} -- only show if midi is enabled

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
  if ppq~=params:get(self.id.."ppq") then
    do return end
  end
  if self.id==1 then
    print(beat,ppq)
    if self.tli~=nil and self.tli.track~=nil then
      local i=(beat-1)%#self.tli.track+1
      local t=self.tli.track[i]
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
  d.v=d.v or 60
  if params:get(self.id.."track_type")==1 and do.on then
    -- only triggers on note, uses duration to figure out how long
    self.states[SAMPLE]:play{
      on=d.on,
      id=self.id.."_"..d.m,
      ci=d.m,
      duration=d.duration*(clock.get_beat_sec()/params:get(self.id.."ppq")),
      rate=clock.get_tempo()/params:get(self.id.."bpm"),
      watch=(params:get("track")==self.id and self.state==SAMPLE) and 1 or 0,
      retrig=d.r or 0,
      gate=d.q/100 or 0,
    }
  end
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
