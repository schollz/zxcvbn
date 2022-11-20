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
  os.execute("mkdir -p ".._path.data.."zxcvbn/samples")
  params:add_file("load_archive","load archive",_path.data.."zxcvbn/archives/")
  params:set_action("load_archive",function(x)
    if string.find(x,".zip") then
      _,fname,_=self.path_split(x)
      self:load_archive(fname)
      params:set("archive_info","loaded "..fname)
    end
  end)
  params:add{type="binary",name="make archive",id="make_archive",behavior="toggle",action=function(v)
    print("make_archive",v)
    if v==1 then
      params:set("make_archive",0,false)
      params:set("archive_info","")
      params:set("load_archive",_path.data.."zxcvbn/archives/",true)
      local fname=self:make_archive()
      if fname~=nil then
        params:set("archive_info","saved "..fname)
        params:set("make_archive",0,true)
      end
    end
  end}
  params:add_text("archive_info","","")
end

function Archive:load_archive(name)
  print("loading archive: "..name)
  local path=_path.data.."zxcvbn/archives/"..name
  if not util.file_exists(path) then
    print("loading archive: archive not found")
    do return end
  end
  os.execute("cp "..path.." ".._path.data.."zxcvbn/")
  os.execute("cd ".._path.data.."zxcvbn".." && unzip -o "..name)
  os.execute("rm ".._path.data.."zxcvbn/"..name)
  params:read(_path.data.."zxcvbn/temp_pset")
end

function Archive:make_archive()
  local temp_pset="/home/we/dust/data/zxcvbn/temp_pset"
  params:write(temp_pset)
  local name=util.os_capture(string.format("cat %s | sha256sum | head -c 8",temp_pset,pset_num))..".zip"
  self:dump(name,"temp_pset")
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
      (string.find(v,".wav") or string.find(v,".flac") or string.find(v,".aif")) then
      local foo=self.string_split(v,":")
      self:package_audio(fname,foo[2])
    end
  end

  self:package_tapes(fname)

  os.execute("mv "..path.." ".._path.data.."zxcvbn/archives")
end

function Archive:package_audio(fname,path)
  local pathname,filename,ext=self.path_split(path)
  os.execute(string.format("cd %s && zip %s -u samples/%s",_path.data.."zxcvbn",fname,filename))
  -- pathname=self.trim(pathname)
  -- local s=util.os_capture(string.format("cd %s && find * -name '%s*' -type f",_path.data.."zxcvbn",filename))
  -- local audio_files=self.fields(s)
  -- for _,v in ipairs(audio_files) do
  --   if pathname~="/home/we/dust/data/zxcvbn/samples/" then
  --     os.execute(string.format("cp %s /home/we/dust/data/zxcvbn/samples/",path))
  --   end
  --   os.execute(string.format("cd %s && zip %s -u %s",_path.data.."zxcvbn",fname,v))
  -- end
end

function Archive:package_psets(fname,pset)
  local s=util.os_capture(string.format("cd %s && find * -name '%s*' -type f",_path.data.."zxcvbn",pset))
  local pset_files=self.fields(s)
  local pset_lines={}
  local pset_lines=self:remake_pset(pset)
  for _,v in ipairs({pset,pset..".json"}) do
    os.execute(string.format("cd %s && zip %s -u %s",_path.data.."zxcvbn",fname,v))
  end
  return pset_lines
end

function Archive:package_tapes(fname)
  local cmd=string.format("cd %s && find * -name '%s*' -type f",_path.data.."zxcvbn/tapes",params:get("random_string"))
  print(cmd)
  local s=util.os_capture(cmd)
  local files=self.fields(s)
  for _,v in ipairs(files) do
    os.execute(string.format("cd %s && zip %s -u tapes/%s",_path.data.."zxcvbn",fname,v))
  end
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

function Archive:remake_pset(fname)
  local lines=self:get_lines(_path.data.."zxcvbn/"..fname)

  for i,v in ipairs(lines) do
    if string.find(v,"sample_file") and
      (string.find(v,".wav") or string.find(v,".flac") or string.find(v,".aif")) then
      local foo=self.string_split(v,":")
      local _,old_fname,_=self.path_split(foo[2])
      lines[i]=string.format("%s: /home/we/dust/data/zxcvbn/samples/%s",foo[1],old_fname)
      -- copy over the sample to the samples folder
      local cmd=string.format("cp %s /home/we/dust/data/zxcvbn/samples/%s",foo[2],old_fname)
      print(cmd)
      os.execute(cmd)
    end
  end

  local f=io.open(_path.data.."zxcvbn/"..fname,"w")
  io.output(f)
  io.write(table.concat(lines,"\n"))
  io.close()
  do return lines end
end

return Archive
