-- break ops
--
--
-- llllllll.co/t/break ops
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
sequence_tli_=include("lib/sequence_tli")
grid_=include("lib/ggrid")
MusicUtil=require "musicutil"
lattice=require("lattice")
sequins=require("sequins")

-- debouncer
debounce_fn={}

-- initialize the engine
engine.name="BreakOps"

-- global division definitions
possible_divisions={1/32,1/24,1/16,1/12,1/8,1/6,1/4,1/3,1/2,1,2,4}
possible_division_options={"1/32","1/24","1/16","1/12","1/8","1/6","1/4","1/3","1/2","1","2","4"}

function init()
  params:set("clock_tempo",136)

  -- start the sampler
  sampler=sampler_:new()

  -- start the TLI sequences
  tli_sequences=sequence_tli_:new()

  -- setup osc
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

  -- setup params
  params_kick()

  -- setup grid
  g_=grid_:new()
  params:add{type="binary",name="record",id="record",behavior="toggle"}

  -- start lattice
  local sequencer=lattice:new{}
  for _,division in ipairs(possible_divisions) do
    local step=0
    sequencer:new_pattern({
      action=function(t)
        step=step+1
        sampler:emit(division,step)
        tli_sequences:emit(division,step)
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

  clock.run(function()
    clock.sleep(1)
    print("DEBUG MODE")

    -- sample1=_path.code.."break-ops/lib/amenbreak_bpm136.wav"
    -- params:set("1sample_file",sample1)

    -- params:set("1tli_file",_path.code.."break-ops/test.tli")
    -- params:set("1tli_play",1)
  end)

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

function params_kick()

  -- kick
  local params_menu={
    {id="kick_db",name="db adj",min=-96,max=96,exp=false,div=1,default=0.0,unit="db"},
    {id="preamp",name="preamp",min=0,max=4,exp=false,div=0.01,default=1,unit="amp"},
    {id="basefreq",name="base freq",min=10,max=200,exp=false,div=0.1,default=32.7,unit="Hz"},
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
    -- params:set_action(pram.id,function(x)
    --   if string.find(pram.id,"euc")~=nil then
    --     debounce_fn["euc"]={
    --       1,function()
    --         update_euclidean()
    --       end
    --     }
    --   end
    -- end)
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

  -- g_:redraw()

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
  screen.text_center(string.format("%02d",111))

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
