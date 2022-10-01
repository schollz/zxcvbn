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
tli_=include("lib/tli")
tli=tli_:new()
lattice=require("lattice")
musicutil=require("musicutil")
-- debouncer
debounce_fn={}

engine.name="Zxcvbn"

function init()
  os.execute(_path.code.."zxcvbn/lib/oscnotify/run.sh &")

  -- setup screens
  screens={}
  screen_ind=1
  table.insert(screens,tracker_:new())
  table.insert(screens,viewselect_:new())

  -- add major parameters
  params_audioin()
  params_sidechain()
  params_kick()
  params_midi()

  -- setup tracks
  params:add_number("track","track",1,4,1)
  params:set_action("track",function(x)
    for i,track in ipairs(tracks) do
      track:select(i==x)
    end
  end)

  tracks={}
  for i=1,4 do
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
    oscnotify=function(args)
      print("file edited ok!")
      rerun()
    end,
    audition=function(args)
      screens[2]:set_pos(tonumber(args[1]))
    end,
  }
  osc.event=function(path,args,from)
    if string.sub(path,1,1)=="/" then
      path=string.sub(path,2)
    end
    if osc_fun[path]~=nil then osc_fun[path](args) else
      print("osc.event: '"..path.."' ?")
    end
  end

  clock.run(function()
    while true do
      debounce_params()
      clock.sleep(1/10)
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
        clock.sync(1/96)
      end
    end
  end)

  params:set("1track_type",2)
  params:set("1sample_file",_path.code.."zxcvbn/lib/60.3.3.1.0.wav")
  --   tracks[1]:load_text([[
  -- chain a
  -- pattern a
  -- ppl 32
  -- c4 c4 c5 c3 c4
  -- #Cmaj;4 xud z5 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4 c4
  -- #Am/C;4 xud z5
  -- #Em/B;3 xud z5
  -- #G/B;2 xud z5

  --   ]])

  -- tracks[1]:parse_tli()

  params:set("2track_type",3)
  tracks[2]:load_text([[
chain a
 
pattern a
Cmaj;3 w192
Am/C;4
Em/B;3
G/B;3
          ]])

  params:set("3sample_file",_path.code.."zxcvbn/lib/amenbreak_bpm136.wav")
  params:set("3track_type",1)
  tracks[3]:load_text([[
00...................00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000chain a
 
pattern a
0 n0 w24
1
2
3
 
pattern b
2 n0
3 n2
 
pattern c
3 x5 n-2
-
    ]])
  params:set("3play_through",2)
  params:set("1compressible",1)
  params:set("2compressible",1)
  params:set("3compressing",1)
  params:set("sidechain_mult",0.5)
  params:set("1db",-10)
  params:set("2db",-1)
  params:set("3db",-7.7)
  -- params:set("3play",1)

  tracks[4]:load_text([[
chain c*2 (a b)*2
 
pattern c 
0 w24 n0
9 a b c
1 4 x8 v-4 w48 
5 6 7 8 w36 
9 a b c w24
 
pattern b 
0 x5 v-1 w24 n0
 
pattern a
0 v12 w24
1 2
0 v6
4 a 1 2
0 v8
7 8 a b v8
e e e x4 n-1
f x8 n1
]])

  params:set("4sample_file",_path.code.."zxcvbn/lib/yelidek_kit.wav")
  params:set("4track_type",1)
  params:set("4play_through",2)
  -- params:set("4play",1)
  params:set("track",4)
  clock.run(function()
    clock.sleep(1)
    engine.mx(
      _path.audio.."mx.samples/steinway_model_b",
      60,120,1.0,0,0.01,2,2,0,0,0
    )
    clock.sleep(0.5)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72,120,1.0,0,0.01,2,2,0,0,0)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72+5,120,1.0,0,0.01,2,2,0,0,0)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72+7,120,1.0,0,0.01,2,2,0,0,0)
    clock.sleep(2)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72,120,1.0,0,0.01,2,2,0,0,1.0)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72+5,120,1.0,0,0.01,2,2,0,0,1.0)
    engine.mx(_path.audio.."mx.samples/steinway_model_b",72+7,120,1.0,0,0.01,2,2,0,0,1.0)
  end)
end

function reset_clocks()
  -- TODO: redo
  -- for i,_ in ipairs(sequencer_beats) do
  --   sequencer_beats[i]=0
  -- end
  -- sequencer:hard_restart()
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
  k=shift_on and "SHIFT+"..k or k
  k=ctrl_on and "CTRL+"..k or k
  k=alt_on and "ALT+"..k or k
  for i,_ in ipairs(tracks) do
    if k=="CTRL+"..i then
      params:set("track",i)
      do return end
    end
  end
  if alt_on and tonumber(k)~=nil and tonumber(k)>=1 and tonumber(k)<=9 then
    -- mute group
    local mute_group=tonumber(k)
    local do_mute=-1
    for i,_ in ipairs(tracks) do
      if params:get(i.."mute_group")==mute_group then
        if do_mute<0 then
          do_mute=1-params:get(i.."mute")
        end
        params:set(i.."mute",do_mute)
      end
    end
    if do_mute>-1 then
      show_message((do_mute==1 and "muted" or "unmuted").." group "..mute_group)
    end
  elseif k=="CTRL+P" then
    if v==1 then
      params:set(params:get("track").."play",1-params:get(params:get("track").."play"))
      show_message(params:get(params:get("track").."play")==0 and "stopped" or "playing")
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
    screen.rect(x-w/2,y,w,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    if show_message_progress~=nil and show_message_progress>0 then
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w*(show_message_progress/100),9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
    else
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w,9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
      screen.level(0)
      screen.rect(x-w/2,y,w,10)
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

  screen.level(7)
  screen.rect(0,0,6,66)
  screen.fill()
  screen.level(0)
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
        print(lr,pram.id,v)
        --engine.audioin_set(lr,pram.id,v)
        if params:get("audioin_linked")==2 then
          if pram.id~="pan" then
            params:set("audioin"..pram.id..lrs[3-lri],v,true)
            --engine.audioin_set(lrs[3-lri],pram.id,v)
          else
            params:set("audioin"..pram.id..lrs[3-lri],-v,true)
            --engine.audioin_set(lrs[3-lri],pram.id,-1*v)
          end
        end
      end)
    end
  end
  params:set("audioinpanR",1)
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
  midi_device={}
  midi_device_list={}
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
