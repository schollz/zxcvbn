-- zxcvbn
--
--
-- llllllll.co/t/zxcvbn
--
--
--
--    ▼ instructions below ▼

engine.name="Zxcvbn"
debounce_fn={}
osc_fun={}

function init()
  clock.run(function()
    while true do
      debounce_params()
      clock.sleep(1/15)
      redraw()
    end
  end)

  check_install()
end

function check_install()
  if is_installed() then
    clock.run(function()
      clock.sleep(1)
      ready_main()
    end)
  else
    show_message("press K3 to install",3000)
  end
end

function is_installed()
  -- choose audiowaveform binary
  audiowaveform="audiowaveform"
  local foo=util.os_capture(audiowaveform.." --help")
  if not string.find(foo,"Options") then
    audiowaveform="/home/we/dust/code/zxcvbn/lib/audiowaveform"
  end
  foo=util.os_capture(audiowaveform.." --help")
  if not string.find(foo,"Options") then
    do return false end
  end

  foo=util.os_capture("aubioonset --help")
  if not string.find(foo,"-minioi") then
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/aubiogo/aubiogo") then
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/oscconnect/oscconnect") then
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/oscnotify/oscnotify") then
    do return false end
  end
  return true
end

function do_install()
  clock.run(function()
    show_message_text="installing..."
    clock.sleep(1)
    os.execute("cd ".._path.code.."zxcvbn/lib/ && ./install.sh &")
    clock.sleep(1)

  end)
end

function ready_main()
  show_message("zxcvbn ready.",2)
  include("lib/runner")
  do_run()
  include("lib/runner_defs")
end

function enc(k,d)
end

function key(k,z)
  if k==3 and z==1 then
    do_install()
  end
end

function redraw()
  screen.clear()

  screen.level(15)
  screen.move(64,20)
  screen.font_face(18)
  screen.font_size(14)
  screen.text_center("zxcvbn")
  screen.font_size(8)
  screen.font_face(1)
  draw_message()

  screen.update()
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
