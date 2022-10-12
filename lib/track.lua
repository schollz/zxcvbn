local Track={}

VTERM=1
SAMPLE=2
LOADSCREEN=3

function string.split(pString,pPattern)
  local Table={} -- NOTE: use {n = 0} in Lua-5.0
  local fpat="(.-)"..pPattern
  local last_end=1
  local s,e,cap=pString:find(fpat,1)
  while s do
    if s~=1 or cap~="" then
      table.insert(Table,cap)
    end
    last_end=e+1
    s,e,cap=pString:find(fpat,last_end)
  end
  if last_end<=#pString then
    cap=pString:sub(last_end)
    table.insert(Table,cap)
  end
  return Table
end

function Track:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Track:init()
  -- initialize parameters
  self.track_type_options={"sliced sample","melodic sample","mx.samples","mx.synths","infinite pad","crow 1+2","crow 3+4","midi"}
  params:add_option(self.id.."track_type","type",self.track_type_options,1)
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
  params:add_option(self.id.."play_through","play through",{"until stop","until next slice"},1)
  params:add_number(self.id.."slices","slices",1,16,16)
  params:add_number(self.id.."bpm","bpm",10,600,math.floor(clock.get_tempo()))

  -- midi stuff
  params:add_option(self.id.."midi_dev","midi",midi_device_list,1)
  params:add_number(self.id.."midi_ch","midi ch",1,16,1)

  -- mx.synths stuff
  self.mx_synths={"synthy","casio","icarus","epiano","toshiya","malone","kalimba","mdapiano","polyperc","dreadpiano","aaaaaa","triangles"}
  params:add_option(self.id.."mx_synths","synth",self.mx_synths)
  local params_menu={
    {id="mod1",name="mod 1",min=-1,max=1,exp=false,div=0.01,default=0},
    {id="mod2",name="mod 2",min=-1,max=1,exp=false,div=0.01,default=0},
    {id="mod3",name="mod 3",min=-1,max=1,exp=false,div=0.01,default=0},
    {id="mod4",name="mod 4",min=-1,max=1,exp=false,div=0.01,default=0},
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

  local params_menu={
    {id="source_note",name="source_note",min=1,max=127,exp=false,div=1,default=60,formatter=function(param) return musicutil.note_num_to_name(math.floor(param:get()),true)end},
    {id="db",name="volume (v)",min=-48,max=12,exp=false,div=0.1,default=-6,unit="db"},
    {id="db_sub",name="volume sub",min=-48,max=12,exp=false,div=0.1,default=-6,unit="db"},
    {id="pan",name="pan (w)",min=-1,max=1,exp=false,div=0.01,default=0},
    {id="filter",name="filter note",min=24,max=127,exp=false,div=0.5,default=127,formatter=function(param) return musicutil.note_num_to_name(math.floor(param:get()),true)end},
    {id="probability",name="probability",min=0,max=100,exp=false,div=1,default=100,unit="%"},
    {id="attack",name="attack (k)",min=1,max=10000,exp=false,div=1,default=1,unit="ms"},
    {id="crow_sustain",name="sustain",min=0,max=10,exp=false,div=0.1,default=10,unit="volt"},
    {id="release",name="let-go (l)",min=1,max=10000,exp=false,div=1,default=5,unit="ms"},
    {id="gate",name="gate (h)",min=0,max=100,exp=false,div=1,default=100,unit="%"},
    {id="decimate",name="decimate (m)",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%d%%",util.round(100*param:get())) end},
    {id="drive",name="drive",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%d%%",util.round(100*param:get())) end},
    {id="compression",name="compression",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%d%%",util.round(100*param:get())) end},
    {id="pitch",name="note (n)",min=-24,max=24,exp=false,div=0.1,default=0.0,response=1,formatter=function(param) return string.format("%s%2.1f",param:get()>-0.01 and "+" or "",param:get()) end},
    {id="rate",name="rate (u)",min=-2,max=2,exp=false,div=0.01,default=1.0,response=1,formatter=function(param) return string.format("%s%2.1f",param:get()>-0.01 and "+" or "",param:get()*100) end},
    {id="compressing",name="compressing",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="send_reverb",name="send reverb",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
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

  params:add{type="binary",name="play",id=self.id.."play",behavior="toggle",action=function(v)
    -- reset the clocks if this is the first thing to play
    if v==1 then
      local play_count=0
      for i,_ in ipairs(tracks) do
        play_count=play_count+params:get(i.."play")
      end
      if play_count==1 then
        reset_clocks()
      end
    else
      if params:get(self.id.."track_type")==5 then
        crow.output[2](false)
      elseif params:get(self.id.."track_type")==6 then
        crow.output[4](false)
      end
    end
  end}
  params:add{type="binary",name="mute",id=self.id.."mute",behavior="toggle",action=function(v)
    if v==0 then
      -- TODO if play off, turn off all notes
    end
  end}
  params:add_number(self.id.."mute_group","mute group",1,9,1)

  self.params={shared={"track_type","play","db","probability","pitch","mute","mute_group"}}
  self.params["sliced sample"]={"sample_file","rate","slices","bpm","compression","play_through","gate","filter","decimate","drive","pan","compressing","compressible","attack","release","send_reverb"}
  self.params["melodic sample"]={"sample_file","attack","release","filter","pan","source_note","compressing","compressible"}
  self.params["infinite pad"]={"attack","filter","pan","release","compressing","compressible","send_reverb"}
  self.params["mx.samples"]={"db","attack","pan","release","compressing","compressible","send_reverb"}
  self.params["crow 1+2"]={"attack","release","crow_sustain"}
  self.params["crow 3+4"]={"attack","release","crow_sustain"}
  self.params["midi"]={"midi_ch","midi_dev"}
  self.params["mx.synths"]={"db","db_sub","attack","pan","release","compressing","compressible","mx_synths","mod1","mod2","mod3","mod4","db_sub","send_reverb"}

  -- define the shortcodes here
  self.mods={
    i=function(x) params:set(self.id.."filter",x+30) end,
    q=function(x) params:set(self.id.."probability",x) end,
    h=function(x) params:set(self.id.."gate",x) end,
    k=function(x) params:set(self.id.."attack",x) end,
    l=function(x) params:set(self.id.."release",x) end,
    w=function(x) params:set(self.id.."pan",(x/100)) end,
    m=function(x) params:set(self.id.."decimate",x/100) end,
    n=function(x) params:set(self.id.."pitch",x) end,
    u=function(x) params:set(self.id.."rate",x/100) end,
    z=function(x) params:set(self.id.."send_reverb",x/100) end,
  }

  -- initialize track data
  self.state=VTERM
  self.states={}
  table.insert(self.states,vterm_:new{id=self.id,on_save=function(x)
    local success=self:parse_tli()
    return success
  end})
  table.insert(self.states,sample_:new{id=self.id})
  table.insert(self.states,viewselect_:new{id=self.id})

  -- keep track of notes
  self.midi_notes={}

  self.scroll={"","","","","","",""}

  -- add playback functions for each kind of engine
  self.play_fn={}
  -- spliced sample
  table.insert(self.play_fn,{
    note_on=function(d)
      if d.m==nil then
        do return end
      end
      local id=self.id.."_"..d.m
      self.states[SAMPLE]:play{
        on=true,
        id=id,
        ci=(d.m-1)%16+1,
        db=d.mods.v or 0,
        pan=params:get(self.id.."pan"),
        duration=d.duration_scaled,
        rate=clock.get_tempo()/params:get(self.id.."bpm")*params:get(self.id.."rate"),
        watch=(params:get("track")==self.id and self.state==SAMPLE) and 1 or 0,
        retrig=d.mods.x or 0,
        pitch=params:get(self.id.."pitch"),
        gate=params:get(self.id.."gate")/100,
      }
    end,
  })
  -- melodic sample
  table.insert(self.play_fn,{
    note_on=function(d)
      if d.m==nil then
        do return end
      end
      local id=self.id.."_"..d.m
      self.states[SAMPLE]:play{
        on=true,
        id=id,
        db=d.mods.v or 0,
        pitch=d.m-params:get(self.id.."source_note")+params:get(self.id.."pitch"),
        duration=d.duration_scaled,
        retrig=d.mods.x or 0,
        watch=(params:get("track")==self.id and self.state==SAMPLE) and 1 or 0,
        gate=params:get(self.id.."gate")/100,
      }
    end,
  })
  -- mx.samples
  table.insert(self.play_fn,{
    note_on=function(d)
      local folder=_path.audio.."mx.samples/string_spurs" -- TODO: choose from option
      local note=d.m+params:get(self.id.."pitch")
      local velocity=util.clamp(util.linlin(-48,12,0,127,params:get(self.id.."db"))+(d.mods.v or 0),1,127)
      local amp=util.dbamp(params:get(self.id.."db"))
      local pan=params:get(self.id.."pan")
      local attack=params:get(self.id.."attack")/1000
      local release=params:get(self.id.."release")/1000
      local sub=params:get(self.id.."db_sub")
      local mods={}
      for i=1,4 do
        table.insert(mods,params:get(self.id.."mod"..i))
      end
      local duration=d.duration_scaled
      local sendCompressible=0
      local sendCompressing=0
      local sendReverb=0.0
      engine.mx(folder,note,velocity,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb)
    end,
  })
  -- mx.synths
  table.insert(self.play_fn,{
    note_on=function(d)
      local synth=params:string(self.id.."mx_synths")
      local note=d.m+params:get(self.id.."pitch")
      local db=params:get(self.id.."db")+(d.mods.v or 0)
      local pan=params:get(self.id.."pan")
      local attack=params:get(self.id.."attack")/1000
      local release=params:get(self.id.."release")/1000
      local duration=d.duration_scaled
      engine.mx_synths(synth,note,db,params:get(self.id.."db_sub"),pan,attack,release,
        params:get(self.id.."mod1"),params:get(self.id.."mod2"),params:get(self.id.."mod3"),params:get(self.id.."mod4"),
      duration,params:get(self.id.."compressible"),params:get(self.id.."compressing"),params:get(self.id.."send_reverb"))
    end,
  })
  -- infinite pad
  table.insert(self.play_fn,{
    note_on=function(d)
      local note=d.m+params:get(self.id.."pitch")
      engine.note_on(note,
        params:get(self.id.."db")+util.clamp((d.mods.v or 0)/10,0,10),
        params:get(self.id.."attack")/1000,
        params:get(self.id.."release")/1000,
      d.duration_scaled)
    end,
  })
  -- crow 1+2 & 3+4
  for ii=1,2 do
    local i=ii==1 and 1 or 3
    table.insert(self.play_fn,{
      note_on=function(d)
        local level=util.linlin(-48,12,0,10,params:get(self.id.."db")+(d.mods.v or 0))
        local note=d.m+params:get(self.id.."pitch")
        if level>0 then
          -- local crow_asl=string.format("adsr(%3.3f,0,%3.3f,%3.3f,'linear')",params:get(self.id.."attack")/1000,level,params:get(self.id.."release")/1000)
          local crow_asl=string.format("{to(%3.3f,%3.3f), to(%3.3f,%3.3f), to(0,%3.3f)}",level,params:get(self.id.."attack")/1000,level,d.duration_scaled,params:get(self.id.."release")/1000)
          print(i+1,crow_asl)
          crow.output[i+1].action=crow_asl
          crow.output[i].volts=(note-24)/12
          crow.output[i+1]()
        end
        if d.mods.x~=nil and d.mods.x>0 then
          clock.run(function()
            for i=1,d.mods.x do
              clock.sleep(d.duration_scaled/(d.mods.x+1))
              crow.output[i+1](false)
              level=util.linlin(-48,12,0,10,params:get(self.id.."db")+(d.mods.v or 0)*(i+1))
              note=d.m+params:get(self.id.."pitch")*(i+1)
              if level>0 then
                crow.output[i].volts=(note-24)/12
                crow.output[i+1]()
              end
            end
          end)
        end
      end,
    })
  end

  -- midi device
  table.insert(self.play_fn,{
    note_on=function(d)
      local vel=util.linlin(-48,12,0,127,params:get(self.id.."db")+(d.mods.v or 0))
      local note=d.m+params:get(self.id.."pitch")
      if vel>0 then
        midi_device[params:get(self.id.."midi_dev")].note_on(note,vel,params:get(self.id.."midi_ch"))
        self.midi_notes[note]={device=params:get(self.id.."midi_dev"),duration=v.duration}
      end
      if d.mods.x~=nil and d.mods.x>0 then
        clock.run(function()
          for i=1,d.mods.x do
            clock.sleep(d.duration_scaled/(d.mods.x+1))
            midi_device[params:get(self.id.."midi_dev")].note_off(note,0,params:get(self.id.."midi_ch"))
            vel=util.linlin(-48,12,0,127,params:get(self.id.."db")+(d.mods.v or 0)*(i+1))
            note=d.m+params:get(self.id.."pitch")*(i+1)
            if vel>0 then
              midi_device[params:get(self.id.."midi_dev")].note_on(d.m,vel,params:get(self.id.."midi_ch"))
              self.midi_notes[note]={device=params:get(self.id.."midi_dev"),duration=v.duration}
            end
          end
        end)
      end
    end,
  })

end

function Track:dumps()
  local data={states={}}
  for i,v in ipairs(self.states) do
    if i==SAMPLE or i==VTERM then
      data.states[i]=v:dumps()
    end
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
    if i==SAMPLE or i==VTERM then
      if v~="{}" then
        print("track: loads",i,v)
        self.states[i]:loads(v)
      end
    end
  end
  self.state=data.state
end

function Track:load_text(text)
  self.states[VTERM]:load_text(text)
  self:parse_tli()
end

function Track:parse_tli()
  local text=self.states[VTERM]:get_text()
  local tli_parsed=nil
  tli_parsed,err=tli:parse_tli(text,params:get(self.id.."track_type")==1)
  if err~=nil then
    print("error: "..err)
    local foo=string.split(err,":")
    show_message(foo[#foo])
    do return end
  end
  self.tli=tli_parsed
  self.track={}
  if self.id==4 then
    print(i,json.encode(tli_parsed.track))
  end
  for i,v in ipairs(tli_parsed.track) do
    if self.track[v.start]==nil then
      self.track[v.start]={}
    end
    table.insert(self.track[v.start],v)
    if self.id==4 then
      print(i,json.encode(v))
    end
  end
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
  -- add flag to turn off on notes
  self.flag_parsed=true
  return true
end

function Track:emit(beat)
  -- turn off any midi notes
  if next(self.midi_notes)~=nil then
    local to_remove={}
    for note,v in pairs(self.midi_notes) do
      v.duration=v.duration-1
      if v.duration==0 then
        -- note off
        midi_device[v.device].note_off(note,0,params:get(self.id.."midi_ch"))
        table.insert(to_remove,note)
      end
    end
    for _,note in ipairs(to_remove) do
      self.midi_notes[note]=nil
    end
  end
  if params:get(self.id.."play")==0 or params:get(self.id.."mute")==1 then
    do return end
  end
  if self.tli~=nil and self.track~=nil and self.tli.pulses>0 then
    local i=(beat-1)%self.tli.pulses+1
    local t=self.track[i]
    if t==nil then
      do return end
    end
    print("beati",beat,i,self.tli.pulses,json.encode(t))
    for k,d in ipairs(t) do
      print(k,json.encode(d))
      if d.mods~=nil then
        for k,v in pairs(d.mods) do
          if self.mods[k]~=nil then
            self.mods[k](tli.numdashcomr(v))
          end
        end
      end
      if self.flag_parsed then
        self.flag_parsed=nil
      end
      d.duration_scaled=d.duration*(clock.get_beat_sec()/24)
      --print("d.duration_scaled",d.duration_scaled,"d.duration",d.duration)
      if d.m~=nil then
        self:scroll_add(params:get(self.id.."track_type")==1 and d.m or string.lower(musicutil.note_num_to_name(d.m)))
      end
      if math.random(0,100)<=params:get(self.id.."probability") then
        self.play_fn[params:get(self.id.."track_type")].note_on(d)
      end
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

function Track:scroll_add(m)
  for i=1,6 do
    self.scroll[i]=self.scroll[i+1]
  end
  self.scroll[7]=m
end

function Track:set_position(pos)
  self.states[SAMPLE]:set_position(pos)
end

function Track:load_sample(path)
  print(string.format("track %d: load sample %s",self.id,path))
  self.states[SAMPLE]:load_sample(path,params:get(self.id.."track_type")==2,params:get(self.id.."slices"))
end

-- base functions

function Track:keyboard(k,v)
  if k=="TAB" then
    if v==1 and params:get(self.id.."track_type")<3 then
      self.state=3-self.state
    end
    do return end
  elseif k=="CTRL+O" then
    if v==1 then
      if self.state==LOADSCREEN then
        self.state=SAMPLE
      else
        self.state=LOADSCREEN
      end
    end
    do return end
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
