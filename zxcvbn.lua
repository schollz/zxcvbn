-- zxcvbn
--
--
-- llllllll.co/t/zxcvbn
--
--
--
--    ▼ instructions below ▼

if not string.find(package.cpath,"/home/we/dust/code/zxcvbn/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/zxcvbn/lib/?.so"
end
json=require("cjson")
parse_chain=include("lib/parse_chain")
track_=include("lib/track")
vterm_=include("lib/vterm")
sample_=include("lib/sample")
viewselect_=include("lib/viewselect")
tracker_=include("lib/tracker")
softsample_=include("lib/softsample")
tli_=include("lib/tli")
tli=tli_:new()
lattice=require("lattice")
musicutil=require("musicutil")
-- debouncer
debounce_fn={}

-- globals
softcut_buffers={1,1,2,1,1,2}
softcut_offsets={2,70,2,2,70,2}
softcut_positions={0,0,0,0,0,0}
softcut_renders={{},{},{}}

engine.name="Zxcvbn"

function init()
  -- make the default pages
  os.execute("mkdir -p ".._path.data.."zxcvbn/pages")
  for i=1,9 do
    if not util.file_exists(_path.data.."zxcvbn/pages/"..i) then
      os.execute("touch ".._path.data.."zxcvbn/pages/"..i)
    end
  end
  os.execute(_path.code.."zxcvbn/lib/oscnotify/run.sh &")

  -- choose audiowaveform binary
  audiowaveform="/home/we/dust/code/zxcvbn/lib/audiowaveform"
  local foo=util.os_capture(audiowaveform.." --help")
  if not string.find(foo,"Options") then
    audiowaveform="audiowaveform"
  end

  -- get the mx.samples availability
  local foo=util.os_capture("find ".._path.audio.."mx.samples/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n'")
  mx_sample_options=tli.string_split(foo)

  -- setup softcut
  for i=1,3 do
    -- enable playback head
    softcut.buffer(i,softcut_buffers[i])
    softcut.enable(i,1)
    softcut.play(i,1)
    softcut.loop(i,0)
    softcut.fade_time(i,0.005)
    softcut.loop_start(i,softcut_offsets[i])
    softcut.loop_end(i,softcut_offsets[i]+30) -- will get overridden when we load sample folders, anyway
    softcut.position(i,softcut_offsets[i]+30) -- set to the loop end for each voice, so we aren't playing anything
    softcut.rate(i,1)
    softcut.rate_slew_time(i,0.005)
    softcut.pan_slew_time(i,0.005)
    softcut.level_slew_time(i,0.005)
    softcut.post_filter_dry(i,0)
    softcut.post_filter_lp(i,1)
    softcut.post_filter_fc(i,12000)
    softcut.level(i,1)
  end
  for i=4,6 do
    -- enable recording head (decoupled from playback head)
    softcut.buffer(i,softcut_buffers[i])
    softcut.enable(i,1)
    softcut.play(i,1)
    softcut.loop(i,1)
    softcut.rec(i,1)
    softcut.level(i,0)
    softcut.rec_level(i,0)
    softcut.pre_level(i,1)
    softcut.fade_time(i,0.05)
    softcut.loop_start(i,softcut_offsets[i])
    softcut.loop_end(i,softcut_offsets[i]+30) -- will get overridden when we load sample folders, anyway
  end
  -- setup screens
  screens={}
  screen_ind=1
  table.insert(screens,tracker_:new())

  -- add major parameters
  params_audioin()
  params_sidechain()
  params_reverb()
  params_kick()
  params_midi()

  -- setup tracks
  params:add_number("track","track",1,9,1)
  params:set_action("track",function(x)
    for i,track in ipairs(tracks) do
      track:select(i==x)
    end
  end)

  tracks={}
  for i=1,10 do
    table.insert(tracks,track_:new{id=i})
  end

  -- define param actions
  params_action()

  -- bang params
  params:bang()

  -- setup osc
  osc_fun={
    progress=function(args)
      tracks[params:get("track")]:set_position(tonumber(args[1]))
    end,
    progressbar=function(args)
      show_message(args[1])
      show_progress(tonumber(args[2]))
    end,
    oscnotify=function(args)
      print("file edited ok!")
      rerun()
    end,
    oscpage=function(args)
      local path=args[1]
      if debounce_fn["ignore_page"]==nil and path~=nil then
        local id=tonumber(string.sub(path,#path))
        if id~=nil then
          local f=io.open(path,"rb") -- r read mode and b binary mode
          if not f then return nil end
          local content=f:read("*a") -- *a or *all reads the whole file
          f:close()
          tracks[id]:load_text(content)
        end
      end
    end,
    audition=function(args)
      tracks[params:get("track")].states[3]:set_pos(tonumber(args[1]))
    end,
    aubiodone=function(args)
      local id=tonumber(args[1])
      local data_s=args[2]
      tracks[id]:got_onsets(data_s)
    end,
  }
  osc.event=function(path,args,from)
    if string.sub(path,1,1)=="/" then
      path=string.sub(path,2)
    end
    if osc_fun[path]~=nil then osc_fun[path](args) else
      -- print("osc.event: '"..path.."' ?")
    end
  end

  clock.run(function()
    while true do
      debounce_params()
      clock.sleep(1/15)
      redraw()
    end
  end)

  -- start lattice
  clock_pulse=0
  clock.run(function()
    while true do
      clock_pulse=clock_pulse+1
      for _,track in ipairs(tracks) do
        track:emit(clock_pulse)
      end
      clock.sync(1/24)
    end
  end)

  -- start softcut polling
  softcut.event_phase(function(i,x)
    softcut_positions[i]=x
  end)
  softcut.event_render(function(ch,start,sec_per_sample,samples)
    for i=1,3 do
      if ch==softcut_buffers[i] and start>=softcut_offsets[i] and start<=softcut_offsets[i+1] then
        softcut_renders[i]=samples
      end
    end
  end)
  softcut.poll_start_phase()

  params:set("1track_type",4)
  params:set("1mx_synths",9)
  params:set("1mod1",0.5)
  params:set("1mod2",0.2)
  params:set("1mod3",-0.3)
  params:set("1mod4",0.2)
  params:set("1release",1000)
  tracks[1]:load_text([[
chain a*4 b*4
 
p96
 
pattern a
Em;3 rud s12 t12
Bm;3 rud s12 t12
C;3 rud s12 t12
G;3 rud s12 t12
 
pattern b
G;3 rud s12 t12
D;3 rud s12 t12
Em;3 rud s12 t12
C;3 rud s12 t12
          ]])

  params:set("2track_type",1)
  params:set("2play_through",1)
  params:set("2sample_file",_path.code.."zxcvbn/lib/amenbreak_bpm136.wav")
  params:set("2drive",0.7)
  params:set("2compression",0.2)
  params:set("2db",-16)
  params:set("track",2)
  tracks[2]:load_text([[
chain a*4 b*4
 
p12
 
pattern b 
0
-
2 x5 n-1
-
 
pattern a
0123 rud s17 t24 p384 u50 w0 h100 i70
 
pattern b
2acb012345a rud s17 t12 p384 m0 i80 h70 w-50,50
 
          ]])
end

function reset_clocks()
  clock_pulse=0
end

function debounce_params()
  for k,v in pairs(debounce_fn) do
    if v~=nil and v[1]~=nil and v[1]>0 then
      v[1]=v[1]-1
      if v[1]~=nil and v[1]==0 then
        if v[2]~=nil then
          local status,err=pcall(v[2])
          if err~=nil then
            print(status,err)
          end
        end
        debounce_fn[k]=nil
      else
        debounce_fn[k]=v
      end
    end
  end
end

ctrl_on=false
shift_on=false
alt_on=false
function keyboard.code(k,v)
  if string.find(k,"CTRL") then
    ctrl_on=v>0
    do return end
  elseif string.find(k,"SHIFT") then
    shift_on=v>0
    do return end
  elseif string.find(k,"ALT") then
    alt_on=v>0
    do return end
  end
  if alt_on and tonumber(k)~=nil and tonumber(k)>=0 and tonumber(k)<=9 then
    if v==1 then
      -- mute group
      local mute_group=tonumber(k)
      if mute_group==0 then
        mute_group=10
      end
      local do_mute=-1
      for i,_ in ipairs(tracks) do
        if params:get(i.."mute_group")==mute_group then
          if do_mute<0 then
            do_mute=1-params:get(i.."mute")
            break
          end
        end
      end
      for i,_ in ipairs(tracks) do
        if params:get(i.."mute_group")==mute_group then
          params:set(i.."mute",do_mute)
        end
      end
      print("MUTE",alt_on,tonumber(k),mute_group,do_mute)
      if do_mute>-1 then
        show_message((do_mute==1 and "muted" or "unmuted").." group "..mute_group)
      end
    end
    do return end
  end
  k=shift_on and "SHIFT+"..k or k
  k=ctrl_on and "CTRL+"..k or k
  k=alt_on and "ALT+"..k or k
  for i,_ in ipairs(tracks) do
    if k=="CTRL+"..(i>0 and i or 10) then
      params:set("track",i)
      do return end
    end
  end
  if k=="CTRL+P" then
    if v==1 then
      params:set(params:get("track").."play",1-params:get(params:get("track").."play"))
      show_message((params:get(params:get("track").."play")==0 and "stopped" or "playing").." track "..params:get("track"))
    end
    do return end
  end
  screens[screen_ind]:keyboard(k,v)
end

function enc(k,d)
  screens[screen_ind]:enc(k,d)
end

function key(k,z)
  screens[screen_ind]:key(k,z)

end

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  seconds=seconds or 2
  show_message_clock=10*seconds
  show_message_text=message
end

function draw_message()
  if show_message_clock~=nil and show_message_text~=nil and show_message_clock>0 and show_message_text~="" then
    show_message_clock=show_message_clock-1
    screen.blend_mode(0)
    local x=64
    local y=28
    local w=screen.text_extents(show_message_text)+8
    screen.rect(x-w/2,y,w+2,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w+2,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    if show_message_progress~=nil and show_message_progress>0 then
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w*(show_message_progress/100)+2,9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
    else
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w+2,9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
      screen.level(0)
      screen.rect(x-w/2,y,w+2,10)
      screen.stroke()
    end
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
  end
end

function redraw()
  screen.clear()
  screens[screen_ind]:redraw()

  screen.level(5)
  screen.rect(0,0,6,66)
  screen.fill()
  screen.level(params:get(params:get("track").."mute")==1 and 4 or 0)
  screen.move(3,6)
  screen.text_center(params:get("track"))
  for i,v in ipairs(tracks[params:get("track")].scroll) do
    screen.move(3,6+(i*8))
    screen.text_center(v)
  end

  draw_message()
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  os.execute("pkill -f oscnotify")
end

function params_action()
  params.action_write=function(filename,name)
    print("write",filename,name)
    local data={tracks={}}
    for i,track in ipairs(tracks) do
      data.tracks[i]=track:dumps()
    end

    filename=filename..".json"
    local file=io.open(filename,"w+")
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
  end

  params.action_read=function(filename,silent)
    print("read",filename,silent)
    -- load all the patterns
    filename=filename..".json"
    if not util.file_exists(filename) then
      do return end
    end
    local f=io.open(filename,"rb")
    local content=f:read("*all")
    f:close()
    if content==nil then
      do return end
    end
    local data=json.decode(content)
    if data==nil then
      do return end
    end
    for i,s in ipairs(data.tracks) do
      print("loads",i,s)
      tracks[i]:loads(s)
    end
  end
end

function params_kick()

  -- kick
  local params_menu={
    {id="db",name="db adj",min=-96,max=16,exp=false,div=1,default=0.0,unit="db"},
    {id="preamp",name="preamp",min=0,max=4,exp=false,div=0.01,default=1,unit="amp"},
    {id="basenote",name="base note",min=10,max=200,exp=false,div=1,default=24,formatter=function(param) return musicutil.note_num_to_name(param:get(),true)end},
    {id="ratio",name="ratio",min=1,max=20,exp=false,div=1,default=6},
    {id="sweeptime",name="sweep time",min=0,max=200,exp=false,div=1,default=50,unit="ms"},
    {id="decay1",name="decay1",min=5,max=2000,exp=false,div=10,default=300,unit="ms"},
    {id="decay1L",name="decay1L",min=5,max=2000,exp=false,div=10,default=800,unit="ms"},
    {id="decay2",name="decay2",min=5,max=2000,exp=false,div=10,default=150,unit="ms"},
    {id="clicky",name="clicky",min=0,max=100,exp=false,div=1,default=0,unit="%"},
    {id="compressing",name="compressing",min=0,max=1,exp=false,div=1,default=1.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
  }
  params:add_group("KICK",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id="kick_"..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
  end
end

function params_audioin()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.01,default=-1,response=1},
    {id="hpf",name="hpf",min=10,max=2000,exp=true,div=5,default=10},
    {id="hpfqr",name="hpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
    {id="lpf",name="lpf",min=200,max=20000,exp=true,div=100,default=18000},
    {id="lpfqr",name="lpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
    {id="compressing",name="compressing",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
  }
  params:add_group("AUDIO IN",#params_menu*2+1)
  params:add_option("audioin_linked","audio in",{"mono+mono","stereo"},2)
  local lrs={"L","R"}
  for _,pram in ipairs(params_menu) do
    for lri,lr in ipairs(lrs) do
      params:add{
        type="control",
        id="audioin"..pram.id..lr,
        name=pram.name.." "..lr,
        controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
        formatter=pram.formatter,
      }
      params:set_action("audioin"..pram.id..lr,function(v)
        engine.audionin_set(lr,pram.id,v)
        if params:get("audioin_linked")==2 then
          if pram.id~="pan" then
            params:set("audioin"..pram.id..lrs[3-lri],v,true)
            engine.audionin_set(lrs[3-lri],pram.id,v)
          else
            params:set("audioin"..pram.id..lrs[3-lri],-v,true)
            engine.audionin_set(lrs[3-lri],pram.id,-1*v)
          end
        end
      end)
    end
  end
  params:set("audioinpanR",0.1)
  params:set("audioinpanL",-0.1)
end

function params_reverb()
  local params_menu={
    {id="shimmer",name="shimmer",min=0,max=2,exp=false,div=0.01,default=0.0,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="tail",name="tail",min=0,max=8,exp=false,div=0.1,default=4.0,unit="s"},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
  }
  params:add_group("ZEVERB",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(pram.id,function(v)
      engine.reverb_set(pram.id,v)
    end)
  end
end

function params_sidechain()
  local params_menu={
    {id="sidechain_mult",name="amount",min=0,max=8,exp=false,div=0.1,default=2.0},
    {id="compress_thresh",name="threshold",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="compress_level",name="level",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="compress_attack",name="attack",min=0,max=1,exp=false,div=0.001,default=0.01,formatter=function(param) return (param:get()*1000).." ms" end},
    {id="compress_release",name="release",min=0,max=2,exp=false,div=0.01,default=0.2,formatter=function(param) return (param:get()*1000).." ms" end},
  }
  params:add_group("SIDECHAIN",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(pram.id,function(v)
      engine.main_set(pram.id,v)
    end)
  end
end

function params_midi()
  -- midi
  midi_device={{name="none",note_on=function()end,note_off=function()end}}
  midi_device_list={"none"}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local connection=midi.connect(dev.port)
      local name=string.lower(dev.name).." "..i
      print("adding "..name.." as midi device")
      table.insert(midi_device_list,name)
      table.insert(midi_device,{
        name=name,
        note_on=function(note,vel,ch) connection:note_on(note,vel,ch) end,
        note_off=function(note,vel,ch) connection:note_off(note,vel,ch) end,
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

end
