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
sample_=include("lib/sample")
sampler_=include("lib/sampler")
-- grid_=include("lib/ggrid")
-- track_=include("lib/track")
-- sequence_=include("lib/sequence")
MusicUtil=require "musicutil"
lattice=require("lattice")

debounce_fn={}

-- tab.print(sampler.samples["/home/we/dust/code/break-ops/lib/amenbreak_bpm136.wav"])
-- print(sampler.samples["/home/we/dust/code/break-ops/lib/amenbreak_bpm136.wav"]:get_render())
function init()
  sampler=sampler_:new()
  sampler:select(_path.code.."break-ops/lib/amenbreak_bpm136.wav")

  opi=1
  -- g_=grid_:new()
  --   local op={}
  --   for i=1,4 do
  --     table.insert(op,track_:new())
  --   end

  --   -- start lattice
  --   local sequencer=lattice:new{
  --     ppqn=96
  --   }
  --   divisions={1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16,1/2,1/4,1/8,1/16}
  --   for i=1,16 do
  --     local step=0
  --     sequencer:new_pattern({
  --       action=function(t)
  --         step=step+1
  --       end,
  --       division=divisions[i],
  --     })
  --   end
  --   sequencer:hard_restart()

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
