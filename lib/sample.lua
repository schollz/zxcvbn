local Sample={}

function Sample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sample:init()
  self.debounce_fn={}
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
  self.width=128
  self.debounce_zoom=0

  -- create dat file
  os.execute("mkdir -p ".._path.dat.."break-ops/dats/")
  os.execute("mkdir -p ".._path.dat.."break-ops/cursors/")
  os.execute("mkdir -p ".._path.dat.."break-ops/pngs/")
  self.path_to_dat=_path.dat.."break-ops/dats/"..self.filename..".dat"
  self.path_to_pngs=_path.data.."break-ops/pngs/"
  if not util.file_exists(self.path_to_dat) then
    os.execute(string.format("/home/we/dust/code/break-ops/lib/audiowaveform -q -i %s -o %s -z %d -b 8",path,self.path_to_dat,2))
  end

  -- figure out the bpm
  local bpm=nil
  for word in string.gmatch(self.path,'([^_]+)') do
    if string.find(word,"bpm") then
      bpm=tonumber(word:match("%d+"))
    end
  end
  if bpm==nil then
    bpm=self:guess_bpm(path)
  end
  if bpm==nil then
    bpm=clock.get_tempo()
  end
  self.bpm=bpm

  -- load cursors or figure out the best number
  self.cursors={}
  self.cursor_durations={}
  for i=1,16 do
    table.insert(self.cursors,(i-1)*self.duration/16)
    table.insert(self.cursor_durations,self.duration/16)
  end
  self.path_to_cursors=_path.data.."/break-ops/cursors/"..self.filename..".cursors"
  if util.file_exists(self.path_to_cursors) then 
    self:load_cursors()
  end

  self:load_buffer()
  self:render()
end

function Sample:load_buffer()
  engine.load_buffer(self.path)
end

function Sample:play(amp,rate,pos,duration,gate,retrig)
  duration=duration or 100000
  engine.play(self.path,amp,rate,pos,duration)
end

function Sample:play_cursor(amp,rate,gate,retrig,ci)
  self:play(amp,rate,self.cursors[ci],self.cursor_durations[ci],gate,retrig)
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

function Sample:load_cursors()
  local f=io.open(self.path_to_cursors,"rb")
  local content=f:read("*all")
  f:close()
  if content==nil then
    do return end
  end
  local data=json.decode(content)
  if data~=nil then 
    self.cursors=data.cursors
    self.cursor_durations=data.cursor_durations
  end
end

function Sample:save_cursors()
  filename=filename..".json"
  local file=io.open(self.path_to_cursors,"w+")
  io.output(file)
  io.write({cursors=self.cursors,cursor_durations=self.cursor_durations})
  io.close(file)
end

function Sample:guess_bpm(fname)
  local ch,samples,samplerate=audio.file_info(fname)
  if samples==nil or samples<10 then
    print("ERROR PROCESSING FILE: "..self.path)
    do return end
  end
  local duration=samples/samplerate
  local closest={1,1000000}
  for bpm=90,179 do
    local beats=duration/(60/bpm)
    local beats_round=util.round(beats)
    -- only consider even numbers of beats
    if beats_round%4==0 then
      local dif=math.abs(beats-beats_round)/beats
      if dif<closest[2] then
        closest={bpm,dif,beats}
      end
    end
  end
  print("bpm guessing for",fname)
  tab.print(closest)
  return closest[1]
end

function Sample:do_zoom(d)
  -- zoom
  if d>0 then 
    self.debounce_fn["zoom"]={1, function() self:zoom(true) end}
  else
    self.debounce_fn["zoom"]={1, function() self:zoom(false) end}
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
  for i=1,16 do 
    self.cursor_durations[cursors[i].i]=cursors[i+1].c-cursors[i].c
  end

  self.debounce_fn["save_cursors"]={30, function() self:save_cursors() end}
end

function Sample:enc(k,d)
  if k==3 and d~=0 then
    self:do_zoom(d)
  elseif k==2 then
    self:do_move(d)
  end
end

function Sample:key(k,z)
  if z==0 then
    do return end
  end
  if k==2 then
    self:sel_cursor(self.ci+1)
  elseif k==3 then
    self:play_cursor(1.0,1.0,1.0,1.0,self.ci)
  end
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
  if view_duration~=self.duration and cursor<self.view[1] or cursor>self.view[2] then
    local cursor_frac=0.5
    self.view={util.clamp(cursor-view_duration*cursor_frac,0,self.duration),util.clamp(self.view[1]+view_duration,0,self.duration)}
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
  local rendered=string.format("%s%s_%3.3f_%3.3f_%d_%d.png",self.png_path,self.filename,self.view[1],self.view[2],self.width,self.height)
  if not util.file_exists(rendered) then 
    os.execute(string.format("audiowaveform -q -i %s -o %s -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.path_to_dat,rendered,self.view[1],self.view[2],self.width,self.height))
  end
  return rendered
end

function Sample:redraw()
  local x=0
  local y=8
  if show_cursor==nil then
    show_cursor=true
  end
  self:debounce()
  screen.aa(1)
  screen.display_png(self:get_render(),x,y)
  screen.aa(0)
  screen.update()
  local cursors=self:get_cursors()

  for i=1,self:get_cursor_num() do
    local cursor=cursors[i]
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,128,cursor)
      screen.level(i==self.ci and 15 or 1)
      screen.move(pos,64-self.height)
      screen.line(pos,64)
      screen.stroke()
    end
  end

  if self.show~=nil and self.show>0 then
    self.show=self.show-1
    self.is_playing=true
    screen.level(15)
    local cursor=self.show_pos
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,128,cursor)
      screen.aa(1)
      screen.level(15)
      screen.move(pos,64-self.height)
      screen.line(pos,64)
      screen.stroke()
      screen.aa(0)
    end
  else
    self.is_playing=false
  end
  return string.format("%02d",self.ci).."/"..self:get_cursor_num().." "..self.filename
end

return Sample