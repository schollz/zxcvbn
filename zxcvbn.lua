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
track_=include("lib/track")
vterm_=include("lib/vterm")
sample_=include("lib/sample")
tli_=include("lib/tli")
tli=tli_:new()
lattice=require("lattice")
musicutil=require("musicutil")

-- global division definitions
possible_divisions={1/32,1/24,1/16,1/12,1/8,1/6,1/4,1/3,1/2,1,2,4}
possible_division_options={"1/32","1/24","1/16","1/12","1/8","1/6","1/4","1/3","1/2","1","2","4"}

-- debouncer
debounce_fn={}

engine.name="Zxcvbn"

function init()
  os.execute(_path.code.."zxcvbn/lib/oscnotify/run.sh &")

  -- add major parameters
  params_kick()

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
  local sequencer=lattice:new{}
  sequencer_beats={}
  for ppq=1,8 do
    sequencer_beats[ppq]=0
    sequencer:new_pattern({
      action=function(t)
        sequencer_beats[ppq]=sequencer_beats[ppq]+1
        for _,track in ipairs(tracks) do
          track:emit(sequencer_beats[ppq],ppq)
        end
      end,
      division=1/(4*ppq),
    })
  end
  sequencer:hard_restart()

  -- params:set("1sample_file",_path.code.."zxcvbn/lib/amenbreak_bpm136.wav")
  -- params:set("1sample_file",_path.code.."zxcvbn/lib/60.3.3.1.0.wav")
  -- tracks[1]:parse_tli()
  params:set("1track_type",3)
  tracks[1]:load_text([[
chain a

pattern a
Am/C
F/C
C
Em/B
  ]])
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
function keyboard.code(k,v)
  if string.find(k,"CTRL") then
    ctrl_on=v>0
    do return end
  elseif string.find(k,"SHIFT") then
    shift_on=v>0
    do return end
  elseif string.find(k,"SPACE") then 
    params:set(params:get("track").."play",1)
    do return end
  end
  k=shift_on and "SHIFT+"..k or k
  k=ctrl_on and "CTRL+"..k or k
  for i,_ in ipairs(tracks) do
    if k=="CTRL+"..i then
      params:set("track",i)
      do return end
    end
  end
  tracks[params:get("track")]:keyboard(k,v)
end

function enc(k,d)
  tracks[params:get("track")]:enc(k,d)
end

function key(k,z)
  tracks[params:get("track")]:key(k,z)
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
    screen.update()
    screen.blend_mode(13)
    screen.rect(x-w/2,y,w,9)
    screen.level(10)
    screen.fill()
    screen.blend_mode(0)
    screen.level(0)
    screen.rect(x-w/2,y,w,10)
    screen.stroke()
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
  end
end

function redraw()
  screen.clear()
  tracks[params:get("track")]:redraw()

  screen.level(7)
  screen.rect(0,0,6,66)
  screen.fill()
  screen.level(0)
  screen.move(3,8)
  screen.text_center(params:get("track"))

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
    {id="kick_db",name="db adj",min=-96,max=16,exp=false,div=1,default=0.0,unit="db"},
    {id="preamp",name="preamp",min=0,max=4,exp=false,div=0.01,default=1,unit="amp"},
    {id="basenote",name="base note",min=10,max=200,exp=false,div=1,default=24,formatter=function(param) return musicutil.note_num_to_name(param:get(), true)end},
    {id="ratio",name="ratio",min=1,max=20,exp=false,div=1,default=6},
    {id="sweeptime",name="sweep time",min=0,max=200,exp=false,div=1,default=50,unit="ms"},
    {id="decay1",name="decay1",min=5,max=2000,exp=false,div=10,default=300,unit="ms"},
    {id="decay1L",name="decay1L",min=5,max=2000,exp=false,div=10,default=800,unit="ms"},
    {id="decay2",name="decay2",min=5,max=2000,exp=false,div=10,default=150,unit="ms"},
    {id="clicky",name="clicky",min=0,max=100,exp=false,div=1,default=0,unit="%"},
  }
  params:add_group("KICK",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
  end
end