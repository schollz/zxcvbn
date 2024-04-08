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
  self.k3debounce=true
  self.fade_in=0
  show_message("v2.4.0",3000)
end

function Installer:do_install()
  self.doing_install=true
  clock.run(function()
    show_message_text="installing..."
    clock.sleep(1)
    local install_results=util.os_capture("cd ".._path.code.."zxcvbn/lib/ && chmod +x install.sh && ./install.sh")
    clock.sleep(1)
    if string.find(install_results,"dpkg was interrupted") then 
      print("correcting installation...")
      os.execute("sudo dpkg --configure -a")      
      clock.sleep(1)
      os.execute("sudo apt-get install -y --no-install-recommends libavcodec-dev libavformat-dev")
      clock.sleep(1)
    end
    self:check_install()
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
    print("INSTALL NEEDED: libavcaudiowaveformodec")
    do return false end
  end

  local foo=util.os_capture("/sbin/ldconfig -p | grep libavcodec")
  if not string.find(foo,"libavcodec.so") then 
    print("INSTALL NEEDED: libavcodec")
    do return false end
  end

  local foo=util.os_capture("/sbin/ldconfig -p | grep libavformat")
  if not string.find(foo,"libavformat.so") then 
    print("INSTALL NEEDED: libavformat")
    do return false end
  end

  foo=util.os_capture("aubioonset --help")
  if not string.find(foo,"-minioi") then
    print("INSTALL NEEDED: aubioonset")
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/aubiogo/aubiogo") then
    print("INSTALL NEEDED: aubiogo")
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/acrostic/acrostic") then
    print("INSTALL NEEDED: acrostic")
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/oscconnect/oscconnect") then
    print("INSTALL NEEDED: oscconnect")
    do return false end
  end

  if not util.file_exists(_path.code.."zxcvbn/lib/oscnotify/oscnotify") then
    print("INSTALL NEEDED: oscnotify")
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
  self.k3debounce=false
end

function Installer:keyboard(k,v)
end

function Installer:enc(k,d)
end

function Installer:key(k,z)
  if self.doing_install or self.k3debounce then
    do return end
  end
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
  screen_fade_in=util.clamp(util.round(15*(math.exp(x*x*x)-1)),1,15)
  screen.level(screen_fade_in)
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
