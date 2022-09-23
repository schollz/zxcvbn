local Sample={}

function Sample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sample:init()
  self.dec_to_hex={"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
  if not util.file_exists(_path.data.."zxcvbn/dats/") then
    os.execute("mkdir -p ".._path.data.."zxcvbn/dats/")
    os.execute("mkdir -p ".._path.data.."zxcvbn/cursors/")
    os.execute("mkdir -p ".._path.data.."zxcvbn/pngs/")
  end
  self.path_to_pngs=_path.data.."zxcvbn/pngs/"

  -- initialize debouncer
  self.debounce_fn={}

  -- choose audiowaveform binary
  self.audiowaveform="/home/we/dust/code/zxcvbn/lib/audiowaveform"
  local foo=util.os_capture(self.audiowaveform.." --help")
  if not string.find(foo,"Options") then
    self.audiowaveform="audiowaveform"
  end
end

function Sample:load_sample(path,is_melodic)
  print("sample: load_sample "..path)
  self.path=path
  -- load sample
  print("sample: init "..self.path)
  self.pathname,self.filename,self.ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.ch,self.samples,self.sample_rate=audio.file_info(self.path)
  if self.samples<10 or self.samples==nil then
    print("ERROR PROCESSING FILE: "..path)
    do return end
  end
  self.duration=self.samples/self.sample_rate
  self.ci=1
  self.view={0,self.duration}
  self.height=56
  self.width=120
  self.debounce_zoom=0

  -- create dat file
  self.path_to_dat=_path.data.."zxcvbn/dats/"..self.filename..".dat"
  if not util.file_exists(self.path_to_dat) then
    local cmd=string.format("%s -q -i %s -o %s -z %d -b 8",self.audiowaveform,self.path,self.path_to_dat,2)
    os.execute(cmd)
  end

  self.is_melodic=is_melodic
  if not is_melodic then
    self.cursors=self:get_onsets(self.path,self.duration)
    self.cursor_durations={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  else
    self.cursors={0,self.duration*0.6,self.duration*0.8,self.duration-0.1}
    self.cursor_durations={0,0,0,0}
  end
  engine.load_buffer(self.path)
  self.loaded=true
end

function Sample:get_onsets(fname,duration)
  self.path_to_cursors=_path.data.."/zxcvbn/cursors/"..self.filename..".cursors"
  -- try to load the cached cursors
  if util.file_exists(self.path_to_cursors) then
    print("sample: loading existing cursors")
    local f=io.open(self.path_to_cursors,"rb")
    local content=f:read("*all")
    f:close()
    if content~=nil then
      local data=json.decode(content)
      if data~=nil then
        do return data.cursors end
      end
    end
  end

  -- define average function
  local average=function(t)
    local sum=0
    for _,v in pairs(t) do -- Get the sum of all numbers in t
      sum=sum+v
    end
    return sum/#t
  end

  -- gather the onsets
  local onsets={}
  for _,algo in ipairs({"energy","hfc","complex","kl","specdiff"}) do
    for threshold=1.0,0.1,-0.1 do
      local cmd=string.format("aubioonset -i %s -B 128 -H 128 -t %2.1f -O %s",fname,threshold,algo)
      print(cmd)
      local s=util.os_capture(cmd)
      for w in s:gmatch("%S+") do
        local wn=tonumber(w)
        if math.abs(duration-wn)>0.1 then
          local found=false
          for i,o in ipairs(onsets) do
            if math.abs(wn-average(o.onset))<0.01 then
              found=true
              onsets[i].count=onsets[i].count+1
              table.insert(onsets[i].onset,wn)
              break
            end
          end
          if not found then
            table.insert(onsets,{onset={wn},count=1})
          end
        end
      end
    end
  end
  table.sort(onsets,function(a,b) return a.count>b.count end)
  local top16={}
  local i=0
  for _,o in ipairs(onsets) do
    i=i+1
    table.insert(top16,average(o.onset))
    if i==16 then
      break
    end
  end
  table.sort(top16)

  -- save the top16
  local filename=self.path_to_cursors
  local file=io.open(self.path_to_cursors,"w+")
  io.output(file)
  io.write(json.encode({cursors=top16}))
  io.close(file)

  return top16
end

function Sample:audition(on)
  local id="audition"
  local filename=self.path
  local db=0.0
  local pitch=0
  if self.is_melodic then
    if on then
      print("playing audition")
      local sampleStart=self.cursors[1]
      local sampleIn=self.cursors[2]
      local sampleOut=self.cursors[3]
      local sampleEnd=self.cursors[4]
      local watch=1
      engine.melodic_on(id,filename,db,pitch,
      sampleStart,sampleIn,sampleOut,sampleEnd,watch)
    else
      print("stopping audition")
      engine.melodic_off(id)
    end
  else
    if on then
      local rate=1
      local pos=self.cursors[self.ci]
      local duration=self.cursor_durations[self.ci]
      local send_pos=1
      engine.slice_on(id,filename,db,rate,pitch,pos,duration,send_pos)
    else
      engine.slice_off(id)
    end
  end
  -- local pos=self.is_melodic and self.cursors[1] or self.cursors[self.ci]
  -- local duration=self.cursor_durations[]
end

function Sample:dump()
  local data={}
  data.seq=json.encode(seq)
  return json.enode(data)
end

function Sample:load_dump(s)
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  self.seq=json.decode(data.seq)
end

function Sample:debounce()
  for k,v in pairs(self.debounce_fn) do
    if v~=nil and v[1]~=nil and v[1]>0 then
      v[1]=v[1]-1
      if v[1]~=nil and v[1]==0 then
        if v[2]~=nil then
          local status,err=pcall(v[2])
          if err~=nil then
            print(status,err)
          end
        end
        self.debounce_fn[k]=nil
      else
        self.debounce_fn[k]=v
      end
    end
  end
end

function Sample:do_zoom(d)
  -- zoom
  if d>0 then
    self.debounce_fn["zoom"]={1,function() self:zoom(true) end}
  else
    self.debounce_fn["zoom"]={1,function() self:zoom(false) end}
  end
end

function Sample:do_move(d)
  self.cursors[self.ci]=util.clamp(self.cursors[self.ci]+d*((self.view[2]-self.view[1])/128),0,self.duration)

  -- update cursor durations
  local cursors={}
  for i,c in ipairs(self.cursors) do
    table.insert(cursors,{i=i,c=c})
  end
  table.insert(cursors,{i=17,c=self.duration})
  table.sort(cursors,function(a,b) return a.c<b.c end)
  for i,cursor in ipairs(cursors) do
    if i<#cursors then
      self.cursor_durations[cursor.i]=cursors[i+1].c-cursor.c
    end
  end
  self.cursor_durations[#cursors]=self.duration-cursors[#cursors].c

  self.debounce_fn["save_cursors"]={30,function() self:save_cursors() end}
end

function Sample:keyboard(k,v)
  print(k,v)
  if k=="EQUAL" and v==1 then
    self:do_zoom(1)
  elseif k=="MINUS" and v==1 then
    self:do_zoom(-1)
  elseif k=="UP" and v==1 then
    self:sel_cursor(self.ci+1)
  elseif k=="DOWN" and v==1 then
    self:sel_cursor(self.ci-1)
  elseif k=="LEFT" and v==1 then
    self:do_move(-1)
  elseif k=="RIGHT" and v==1 then
    self:do_move(1)
  end
end

function Sample:enc(k,d)
  if k==1 then
  elseif k==2 then
    self:do_move(d)
  elseif k==3 and d~=0 then
    self:do_zoom(d)
  end
end

function Sample:key(k,z)
  if k==2 and z==1 then
    self:sel_cursor(self.ci+1)
  elseif k==3 then
    self:audition(z==1)
  end
end

function Sample:set_position(pos)
  self.show=1
  self.show_pos=pos
end

function Sample:sel_cursor(ci)
  if ci<1 then
    ci=ci+16
  elseif ci>16 then
    ci=ci-16
  end
  self.ci=ci
  local view_duration=(self.view[2]-self.view[1])
  local cursor=self.cursors[self.ci]
  if view_duration~=self.duration and cursor-self.cursor_durations[ci]<self.view[1] or cursor+self.cursor_durations[ci]>self.view[2] then
    local cursor_frac=0.5
    local next_view=cursor+self.cursor_durations[ci]
    if ci<16 then
      next_view=next_view+self.cursor_durations[ci+1]/2
    end
    local prev_view=cursor-self.cursor_durations[ci]
    if ci>1 then
      prev_view=self.cursors[ci-1]+self.cursor_durations[ci-1]/3
    end
    self.view={util.clamp(prev_view,0,self.duration),util.clamp(next_view,0,self.duration)}
  end
end

function Sample:zoom(zoom_in,zoom_amount)
  zoom_amount=zoom_amount or 1.5
  local view_duration=(self.view[2]-self.view[1])
  local view_duration_new=zoom_in and view_duration/zoom_amount or view_duration*zoom_amount
  local cursor=self.cursors[self.ci]
  local cursor_frac=(cursor-self.view[1])/view_duration
  local view_new={0,0}
  view_new[1]=util.clamp(cursor-view_duration_new*cursor_frac,0,self.duration)
  view_new[2]=util.clamp(view_new[1]+view_duration_new,0,self.duration)
  if (view_new[2]-view_new[1])<0.005 then
    do return end
  end
  self.view={view_new[1],view_new[2]}
end

function Sample:get_render()
  local rendered=string.format("%s%s_%3.3f_%3.3f_%d_%d.png",self.path_to_pngs,self.filename,self.view[1],self.view[2],self.width,self.height)
  if not util.file_exists(rendered) then
    if self.view[1]>self.view[2] then
      self.view[1],self.view[2]=self.view[2],self.view[1]
    end
    local cmd=string.format("%s -q -i %s -o %s -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.audiowaveform,self.path_to_dat,rendered,self.view[1],self.view[2],self.width,self.height)
    print(cmd)
    os.execute(cmd)
  end
  return rendered
end

function Sample:redraw()
  if not self.loaded then
    do return end
  end
  local x=7
  local y=8
  if show_cursor==nil then
    show_cursor=true
  end
  self:debounce()
  screen.aa(1)
  screen.display_png(self:get_render(),x,y)
  screen.aa(0)
  screen.update()

  for i,cursor in ipairs(self.cursors) do
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
      screen.level(i==self.ci and 15 or 5)
      screen.move(pos+x,64-self.height)
      screen.line(pos+x,64)
      screen.stroke()
    end
  end

  if self.show~=nil and self.show>0 then
    self.show=self.show-1
    self.is_playing=true
    screen.level(15)
    local cursor=self.show_pos
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
      screen.aa(1)
      screen.level(15)
      screen.move(pos+x,64-self.height)
      screen.line(pos+x,64)
      screen.stroke()
      screen.aa(0)
    end
  else
    self.is_playing=false
  end

  local title="/"..self.filename
  screen.level(15)
  screen.move(8+x,6)
  screen.text(title)
  screen.move(6+x,6)
  screen.text_right(self.dec_to_hex[self.ci])
  screen.blend_mode(1)
  screen.level(9)
  screen.rect(x,0,128,7)
  screen.fill()
  -- screen.rect(x,0,11,7)
  -- screen.fill()

end

return Sample
