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
  self.k3_held=0
  self.k3_hold_time=20
  self.k3_hold_min=5
  self.debounce_regen=0
  self:regen("/home/we/dust/audio/")
end

function ViewSelect:regen(path)
  self.current_folder=path
  self.ls=self:list_all(self.current_folder)
  -- for _,v in ipairs(self.ls) do
  --   print(v[1],v[2])
  -- end
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
  local folder_string=util.os_capture("find "..path.." -maxdepth 1 -type f -name '*.wav' | sort")
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
          if self.is_playing then
            print("stopping")
          else
            -- TODO: Play
          end
        end
      end
      self.k3_held=0
    end
  elseif k==2 and z==1 then
    self:regen(self.ls[1][1])
  end
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
        self.load_sample(self.ls[self.current][1])
        show_message("loaded "..self.ls[self.current][2])
        show_progress(100)
      end
    end
  end
  if self.debounce_regen>0 then
    self.debounce_regen=self.debounce_regen-1
    if self.debounce_regen==0 then
      if self.is_playing then
        print("stopping")
      end
      if string.sub(self.ls[self.current][1],-1)~="/" then
        print("loading",self.ls[self.current][1])
      end
    end
  end
  for i=self.view[1],self.view[2] do
    local j=i-self.view[1]+1
    screen.level(self.current==i and 15 or 2)
    screen.move(1,7+j*7)
    if self.ls[i]~=nil and self.ls[i][2]~=nil then
      screen.text(self.ls[i][2])
    end
  end
  return self.current_folder:gsub("/home/we/dust/","")
end

return ViewSelect
