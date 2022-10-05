local ViewSelect={}

function ViewSelect:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  local osc_event=osc.event
  osc.event=function(path,args,from)
    osc_event(path,args,from)
    o.show_pos=args[2]
    o.show=1
  end
  o:init()
  return o
end

function ViewSelect:init()
  self.is_playing=false
  self.k3_held=0
  self.k3_hold_time=20
  self.k3_hold_min=5
  self.debounce_regen=0
  self.audiowaveform="/home/we/dust/code/zxcvbn/lib/audiowaveform"
  self.path_to_pngs=_path.data.."zxcvbn/pngs/"

  local foo=util.os_capture(self.audiowaveform.." --help")
  if not string.find(foo,"Options") then
    self.audiowaveform="audiowaveform"
  end
  self:regen("/home/we/dust/audio/")
end

function ViewSelect:regen(path)
  self.current_folder=path
  self.ls=self:list_all(self.current_folder)
  self.view={1,6}
  self.current=1
end

function ViewSelect:split_path(path)
  local pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  return pathname,filename,ext
end

function ViewSelect:split(inputstr,sep)
  if sep==nil then
    sep="%s"
  end
  local t={}
  for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t
end

function ViewSelect:list_folders(path)
  local folder_string=util.os_capture("find "..path.." -maxdepth 1 -type d | tail -n +2 | sort")
  local cur_path=self:split(path,"/")
  local path_back=""
  for i=1,#cur_path-1 do
    path_back=path_back.."/"..cur_path[i]
  end
  local folders={{path_back.."/","../"}}
  for s in folder_string:gmatch("%S+") do
    -- trim string
    local s2=(s:gsub("^%s*(.-)%s*$","%1"))
    if s2~="" then
      _,foldername,_=self:split_path(s2)
      s2=s2.."/"
      table.insert(folders,{s2,foldername.."/"})
    end
  end
  return folders
end

function ViewSelect:list_files(path)
  local folder_string=util.os_capture("find "..path.." -maxdepth 1 -type f -name '*.wav' -o -name '*.flac' | sort")
  local files={}
  for s in folder_string:gmatch("%S+") do
    -- trim string
    local s2=(s:gsub("^%s*(.-)%s*$","%1"))
    if s2~="" then
      _,filename,_=self:split_path(s2)
      table.insert(files,{s,filename})
    end
  end
  return files
end

function ViewSelect:list_all(path)
  local files=self:list_folders(path)
  for _,v in ipairs(self:list_files(path)) do
    table.insert(files,v)
  end
  return files
end

function ViewSelect:keyboard(code,value)
  print(code,value)
  if code=="DOWN" and value>0 then
    self:enc(2,1)
  elseif code=="UP" and value>0 then
    self:enc(2,-1)
  elseif code=="ENTER" then
    if self.doing_load~=nil then
      if value==0 then
        self.doing_load=nil
      end
      do return end
    end
    if self.k3_held==0 and value>0 then
      self:key(3,1)
    elseif self.k3_held>0 and value==0 then
      self:key(3,0)
    end
  elseif code=="BACKSPACE" and value==1 then
    self:key(2,1)
  end
end

function ViewSelect:enc(k,d)
  if k==2 then
    if d==0 then
      do return end
    end
    local current=self.current+(d>0 and 1 or-1)
    if current>#self.ls then
      current=1
    elseif current<1 then
      current=#self.ls
    end
    self.current=current
    if self.current>self.view[2] then
      self.view[2]=self.current
      self.view[1]=self.view[2]-5
    elseif self.current<self.view[1] then
      self.view[1]=self.current
      self.view[2]=self.view[1]+5
    end
    self.debounce_regen=5
  end
end

function ViewSelect:key(k,z)
  if k==3 then
    if z==1 then
      self.k3_held=1
    else
      if self.k3_held<self.k3_hold_min then
        if string.sub(self.ls[self.current][1],-1)=="/" then
          print(self.ls[self.current][1])
          self:regen(self.ls[self.current][1])
        else
          self:audition(not self.is_playing)
        end
      end
      self.k3_held=0
    end
  elseif k==2 and z==1 then
    self:regen(self.ls[1][1])
  end
end

function ViewSelect:audition(on)
  if on then
    if self.path~=nil then
      engine.audition_on(self.path,0,self.duration)
    end
  else
    engine.audition_off()
  end
  self.is_playing=on
end

function ViewSelect:get_render(path)
  print("getting render for "..path)
  self.path=path
  self.pathname,self.filename,self.ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.path_to_dat=_path.data.."zxcvbn/dats/"..self.filename..".dat"
  if not util.file_exists(self.path_to_dat) then
    local cmd=string.format("%s -q -i %s -o %s -z %d -b 8",self.audiowaveform,self.path,self.path_to_dat,2)
    print(cmd)
    os.execute(cmd)
  end
  print("getting audio file info",self.path)
  self.ch,self.samples,self.sample_rate=audio.file_info(self.path)
  if self.samples<10 or self.samples==nil then
    print("ERROR PROCESSING FILE: "..path)
    do return end
  end
  self.duration=self.samples/self.sample_rate
  print("duration",self.duration)

  self.width=120
  self.height=16
  local view={0,self.duration}
  local path_to_rendered=string.format("%s%s_%3.3f_%3.3f_%d_%d.png",self.path_to_pngs,self.filename,view[1],view[2],self.width,self.height)
  if not util.file_exists(path_to_rendered) then
    local cmd=string.format("%s -q -i %s -o %s -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.audiowaveform,self.path_to_dat,path_to_rendered,view[1],view[2],self.width,self.height)
    print(cmd)
    os.execute(cmd)
  end
  self.path_to_rendered=path_to_rendered
end

function ViewSelect:set_pos(x)
  self.show_pos=x
  self.show=7
end

function ViewSelect:redraw()
  if self.ls==nil then
    do return end
  end
  if self.k3_held>0 then
    self.k3_held=self.k3_held+1
    if self.k3_held==self.k3_hold_min then
      show_message("loading "..self.ls[self.current][2],2)
    elseif self.k3_held>self.k3_hold_min then
      show_progress((self.k3_held-self.k3_hold_min)/(self.k3_hold_time-self.k3_hold_min)*100)
    end
    if self.k3_held==self.k3_hold_time then
      if string.sub(self.ls[self.current][1],-1)~="/" then
        print(self.ls[self.current][1])
        self.k3_held=0
        self.doing_load=true
        clock.run(function()
          show_message("loading... ",4)
          show_progress(100)
          clock.sleep(0.5)
          params:set(params:get("track").."sample_file",self.ls[self.current][1])
          clock.sleep(0.5)
          tracks[self.id].state=2
        end)
      end
    end
  end
  if self.debounce_regen>0 then
    self.debounce_regen=self.debounce_regen-1
    if self.debounce_regen==0 then
      if self.is_playing then
        print("stopping")
        self.is_playing=false
      end
      if string.sub(self.ls[self.current][1],-1)~="/" then
        print("loading",self.ls[self.current][1])
        self:get_render(self.ls[self.current][1])
      end
    end
  end
  for i=self.view[1],self.view[2] do
    local j=i-self.view[1]+1
    screen.level(self.current==i and 15 or 2)
    screen.move(1+7,j*7+7)
    if self.ls[i]~=nil and self.ls[i][2]~=nil then
      screen.text(self.ls[i][2])
    end
  end
  if self.path_to_rendered~=nil then
    screen.display_png(self.path_to_rendered,7,50)
  end
  if self.show~=nil and self.show>0 then
    self.show=self.show-1
    if self.show==0 then
      self.is_playing=false
    end
    local pos=util.linlin(0,self.duration,7,128,self.show_pos)
    screen.aa(1)
    screen.level(self.show*2+1)
    screen.move(pos,64-self.height+1)
    screen.line(pos,64)
    screen.stroke()
    screen.aa(0)
  end

  screen.level(5)
  screen.move(8,6)
  screen.text("load sample")
  screen.blend_mode(1)
  screen.level(5)
  screen.rect(7,0,128,7)
  screen.fill()
  screen.blend_mode(0)

  return self.current_folder:gsub("/home/we/dust/","")
end

return ViewSelect
