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

-- global division definitions
possible_divisions={1/32,1/24,1/16,1/12,1/8,1/6,1/4,1/3,1/2,1,2,4}
possible_division_options={"1/32","1/24","1/16","1/12","1/8","1/6","1/4","1/3","1/2","1","2","4"}

-- debouncer
debounce_fn={}

engine.name="Zxcvbn"

function init()
  os.execute(_path.code.."zxcvbn/lib/oscnotify/run.sh &")

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

  params:set("1sample_file",_path.code.."zxcvbn/lib/amenbreak_bpm136.wav")
  -- params:set("1sample_file",_path.code.."zxcvbn/lib/60.3.3.1.0.wav")
  tracks[1]:parse_tli()
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
