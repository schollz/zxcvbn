-- zxcvbn v1.6.0
--
--
-- zxcvbn.norns.online
--
--
--
--    ▼ instructions below ▼
--
-- E1/E2/E3 change parameters
-- K2/K3 change track
-- K1+K2 mutes
-- K1+K3 plays
--
-- keyboard quickstart
--
-- ctrl+p plays
-- ctrl+<num> change track
-- tab toggles sample mode
-- ctrl+s saves and parses
--
-- see zxcvbn.norns.online
--    for further help.
--
if not string.find(package.cpath,"/home/we/dust/code/zxcvbn/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/zxcvbn/lib/?.so"
end
json=require("cjson")
parse_chain=include("lib/parse_chain")
track_=include("lib/track")
vterm_=include("lib/vterm")
sample_=include("lib/sample")
viewselect_=include("lib/viewselect")
installer_=include("lib/installer")
tracker_=include("lib/tracker")
softsample_=include("lib/softsample")
grid_=include("lib/ggrid")
tli_=include("lib/tli")
archive_=include("lib/archive")
tli=tli_:new()
lattice=require("lattice")
musicutil=require("musicutil")
lfos_=require("lfo")
UI=require("ui")

-- globals
softcut_buffers={1,1,2,1,1,2}
softcut_offsets={2,70,2,2,70,2}
softcut_positions={0,0,0,0,0,0}
softcut_renders={{},{},{}}
softcut_rendering={false,false,false,false,false,false}
local fverb_so="/home/we/.local/share/SuperCollider/Extensions/fverb/Fverb.so"
engine.name=util.file_exists(fverb_so) and "Zxcvbn" or nil

debounce_fn={}
osc_fun={}

function init()
  -- turn reverb off
  params:set("reverb",1)

  -- check if engine file exists
  Needs_Restart=false
  if not util.file_exists(fverb_so) then
    print("building Fverb...")
    util.os_capture("cd ".._path.code.."zxcvbn/lib/ignore && ./build.sh")
    util.os_capture("cp -r " .._path.code.."zxcvbn/lib/ignore/fverb/build /home/we/.local/share/SuperCollider/Extensions/fverb")
    print("installed Fverb")
    Needs_Restart=true
  end
  Restart_Message=UI.Message.new{"please restart norns"}
  if Needs_Restart then redraw() return end
  -- rest of init()

  -- setup screens
  screens={}
  screen_ind=1
  table.insert(screens,installer_:new())
  table.insert(screens,tracker_:new())

  -- startupclock
  clock.run(function()
    while true do
      debounce_params()
      clock.sleep(1/15)
      redraw()
    end
  end)

  screens[1]:check_install()
end

function init2()
  screen_ind=2
  show_message("zxcvbn ready.",2)
  -- make the default pages
  os.execute("mkdir -p ".._path.data.."zxcvbn/meta")
  os.execute("mkdir -p ".._path.data.."zxcvbn/pages")
  os.execute("mkdir -p ".._path.data.."zxcvbn/tapes")
  for i=1,10 do
    os.execute("truncate -s 0 ".._path.data.."zxcvbn/pages/"..i)
  end
  os.execute(_path.code.."zxcvbn/lib/oscnotify/run.sh &")
  os.execute(_path.code.."zxcvbn/lib/oscconnect/run.sh &")

  -- choose audiowaveform binary
  audiowaveform="audiowaveform"
  local foo=util.os_capture(audiowaveform.." --help")
  if not string.find(foo,"Options") then
    audiowaveform="/home/we/dust/code/zxcvbn/lib/audiowaveform"
  end

  -- get the mx.samples availability
  local foo=util.os_capture("find ".._path.audio.."mx.samples/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n'")
  mx_sample_options={"none"}
  for _,v in ipairs(tli.string_split(foo)) do
    table.insert(mx_sample_options,v)
  end

  -- setup softcut
  audio.level_adc_cut(1)
  audio.level_eng_cut(0)
  audio.level_tape_cut(1)
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
    softcut.level_input_cut(1,i,1)
    softcut.level_input_cut(2,i,1)
    softcut.loop_end(i,softcut_offsets[i]+30) -- will get overridden when we load sample folders, anyway
    softcut.position(i,softcut_offsets[i])
  end

  -- add major parameters
  params_meta()
  params_audioin()
  params_sidechain()
  params_reverb()
  params_kick()
  params_midi()

  local charset={} do -- [0-9a-zA-Z]
    for c=48,57 do table.insert(charset,string.char(c)) end
    for c=65,90 do table.insert(charset,string.char(c)) end
    for c=97,122 do table.insert(charset,string.char(c)) end
  end

  random_string=function (length)
    if not length or length<=0 then return '' end
    math.randomseed(os.clock()^5)
    return random_string(length-1)..charset[math.random(1,#charset)]
  end
  params:add_text("random_string","random_string",random_string(8))
  params:hide("random_string")
  print("RANDOM STRING",params:string("random_string"))

  -- setup tracks
  params:add_number("track","track",1,10,1)
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

  -- add lookups
  params.id_to_name={}
  params.name_to_id={}
  for _,p in ipairs(params.params) do
    -- matrix_depth_1_cell  nil
    if p.name~=nil then
      params.id_to_name[p.id]=p.name
      params.name_to_id[p.name]=p.id
    end
  end

  -- bang params
  if util.file_exists(_path.data.."zxcvbn/meta/load_default") then
    print("zxcvbn: loading default")
    params:default()
    params:set("load_default",3)
  else
    params:bang()
  end

  -- setup osc
  other_norns={}
  clock_pulse=0
  osc_fun={
    keyboard=function(args)
      keyboard.code(args[1],tonumber(args[2]))
    end,
    recordingProgress=function(args)
      local id=math.floor(tonumber(args[1]))
      local progress=tonumber(args[2])
      print("recordingProgress",id,progress)
      tracks[id].loop.pos_rec=progress
    end,
    loopPosition=function(args)
      local id=math.floor(tonumber(args[1]))
      local position=tonumber(args[2])
      tracks[id].loop.pos_play=position
      debounce_fn[id.."looping"]={7,function()
        print("looping done")
        tracks[id].loop.pos_play=-1
      end}
    end,
    recordingDone=function(args)
      local id=math.floor(tonumber(args[1]))
      print("recordingDone",id)
      tracks[id].loop.pos_rec=100
      tracks[id].loop.send_tape=0
      params:set(id.."mute",1)
    end,
    progress=function(args)
      tracks[params:get("track")]:set_position(tonumber(args[1]))
    end,
    progressbar=function(args)
      show_message(args[1])
      show_progress(tonumber(args[2]))
    end,
    oscload=function(args)
      print("args[1]",args[1])
      print("args[2]",args[2])
      local track=tonumber(args[1])
      if track>=1 and track<=10 then
        tracks[track]:load_text(args[2])
      end
    end,
    oscnotify=function(args)
      print("file edited ok!")
      rerun()
    end,
    oscdiscover=function(args)
      print("discovered other norns; "..args[1])
      table.insert(other_norns,args[1])
      for _,addr in ipairs(other_norns) do
        osc.send({addr,10111},"/requestsync",{})
      end
    end,
    requestsync=function(args)
      for _,addr in ipairs(other_norns) do
        osc.send({addr,10111},"/pulsesync",{clock_pulse,clock.get_tempo()})
      end
    end,
    pulsesync=function(args)
      print("incoming pulse: "..args[1])
      clock_pulse=tonumber(args[1])
      local tempo=tonumber(args[2])
      if tempo~=clock.get_tempo() then
        params:set("clock_tempo",tempo)
      end
      debounce_fn["pulsesync"]={15,function()end}
    end,
    oscpage=function(args)
      local path=args[1]
      if debounce_fn["ignore_page"]==nil and path~=nil then
        print("oscpage")
        tab.print(args)
        local name=string.sub(path,#path)
        local id=tonumber(name)
        if id~=nil then
          local f=io.open(path,"rb") -- r read mode and b binary mode
          if not f then return nil end
          local content=f:read("*a") -- *a or *all reads the whole file
          f:close()
          tracks[id]:load_text(content)
        elseif path==_path.data.."zxcvbn/pages/all" then
          local f=io.open(path,"rb") -- r read mode and b binary mode
          if not f then return nil end
          local content=f:read("*a") -- *a or *all reads the whole file
          f:close()
          for i,text in ipairs(tli.string_split(content,"###")) do
            tracks[i]:load_text(tli.trim(text))
          end
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

  -- start lattice
  current_tempo=clock.get_tempo()
  clock_pulse_sync=math.random(24*12,24*48)
  clock.run(function()
    while true do
      clock_pulse=clock_pulse+1
      for _,track in ipairs(tracks) do
        track:emit(clock_pulse)
      end
      -- norns syncing
      if next(other_norns)~=nil then
        -- if (clock_pulse-1)%24==0 then
        --   print("beat",(clock_pulse-1)/24)
        -- end
        if debounce_fn["pulsesync"]==nil and (clock_pulse%clock_pulse_sync==0 or current_tempo~=clock.get_tempo() or clock_pulse==1) then
          current_tempo=clock.get_tempo()
          for _,addr in ipairs(other_norns) do
            osc.send({addr,10111},"/pulsesync",{clock_pulse,current_tempo})
          end
          clock_pulse_sync=math.random(24*12,24*48)
        end
      end
      clock.sync(1/24)
    end
  end)

  -- start softcut polling
  softcut.event_phase(function(i,x)
    softcut_positions[i]=x
  end)

  softcut.event_render(function(ch,start,sec_per_sample,samples)
    print("got render for ",ch,start,sec_per_sample)
    for i=1,3 do
      if ch==softcut_buffers[i] and start>=softcut_offsets[i] and start<=softcut_offsets[i]+60 then
        print("assigned to ",i)
        softcut_renders[i]=samples
        softcut_rendering[i]=false
        do return end
      end
    end
  end)
  softcut.poll_start_phase()

  -- setup polls
  pitch_polls={}
  pitch_poll_on=false
  pitch_polls_sma={sma(20),sma(20)}
  for i,v in ipairs({"pitch_in_l","pitch_in_r"}) do
    pitch_polls[i]=poll.set(v)
    pitch_polls[i].callback=function(val)
      if val>10 then
        val=pitch_polls_sma[i](val)
        if debounce_fn[v]==nil then
          debounce_fn[v]={1,function() return val end}
        else
          debounce_fn[v]={debounce_fn[v][1]>=15 and 15 or (debounce_fn[v][1]+1),function() return val end}
        end
      end
    end
    pitch_polls[i].time=0.05
    pitch_polls[i]:stop()
  end

  if util.file_exists(_path.data.."zxcvbn/first") then
    params:set("clock_tempo",150)
    params:read(_path.data.."zxcvbn/zxcvbn-01.pset")
    os.execute("rm -f ".._path.data.."zxcvbn/first")
  end

  -- setup grid
  g_=grid_:new()

  --   -- Am F
  params:set("1track_type",6)
  params:set("1play_through",1)
  params:set("1sample_file",_path.data.."zxcvbn/samples/amenbreak_bpm136.wav")
  tracks[1]:load_text([[
0 1 2 3
0 - - a
9 a b c
d - e a
0 1
0 2
  ]])
  -- params:set("1play",1)

  --   tracks[2]:load_text([[
  -- c4 pm
  -- a3
  --   ]])

  --   tracks[3]:load_text([[
  -- a1 pm
  -- f1
  --         ]])

  --   tracks[4]:load_text([[
  -- e3 d2 pm
  -- c2
  --     ]])

  --   params:set("1track_type",6)
  --   -- params:set("1sample_file",_path.audio.."mx.samples/alto_sax_choir/52.1.1.1.0.wav")
  --   -- for i=1,5 do
  --   --   params:set(i.."track_type",7)
  --   --   params:set(i.."crow_type",2)
  --   -- end
  --   params:set("track",1)
  --   params:set("1play",1)
  --   clock.run(function()
  --     clock.sleep(0.5)
  --     params:set("1mute",0)
  --     clock.sleep(1)
  --     tracks[1]:loop_record()
  --     clock.sleep(8)
  --     params:set("1mute",0)
  --     clock.sleep(0.2)
  --     tracks[1]:loop_record()
  --   end)

  -- DEBUG DEBUG
  -- params:set("1track_type",7)
  -- params:set("audioinpanL",0)
  -- params:set("1scale_mode",2)
end

function sma(period)
  local t={}
  function sum(a,...)
    if a then return a+sum(...) else return 0 end
  end
  function average(n)
    if #t==period then table.remove(t,1) end
    t[#t+1]=n
    return sum(table.unpack(t))/#t
  end
  return average
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  os.execute("pkill -f oscnotify")
end

function reset_clocks()
  clock_pulse=0
  tli:reset()
end

function keyboard.code(k,v)
  screens[screen_ind]:keyboard(k,v)
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

function enc(k,d)
  screens[screen_ind]:enc(k,d)
end

function key(k,z)
  screens[screen_ind]:key(k,z)
end

function redraw()
  if Needs_Restart then
    screen.clear()
    Restart_Message:redraw()
    screen.update()
    return
  end
  screen.clear()
  screens[screen_ind]:redraw()
  draw_message()

  if debounce_fn["pitch_in_r"]~=nil then
    local freq=debounce_fn["pitch_in_r"][2]()
    local note_num=musicutil.freq_to_note_num(freq)
    local note_exact=math.log(freq/440)/math.log(2)*12+69
    local note_diff=util.round(100*(note_exact-note_num))
    local note_name=musicutil.note_num_to_name(note_num,true)
    screen.level(debounce_fn["pitch_in_r"][1])
    screen.move(127,62)
    screen.font_size(16)
    screen.text_right(note_name)
    local text_width=screen.text_extents(note_name)
    screen.font_size(8)
    screen.move(127-text_width-3,62)
    screen.text_right((note_diff>0 and "+" or "")..math.floor(note_diff))
  end

  if debounce_fn["pitch_in_l"]~=nil then
    local freq=debounce_fn["pitch_in_l"][2]()
    local note_num=musicutil.freq_to_note_num(freq)
    local note_exact=math.log(freq/440)/math.log(2)*12+69
    local note_diff=util.round(100*(note_exact-note_num))
    local note_name=musicutil.note_num_to_name(note_num,true)
    screen.level(debounce_fn["pitch_in_l"][1])
    screen.move(8,62)
    screen.font_size(16)
    screen.text(note_name)
    local text_width=screen.text_extents(note_name)
    screen.font_size(8)
    screen.move(8+text_width+3,62)
    screen.text((note_diff>0 and "+" or "")..math.floor(note_diff))
  end

  -- screen.level(15)
  -- screen.move(127,62)
  -- screen.font_size(16)
  -- screen.text_right("Fb")
  -- local text_width=screen.text_extents("Fb")
  -- screen.font_size(8)
  -- screen.move(127-text_width-2,62)
  -- screen.text_right("+10")

  screen.update()
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

function params_meta()
  params:add_group("META",5)
  params:add_option("ambisonics","loop ambisonics",{"no","yes"},1)
  params:add_option("load_default","load default on startup",{"n/a","no","yes"},1)
  params:set_action("load_default",function(x)
    if x==2 then
      os.execute("rm ".._path.data.."zxcvbn/meta/load_default")
    elseif x==3 then
      os.execute("touch ".._path.data.."zxcvbn/meta/load_default")
    end
  end)
  archive_:new()
end

function params_audioin()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.01,default=-1,response=1},
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
  params:set("audioinpanR",1)
  params:set("audioinpanL",-1)
end

function params_reverb()

  -- predelay: 20,
  -- input_amount: 100,
  -- input_lowpass_cutoff: 10000,
  -- input_highpass_cutoff: 100,
  -- input_diffusion_1: 75,
  -- input_diffusion_2: 62.5,
  -- tail_density: 70,
  -- decay: 50,
  -- damping: 5500,
  -- modulator_frequency: 1,
  -- modulator_depth: 0.1,
  local params_menu={
    {id="decay",name="decay time",min=0.4,max=100,exp=false,div=0.1,default=4,unit="s"},
    {id="shimmer",name="shimmer",min=0,max=2,exp=false,div=0.01,default=0.15,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="predelay",name="predelay",min=0,max=1000,exp=false,div=1,default=20.0,unit="ms"},
    {id="input_amount",name="input amount",min=0,max=100,exp=false,div=1,default=100.0,unit="%"},
    {id="input_lowpass_cutoff",name="lpf",min=10,max=18000,exp=true,div=10,default=10000,unit="Hz"},
    {id="input_highpass_cutoff",name="hpf",min=10,max=5000,exp=true,div=5,default=100,unit="Hz"},
    {id="input_diffusion_1",name="diffuser 1",min=0,max=100,exp=false,div=0.5,default=75,unit="%"},
    {id="input_diffusion_2",name="diffuser 2",min=0,max=100,exp=false,div=0.5,default=62.5,unit="%"},
    {id="tail_density",name="tail density",min=0,max=100,exp=false,div=0.5,default=70,unit="%"},
    {id="damping",name="damping",min=10,max=15000,exp=true,div=100,default=5500,unit="Hz"},
    {id="modulator_frequency",name="mod freq",min=0.01,max=4.0,exp=false,div=0.01,default=1.0,unit="Hz"},
    {id="modulator_depth",name="mod depth",min=0.0,max=10.0,exp=false,div=0.01,default=1.2},
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
      if pram.id=="decay" then
        v=util.clamp(100*math.exp(-1.1/v),0,100)
      end
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
    {id="lpshelf",name="lp boost freq",min=12,max=127,exp=false,div=1,default=23,formatter=function(param) return musicutil.note_num_to_name(math.floor(param:get()),true)end,fn=function(x) return musicutil.note_num_to_freq(x) end},
    {id="lpgain",name="lp boost db",min=-48,max=36,exp=false,div=1,default=0,unit="dB"},
    {id="delay_feedback",name="tape delay feedback",min=0,max=1,exp=false,div=0.01,default=0.8,unit="x"},
    {id="delay_time",name="tape delay time",min=0.01,max=4,exp=false,div=clock.get_beat_sec()/16,default=clock.get_beat_sec(),unit="s"},
    {id="tape_slow",name="tape slow",min=0,max=2,exp=false,div=0.01,default=0.0,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
  }
  params:add_group("AUDIO OUT",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(pram.id,function(v)
      engine.main_set(pram.id,pram.fn~=nil and pram.fn(v) or v)
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
        note_on=function(note,vel,ch) connection:note_on(math.floor(note),math.floor(vel),ch) end,
        note_off=function(note,vel,ch) connection:note_off(math.floor(note),math.floor(vel),ch) end,
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

function whatislove()
  params:set("3track_type",5)
  params:set("3mx_sample",3)
  params:set("3mx_synths",9)
  params:set("3mod1",0.5)
  params:set("3mod2",0.2)
  params:set("3mod3",-0.3)
  params:set("3mod4",0.2)
  params:set("3db",-19)
  params:set("3attack",50)
  params:set("3release",800)
  params:set("3send_reverb",99)
  tracks[3]:load_text([[
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3 
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3 
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3 
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3 
- - - Bb;3
- - - Dm;3
- - - F;3
- - - Gm;3
         
]])
  -- Em;3 p2*m z50 k500 l100
  -- Bm;3
  -- C;3
  -- G;3
  -- chain a*4 b*4

  -- p96

  -- pattern a
  -- Em;3 rud s12 t12
  -- Bm;3 rud s12 t12
  -- C;3 rud s12 t12
  -- G;3 rud s12 t12

  -- pattern b
  -- G;3 rud s12 t12
  -- D;3 rud s12 t12

  params:set("2track_type",4)
  params:set("2mx_sample",3)
  params:set("2mx_synths",6)
  params:set("2mod1",0.5)
  params:set("2mod2",0.2)
  params:set("2mod3",-0.3)
  params:set("2mod4",0.01)
  params:set("2db",-10)
  params:set("2db_sub",-96)

  params:set("2release",1000)
  tracks[2]:load_text([[
chain a*2 b*2 c*2 d*2
 
ph
 
pattern a
bb6 a6 bb6 g6
pattern b
bb6 a6 bb6 f6
pattern c
a6 g6 a6 f6 
pattern d
a6 g6 a6 f6 
 
]])

  params:set("1track_type",4)
  params:set("1mx_sample",1)
  params:set("1mx_synths",7)
  params:set("1mod1",0.7)
  params:set("1mod2",0.3)
  params:set("1mod3",-0.32)
  params:set("1mod4",0.0)
  params:set("1release",3000)
  tracks[1]:load_text([[
chain a
 
pm
 
pattern a
g5bb4 - - - d5 eb5 d5 f5
- d5bb4 - - . . d5 f5
f5c4 d5 - - - . d5 c5a4
-
. . . . d5 eb5 d5 f5
-  d5 . . . . d5 f5
- d5 . . . . d5 c5
. . . . . d5 f4 g5
 
 
]])

  params:set("4sample_file",_path.data.."zxcvbn/samples/AP2_Kick_Snare_Loop_135_Jack_key_bpm135_beats32_.flac")
  params:set("4drive",0.1)
  params:set("4db",-20)
  tracks[4]:load_text([[
chain a b b a c b
 
pattern a
0b1d0234 rud p96 u90 n0 h100 w0
 
pattern b
01234 rud n0 h100 w0
 
pattern c
2 x11 n-1 36 h70:100 w-50:50
2 x13 n1 v-1 24 h90
 
  ]])
  params:set("5sample_file",_path.data.."zxcvbn/samples/Diver_Break_172_PL_key_bpm172_beats8_.flac")
  params:set("5drive",0.2)
  params:set("5db",-18)
  tracks[5]:load_text([[
0123 rud s12 t12
 
  ]])

  params:set("6sample_file",_path.data.."zxcvbn/samples/whatislove_bpm150.flac")
  params:set("6db",-18)
  tracks[6]:load_text([[
chain a
 
pattern a
- p4*m-32 n0 mi10,30,90
0 p32
- p8*m
 
  ]])

  params:set("7track_type",7)
  params:set("7attack",200)
  params:set("7release",400)
  tracks[7]:load_text([[
chain a*4 b*4
 
p96 
 
pattern a
g2 . . a2 
bb2 . . f2 
d2 . . a2
f2 . . g2 a2 bb2 
 
pattern b
Gm;2 rtu t6 s7
Bb;2 rtud t6 s8
Dm;2 rtu t6 s9
F;2 rtud t6 s7
  ]])
end
