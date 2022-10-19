local Installer={}

function Installer:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Installer:init()
  self.blinky=0
  self.fade_in=0

end

function Installer:do_install()
  clock.run(function()
    show_message_text="installing..."
    clock.sleep(1)
    os.execute("cd ".._path.code.."zxcvbn/lib/ && chmod +x install.sh && ./install.sh")
    clock.sleep(1)
    check_install()
  end)
end

function Installer:is_installed()
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
  self.ready_to_go=true
  return true
end

function Installer:check_install()
  if self:is_installed() then
    clock.run(function()
      clock.sleep(1.1)
      init2()
    end)
  else
    show_message("press K3 to install",3000)
  end
end

function Installer:keyboard(k,v)
end

function Installer:enc(k,d)
end

function Installer:key(k,z)
  if k==3 and z==1 then
    if not self.ready_to_go then
      self:do_install()
    end
  end
end

function Installer:redraw()
  self.fade_in=self.fade_in+1
  self.fade_in=self.fade_in>15 and 15 or self.fade_in
  local x=self.fade_in/15
  screen.level(util.clamp(util.round(15*(math.exp(x*x*x)-1)),1,15))
  screen.move(64,20)
  screen.font_face(18)
  screen.font_size(14)
  screen.text_center("zxcvbn")
  screen.move(64,54)
  screen.font_face(17)
  screen.font_size(12)
  screen.text_center("a tracker for norns.")
  self.blinky=self.blinky-1
  self.blinky=self.blinky>-1 and self.blinky or 20
  screen.move(120,54)
  screen.text(self.blinky>7 and "|" or "")
  screen.font_size(8)
  screen.font_face(1)
  draw_message()
end

return Installer
