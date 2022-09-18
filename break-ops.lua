-- break ops
--
--
-- llllllll.co/t/lightsout
--
--
--
--    ▼ instructions below ▼

if not string.find(package.cpath,"/home/we/dust/code/break-ops/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/break-ops/lib/?.so"
end
json=require("cjson")
tli_=include("lib/tli")
tli=tli_:new()
sample_=include("lib/sample")
sampler_=include("lib/sampler")
-- grid_=include("lib/ggrid")
-- track_=include("lib/track")
-- sequence_=include("lib/sequence")
MusicUtil=require "musicutil"
lattice=require("lattice")
sequins=require("sequins")

debounce_fn={}

engine.name="BreakOps"

-- tab.print(sampler.samples["/home/we/dust/code/break-ops/lib/amenbreak_bpm136.wav"])
-- print(sampler.samples["/home/we/dust/code/break-ops/lib/amenbreak_bpm136.wav"]:get_render())
-- sampler.samples["/home/we/dust/code/break-ops/lib/amenbreak_bpm136.wav"]:play(1,1,0.5,1,1,1)
function init()
  params:set("clock_tempo",136)
  sampler=sampler_:new()
  sample1=_path.code.."break-ops/lib/amenbreak_bpm136.wav"
  sampler:load(1,sample1)
  -- sampler:select("/home/we/dust/audio/seamlessloops/120/TL_Loop_Pad_Lo-Fi_01_Cm_120_keyCmin_bpm120_beats32_.flac")

  osc_fun={
    progress=function(args)
      sampler:show_position(tonumber(args[1]))
    end,
  }
  osc.event=function(path,args,from)
    if osc_fun[path]~=nil then osc_fun[path](args) else
      print("osc.event: "..path.."?")
    end
  end

  opi=1
  -- g_=grid_:new()
  --   local op={}
  --   for i=1,4 do
  --     table.insert(op,track_:new())
  --   end
  pat=tli:parse_tli([[
# ignore this
 
chain a b a b c
 
pattern=a
Am/C
C/G
Dm
F/C
- 
- - - .
 
 
pattern=b division=8
c4 d4 - - - - - . .
e5 . . .
 
]])

  -- start lattice
  local sequencer=lattice:new{}
  seq={1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
  ss=sequins{1,1,2,1,1,1,2,4,1,1,2,1,1,2,4,8}
  pitches=sequins{0,0,0,0,0,0,1,2,3,4,5,0,0,0,0,0,-2,-4,-6,-8}
  gates=sequins{1,1,1,1,1,0.2,0.5,0.5,1,1,1,1}
  divisions={1/32,1/24,1/16,1/12,1/8,1/6,1/4,1/3,1/2,1,2,4}
  for _,division in ipairs(divisions) do
    local step=0
    sequencer:new_pattern({
      action=function(t)
        step=step+1
        -- if division==1/8 then
        --   local slice=seq[(step-1)%#seq+1]
        --   sampler.samples[sample1]:play_cursor(slice,1,pitches(),gates(),ss(),4)

        --   local notes=pat.patterns.a.parsed
        --   print((step-1)%#notes+1)
        --   local off=notes[(step-1)%#notes+1].off
        --   if next(off)~=nil then
        --     for _,n in ipairs(off) do
        --       print("off",n.m)
        --       engine.note_off(n.m)
        --     end
        --   end
        --   local on=notes[(step-1)%#notes+1].on
        --   if next(on)~=nil then
        --     for _,n in ipairs(on) do
        --       print("on",n.m)
        --       engine.note_on(n.m)
        --     end
        --   end
        -- end
      end,
      division=division,
    })
  end
  sequencer:hard_restart()

  clock.run(function()
    while true do
      debounce_params()
      redraw()
      clock.sleep(1/10)
    end
  end)

  -- debounce_fn[i.."crow"]={
  --     5,function()
  --       crow.output[i].action=string.format("adsr(%3.3f,%3.3f,%3.3f,%3.3f,'linear')",
  --       params:get(i.."crow_attack"),params:get(i.."crow_sustain"),params:get(i.."crow_decay"),params:get(i.."crow_release"))
  --     end,
  --   }

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
  sampler:enc(k,d)
end

function key(k,z)
  -- if k==2 then
  --   if z==1 then
  --     engine.note_on(60);engine.note_on(65);engine.note_on(69);engine.note_on(60-12)
  --   else
  --     engine.note_off(60);engine.note_off(65);engine.note_off(69);engine.note_off(60-12)
  --   end
  -- end
  sampler:key(k,z)
end

function redraw()
  screen.clear()

  local title=sampler:redraw()
  if title~=nil then
    screen.level(15)
    screen.move(12,6)
    screen.text(title)
    screen.blend_mode(1)
    screen.level(9)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.rect(0,0,11,7)
    screen.fill()
  end
  screen.level(15)
  screen.move(4,6)
  screen.text_center(string.format("%02d",opi))
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
