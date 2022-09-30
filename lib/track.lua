local Track={}

VTERM=1
SAMPLE=2

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
  self.track_type_options={"sliced sample","melodic sample","infinite pad","crow 1+2","crow 3+4","midi"}
  params:add_option(self.id.."track_type","type",self.track_type_options,1)
  params:set_action(self.id.."track_type",function(x)
    -- rerun show/hiding
    self:select(self.selected)
  end)

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
    end
  end}
  params:add{type="binary",name="mute",id=self.id.."mute",behavior="toggle",action=function(v)
    if v==0 then
      -- TODO if play off, turn off all notes
    end
  end}
  params:add_number(self.id.."mute_group","mute group",1,9,1)

  params:add_number(self.id.."ppq","ppq",1,8,4)

  -- midi stuff
  params:add_option(self.id.."midi_dev","midi",midi_device_list,1)
  params:add_number(self.id.."midi_ch","midi ch",1,16,1)

  -- sliced sample
  params:add_file(self.id.."sample_file","file",_path.audio.."break-ops")
  params:set_action(self.id.."sample_file",function(x)
    print("sample_file",x)
    if util.file_exists(x) and string.sub(x,-1)~="/" then
      self:load_sample(x)
    end
  end)
  params:add_number(self.id.."slices","slices",1,16,16)
  params:add_number(self.id.."bpm","bpm",10,600,math.floor(clock.get_tempo()))
  params:add_option(self.id.."play_through","play through",{"until stop","until next slice"},1)

  local params_menu={
    {id="source_note",name="source_note",min=1,max=127,exp=false,div=1,default=60,formatter=function(param) return musicutil.note_num_to_name(param:get(),true)end},
    {id="db",name="volume",min=-48,max=12,exp=false,div=0.1,default=-6,unit="db"},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.01,default=0},
    {id="filter",name="filter note",min=24,max=127,exp=false,div=0.5,default=127,formatter=function(param) return musicutil.note_num_to_name(param:get(),true)end},
    {id="probability",name="probability",min=0,max=100,exp=false,div=1,default=100,unit="%"},
    {id="attack",name="attack",min=1,max=10000,exp=false,div=1,default=1,unit="ms"},
    {id="crow_sustain",name="sustain",min=0,max=10,exp=false,div=0.1,default=10,unit="volt"},
    {id="release",name="release",min=1,max=10000,exp=false,div=1,default=5,unit="ms"},
    {id="gate",name="gate",min=0,max=100,exp=false,div=1,default=100,unit="%"},
    {id="compressing",name="compressing",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="decimate",name="decimate",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%d%%",util.round(100*param:get())) end},
    {id="pitch",name="pitch",min=-24,max=24,exp=false,div=0.1,default=0.0,response=1,formatter=function(param) return string.format("%s%2.1f",param:get()>-0.01 and "+" or "",param:get()) end},
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
    params:set_action(self.id..pram.id,function(v)
      if params:get(self.id.."track_type")==3 and string.find(pram.id,"compress") then
        engine.padfx_set(pram.id,v)
      end
    end)
  end
  self.params={shared={"ppq","track_type","play","db","probability","pitch","mute","mute_group"}}
  self.params["sliced sample"]={"sample_file","slices","bpm","play_through","gate","filter","decimate","pan","compressing","compressible"} -- only show if midi is enabled
  self.params["melodic sample"]={"sample_file","attack","release","filter","pan","source_note","compressing","compressible"} -- only show if midi is enabled
  self.params["infinite pad"]={"attack","filter","pan","release","compressing","compressible"}
  self.params["crow 1+2"]={"attack","release","crow_sustain"}
  self.params["crow 3+4"]={"attack","release","crow_sustain"}
  self.params["midi"]={"midi_ch","midi_dev"}

  -- define the shortcodes here
  self.mods={
    i=function(x) params:set(self.id.."filter",x+30) end,
    q=function(x) params:set(self.id.."probability",x) end,
    h=function(x) params:set(self.id.."gate",x) end,
    k=function(x) params:set(self.id.."attack",x) end,
    l=function(x) params:set(self.id.."release",x) end,
    p=function(x) params:set(self.id.."pan",(x/100)*2-1) end,
    m=function(x) params:set(self.id.."decimate",x/100) end,
    n=function(x) params:set(self.id.."pitch",x) end,
  }

  -- initialize track data
  self.state=VTERM
  self.states={}
  table.insert(self.states,vterm_:new{id=self.id,on_save=function(x)
    local success=self:parse_tli()
    return success
  end})
  table.insert(self.states,sample_:new{id=self.id})

  -- keep track of notes
  self.notes_on={}
  for i=1,#self.track_type_options do
    table.insert(self.notes_on,{})
  end

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
      self.notes_on[1][d.m]=true
      self.states[SAMPLE]:play{
        on=true,
        id=id,
        ci=(d.m-1)%16+1,
        db=d.mods.v or 0,
        pan=params:get(self.id.."pan"),
        duration=d.duration_scaled,
        rate=clock.get_tempo()/params:get(self.id.."bpm"),
        watch=(params:get("track")==self.id and self.state==SAMPLE) and 1 or 0,
        retrig=d.mods.x or 0,
        pitch=params:get(self.id.."pitch"),
        gate=params:get(self.id.."gate")/100,
      }
    end,
    note_off=function(d)
      -- if d.m==nil then
      --   do return end
      -- end
      -- local id=self.id.."_"..d.m
      -- self.states[SAMPLE]:play{on=false,id=self.id.."_"..d.m}
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
    note_off=function(d) end,
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
    note_off=function(d) end,
  })
  -- crow 1+2
  for i=1,2 do
    table.insert(self.play_fn,{
      note_on=function(d)
        local level=util.linlin(-48,12,0,10,params:get(self.id.."db")+(d.mods.v or 0))
        local note=d.m+params:get(self.id.."pitch")
        if level>0 then
          crow.output[i+1].action=string.format("ar(%3.3f,%3.3f,%3.3f)",
          params:get(self.id.."attack"),params:get(self.id.."release"),level)
          crow.output[i].volts=(note-24)/12
          crow.output[i+1](true)
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
                crow.output[i+1](true)
              end
            end
          end)
        end
      end,
      note_off=function(d)
        crow.output[i+1](false)
      end,
    })
  end

  -- midi device
  table.insert(self.play_fn,{
    note_on=function(d)
      self.notes_on[6][d.m]=true
      local vel=util.linlin(-48,12,0,127,params:get(self.id.."db")+(d.mods.v or 0))
      local note=d.m+params:get(self.id.."pitch")
      if vel>0 then
        midi_device[params:get(self.id.."midi_dev")].note_on(note,vel,params:get(self.id.."midi_ch"))
        midi_device[params:get(self.id.."midi_dev")].notes[d.m]=note
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
              midi_device[params:get(self.id.."midi_dev")].notes[d.m]=note
            end
          end
        end)
      end
    end,
    note_off=function(d)
      local note=midi_device[params:get(self.id.."midi_dev")].notes[d.m]
      if note~=nil then
        midi_device[params:get(self.id.."midi_dev")].note_off(note,0,params:get(self.id.."midi_ch"))
      end
    end,
  })

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

function Track:emit(beat,ppq)
  if params:get(self.id.."play")==0 or params:get(self.id.."mute")==1 or ppq~=params:get(self.id.."ppq")  then
    do return end
  end
  if self.tli~=nil and self.tli.track~=nil then
    --print("beat",beat,"ppq",ppq)
    local i=(beat-1)%#self.tli.track+1
    local t=self.tli.track[i]
    for _,d in ipairs(t.off) do
      if d.m~=nil then
        self.play_fn[params:get(self.id.."track_type")].note_off(d)
      end
    end
    for _,d in ipairs(t.on) do
      if d.mods~=nil then
        for k,v in pairs(d.mods) do
          if self.mods[k]~=nil then
            self.mods[k](v)
          end
        end
      end
      if self.flag_parsed then
        self.flag_parsed=nil
        for i,notes_on in ipairs(self.notes_on) do
          for m,_ in pairs(notes_on) do
            print("notes_on",m)
            self.play_fn[i]:note_off({m=m})
            self.notes_on[i][m]=nil
          end
        end
      end
      d.duration_scaled=d.duration*(clock.get_beat_sec()/params:get(self.id.."ppq"))
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
  elseif k=="CTRL+P" then
    if v==1 then
      params:set(self.id.."play",1-params:get(self.id.."play"))
      show_message(params:get(self.id.."play")==0 and "stopped" or "playing")
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
