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

  self.string_split=function(input_string,split_character)
    local s=split_character~=nil and split_character or "%s"
    local t={}
    if split_character=="" then
      for str in string.gmatch(input_string,".") do
        table.insert(t,str)
      end
    else
      for str in string.gmatch(input_string,"([^"..s.."]+)") do
        table.insert(t,str)
      end
    end
    return t
  end

  self.normalize_path=function(s)
    local path_split=self.string_split(s,"/")
    local t={}
    for _,v in ipairs(path_split) do
      if v==".." then
        if next(t)~=nil then
          table.remove(t,#t)
        end
      elseif v=="." then
      else
        table.insert(t,v)
      end
    end
    return (string.sub(s,1,1)=="/" and "/" or "")..table.concat(t,"/")
  end

  self.cache={}
  self.attempting_render={}
  self.attempting_render2={}
  self.is_playing=false
  self.k3_held=0
  self.k3_hold_time=20
  self.k3_hold_min=5
  self.debounce_regen=0
  self.path_to_pngs=_path.data.."zxcvbn/pngs/"
  self:regen("/home/we/dust/audio/")
end

function ViewSelect:regen(path)
  path=self.normalize_path(path)
  if self.current_folder~=nil then
    self.cache[self.current_folder]={}
    self.cache[self.current_folder].current_folder=self.current_folder
    self.cache[self.current_folder].ls=json.decode(json.encode(self.ls))
    self.cache[self.current_folder].view=json.decode(json.encode(self.view))
    self.cache[self.current_folder].current=json.decode(json.encode(self.current))
    tab.print(self.cache[self.current_folder])
  end
  if self.cache[path]~=nil then
    print("[viewselect] getting list from cache")
    tab.print(self.cache[path])
    self.current_folder=self.cache[path].current_folder
    self.ls=self.cache[path].ls
    self.view=self.cache[path].view
    self.current=self.cache[path].current
  else
    self.current_folder=path
    self.ls=self:list_all(self.current_folder)
    self.view={1,6}
    self.current=1
  end
  self.debounce_regen=2
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
  local folder_string=util.os_capture("find "..path.." -maxdepth 1 -not -empty -type d | tail -n +2 | sort",true)
  local cur_path=self:split(path,"/")
  local folders={}
  for s in folder_string:gmatch('[^\r\n]+') do
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
  local folder_string=util.os_capture("find "..path.." -maxdepth 1 -type f -name '*.wav' -o -name '*.flac' -o -name '*.aif' | sort",true)
  local files={}
  for s in folder_string:gmatch('[^\r\n]+') do
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
      print("[viewselect] generating list for "..path)
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
  elseif code=="LEFT" and value==1 then
    self:regen(self.current_folder.."/../")
  elseif code=="RIGHT" and value==1 then
    if string.sub(self.ls[self.current][1],-1)=="/" then
      self:regen(self.ls[self.current][1])
    else
      self:audition(not self.is_playing)
    end
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
    self.debounce_regen=2
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
    self:regen(self.current_folder.."/../")
  end
end

function ViewSelect:audition(on)
  print("audition",on)
  if on then
    print(self.path,0,self.duration)
    if self.path~=nil then
      engine.audition_on(self.path)
    end
  else
    engine.audition_off()
  end
  self.is_playing=on
end

function ViewSelect:get_render()
  if self.path_to_render==nil then
    do return end
  end
  local path=self.path_to_render
  self.path=path
  if (self.path_to_dat==nil or not util.file_exists(self.path_to_dat)) and
    self.attempting_render[self.path]==nil then
    print("attemping render")
    self.attempting_render[self.path]=true
    self.attempting_render2[self.path]=nil
    self.pathname,self.filename,self.ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    self.path_to_dat=_path.data.."zxcvbn/dats/"..self.filename..".dat"
    if not util.file_exists(self.path_to_dat) then
	    local delete_temp=false
	    local filename=self.path
	    if self.ext=="aif" then 
		    print(util.os_capture(string.format("sox '%s' '%s'",filename,filename..".wav")))
		    filename=filename..".wav"
		    delete_temp=true
	    end
      local cmd=string.format("%s -q -i '%s' -o '%s' -z %d -b 8 &",audiowaveform,filename,self.path_to_dat,2)
      print(cmd)
      os.execute(cmd)
      if delete_temp then 
	      debounce_fn["rm_"..filename]={45,function() os.execute("rm "..filename) end}
      end
    end
  elseif self.attempting_render[self.path]==true and util.file_exists(self.path_to_dat) and self.attempting_render2[self.path]==nil then
    self.attempting_render[self.path]=nil
    self.attempting_render2[self.path]=true

    self.width=120
    self.height=16
    local path_to_rendered=string.format("%s%s_%d_%d.png",self.path_to_pngs,self.filename,self.width,self.height)

    self.ch,self.samples,self.sample_rate=audio.file_info(self.path)
    if self.samples<10 or self.samples==nil then
      print("ERROR PROCESSING FILE: "..path)
      do return end
    end
    self.duration=self.samples/self.sample_rate
    if not util.file_exists(path_to_rendered) then
      local view={0,self.duration}
      local cmd=string.format("%s -q -i '%s' -o '%s' -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0 &",audiowaveform,self.path_to_dat,path_to_rendered,view[1],view[2],self.width,self.height)
      print(cmd)
      os.execute(cmd)
    end
    self.path_to_render_ready=path_to_rendered
  elseif self.path_to_render_ready~=nil and util.file_exists(self.path_to_render_ready) then
    self.path_to_rendered=self.path_to_render_ready
  end
  return self.path_to_rendered
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
      show_message(string.format("[%d] loading",self.id),2)
    elseif self.k3_held>self.k3_hold_min then
      show_progress((self.k3_held-self.k3_hold_min)/(self.k3_hold_time-self.k3_hold_min)*100)
    end
    if self.k3_held==self.k3_hold_time then
      if string.sub(self.ls[self.current][1],-1)~="/" then
        print(self.ls[self.current][1])
        self.k3_held=0
        self.doing_load=true
        clock.run(function()
          show_message(string.format("[%d] loading...",self.id),2)
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
      print(json.encode(self.ls))
      if string.sub(self.ls[self.current][1],-1)~="/" then
        self.path_to_render=self.ls[self.current][1]
        self.path_to_dat=nil
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
  local render_f=self:get_render()
  if render_f~=nil then
    screen.display_png(render_f,7,50)
  end
  if self.show~=nil and self.show>0 then
    self.show=self.show-1
    if self.show==0 then
      self.is_playing=false
    end
    if self.show_pos~=nil and self.duration~=nil then
      local pos=util.linlin(0,self.duration,7,128,self.show_pos)
      screen.aa(1)
      screen.level(self.show*2+1)
      screen.move(pos,64-self.height+1)
      screen.line(pos,64)
      screen.stroke()
      screen.aa(0)
    end
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
