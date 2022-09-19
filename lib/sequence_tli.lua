local SequenceTLI={}

function SequenceTLI:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function SequenceTLI:init()
  -- crow stuff
  params:add_group("CROW",8)
  for j=1,2 do
    local i=(j-1)*2+2
    params:add_control(i.."crow_attack",string.format("crow %d attack",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    params:add_control(i.."crow_sustain",string.format("crow %d sustain",i),controlspec.new(0,10,'lin',0.1,7,'volts',0.1/10))
    params:add_control(i.."crow_decay",string.format("crow %d decay",i),controlspec.new(0.01,4,'lin',0.01,0.5,'s',0.01/3.99))
    params:add_control(i.."crow_release",string.format("crow %d release",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    for _,v in ipairs({"attack","sustain","decay","release"}) do
      params:set_action(i.."crow_"..v,function(x)
        debounce_fn[i.."crow"]={
          5,function()
            crow.output[i].action=string.format("adsr(%3.3f,%3.3f,%3.3f,%3.3f,'linear')",
            params:get(i.."crow_attack"),params:get(i.."crow_sustain"),params:get(i.."crow_decay"),params:get(i.."crow_release"))
          end,
        }
      end)
    end
  end

  -- midi stuff
  self.midi_device={}
  self.midi_device_list={}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local connection=midi.connect(dev.port)
      local name=string.lower(dev.name).." "..i
      print("adding "..name.." as midi device")
      table.insert(self.midi_device_list,name)
      table.insert(self.midi_device,{
        name=name,
        note_on=function(id_,note,vel,ch) connection:note_on(note,vel or 60,ch) end,
        note_off=function(id_,note,vel,ch) connection:note_off(note,vel,ch) end,
      })
      connection.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then
          do return end
        end
        if msg.type=='start' or msg.type=='continue' then
          -- OP-1 fix for transport
          reset()
        elseif msg.type=="stop" then
        elseif msg.type=="note_on" then
        end
      end
    end
  end

  -- setup outputs
  self.outputs={}
  -- TODO: do similar for sample pitch?
  table.insert(self.outputs,{
    name="engine pad",
    note_on=function(note,vel) engine.note_on(note,0.5,0.5) end,
    note_off=function(note) engine.note_off(note) end,
  })

  for _,v in ipairs(self.midi_device) do
    table.insert(self.outputs,{
      name=v.name,
      note_on=v.note_on,
      note_off=v.note_off,
    })
  end
  for i=1,2 do
    table.insert(self.outputs,{
      name=string.format("crow %d+%d",(i-1)*2+1,(i-1)*2+2),
      note_on=function(note,vel,ch)
        crow.output[(i-1)*2+1].volts=(note-24)/12
        crow.output[(i-1)*2+2](true)
      end,
      note_off=function(note,vel,ch)
        crow.output[(i-1)*2+2](false)
      end,
    })
  end

  self.output_list={}
  for _,v in ipairs(self.outputs) do
    table.insert(self.output_list,v.name)
  end

  self.cur=1
  self.tlis={{},{},{},{}}
  for i=1,4 do
    params:add_group("TLI "..i,3)
    params:add_file(i.."tli_file","tli file",_path.data.."break-ops")
    params:set_action(i.."tli_file",function(x)
      if util.file_exists(x) and string.sub(x,-1)~="/" then
        self.path=x
        local f=io.open(x,"rb")
        local content=f:read("*all")
        f:close()
        self.tlis[i]=tli:parse_tli(content)
      end
    end)
    params:add_option(i.."tli_division","division",possible_division_options,5)
    params:add_option(i.."output","output",self.output_list)
  end
end

function SequenceTLI:load(path)
  self.loaded=true
end

function SequenceTLI:emit(division,step)
  for i,t in ipairs(self.tlis) do
    if division==possible_divisions[params:get(i.."tli_division")] and next(self.tlis[i])~=nil and next(self.tlis[i].track)~=nil then
      local notes=t.track
      local notes_len=#notes
      local off=notes[(step-1)%notes_len+1].off
      local info=""
      if next(off)~=nil then
        info=info.."off["
        for _,n in ipairs(off) do
          info=info.." "..n.m
          print(info)
          print(params:get(i.."output"))
          self.outputs[params:get(i.."output")].note_off(n.m)
        end
      end
      local on=notes[(step-1)%notes_len+1].on
      if next(on)~=nil then
        info=info.." on ["
        for _,n in ipairs(on) do
          info=info.." "..n.m
          self.outputs[params:get(i.."output")].note_on(n.m)
        end
      end
      if info~="" then print(info) end
    end
  end
end

return SequenceTLI
