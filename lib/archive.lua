local Archive={}

function Archive:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Archive:init()
  self.trim=function(s)
    return (s:gsub("^%s*(.-)%s*$","%1"))
  end

  self.fields=function(s)
    local foo={}
    for w in s:gmatch("%S+") do
      table.insert(foo,w)
    end
    return foo
  end

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

  self.path_split=function(path)
    local pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    return pathname,filename,ext
  end

  self.lines_from=function(s)
    local lines={}
    for line in s:gmatch("[^\r\n]+") do
      line=self.trim(line)
      if #line>0 then
        table.insert(lines,line)
      end
    end
    return lines
  end

  os.execute("mkdir -p ".._path.data.."zxcvbn/archives")

  local pset_options={"select"}
  for _,v in ipairs(self:get_psets()) do
    table.insert(pset_options,v)
  end
  params:add_option("sel_pset","pset",pset_options)
  params:add{type="binary",name="make archive",id="make_archive",behavior="mometary",action=function(v)
    self:make_archive(params:get("sel_pset")-1)
  end}
  local archive_name=self:make_archive(1)
  self:load_archive(archive_name)
end

function Archive:load_archive(name)
  print("loading archive: "..name)
  local path=_path.data.."zxcvbn/archives/"..name
  if not util.file_exists(path) then
    print("loading archive: archive not found")
    do return end
  end
end

function Archive:make_archive(pset_num)
  if pset_num<1 then
    do return end
  end
  local fname=string.format("/home/we/dust/data/zxcvbn/zxcvbn-%02d.pset",pset_num)
  if not util.file_exists(fname) then
    do return end
  end
  local name=util.os_capture(string.format("sha256sum /home/we/dust/data/zxcvbn/zxcvbn-%02d.pset | head -c 8",pset_num))..".zip"
  self:dump(name,string.format("zxcvbn-%02d.pset",pset_num))

  print("made archive "..name)
  return name
end

function Archive:dump(fname,pset)
  local path_final=_path.data.."zxcvbn/archives/"..fname
  local path=_path.data.."zxcvbn/"..fname
  if util.file_exists(path_final) then
    os.execute("cp "..path_final.." "..path)
  end

  local pset_lines=self:package_psets(fname,pset)

  for i,v in ipairs(pset_lines) do
    if string.find(v,"sample_file") and
      (string.find(v,".wav") or string.find(v,".flac")) then
      local foo=self.string_split(v,":")
      self:package_audio(fname,foo[2])
    end
  end

  os.execute("mv "..path.." ".._path.data.."zxcvbn/archives")
end

function Archive:package_audio(fname,path)
  local pathname,filename,ext=self.path_split(path)
  pathname=self.trim(pathname)
  local s=util.os_capture(string.format("cd %s && find * -name '%s*' -type f",_path.data.."zxcvbn",filename))
  local audio_files=self.fields(s)
  for _,v in ipairs(audio_files) do
    if pathname~="/home/we/dust/data/zxcvbn/samples/" then
      os.execute(string.format("cp %s /home/we/dust/data/zxcvbn/samples/",path))
    end
    os.execute(string.format("cd %s && zip %s -u %s",_path.data.."zxcvbn",fname,v))
  end
end

function Archive:package_psets(fname,pset)
  local s=util.os_capture(string.format("cd %s && find * -name '%s*' -type f",_path.data.."zxcvbn",pset))
  local pset_files=self.fields(s)
  local pset_lines={}
  for _,v in ipairs(pset_files) do
    local f=v:sub(11)
    pset_lines=self:remake_pset(v,f) or pset_lines
    os.execute(string.format("cd %s && zip %s -u %s",_path.data.."zxcvbn",fname,f))
  end
  return pset_lines
end

function Archive:get_lines(fname)
  local file=io.open(fname)
  local lines={}
  for line in file:lines() do
    table.insert(lines,line)
  end
  io.close(file)
  return lines
end

function Archive:get_psets()
  local s=util.os_capture(string.format("cd %s && find * -name '*.pset' -type f",_path.data.."zxcvbn"))
  local psets={}
  for _,v in ipairs(self.fields(s)) do
    local ss=util.os_capture(string.format("cd %s && head -n1 %s",_path.data.."zxcvbn",v))
    local foo=string.split(v,".pset")
    foo=string.split(foo[1],"-")
    local num=tonumber(foo[#foo])
    local foo=self.fields(ss)
    psets[num]=string.format("(%02d) %s",num,foo[2])
  end
  return psets
end

function Archive:get_archives()
  local s=util.os_capture(string.format("cd %s && find * -name '*.zip' -type f",_path.data.."zxcvbn"))
  return self.fields(s)
end

function Archive:get_list(fname)
  local s=util.os_capture(string.format("cd %s && zipinfo -1 %s",_path.data.."zxcvbn",fname))
  return self.fields(s)
end

function Archive:remake_pset(fname,fname2)
  if not string.find(fname,".json") then
    local lines=self:get_lines(_path.data.."zxcvbn/"..fname)

    for i,v in ipairs(lines) do
      if string.find(v,"sample_file") and
        (string.find(v,".wav") or string.find(v,".flac")) then
        local foo=self.string_split(v,":")
        local _,old_fname,_=self.path_split(foo[2])
        lines[i]=string.format("%s: /home/we/dust/data/zxcvbn/samples/%s",foo[1],old_fname)
      end
    end

    f=io.open(_path.data.."zxcvbn/"..fname2,"w")
    io.output(f)
    io.write(table.concat(lines,"\n"))
    io.close()
    do return lines end
  else
    os.execute(string.format("cd %s && cp %s %s",_path.data.."zxcvbn",fname,fname2))
  end
end

return Archive
