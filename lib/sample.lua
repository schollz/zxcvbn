local Sample={}

function Sample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sample:init()
  print("sample: init "..self.path)
  self.pathname,self.filename,self.ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.filename=string.upper(self.filename)
  self.ch,self.samples,self.sample_rate=audio.file_info(self.path)
  if self.samples<10 or self.samples==nil then
    print("ERROR PROCESSING FILE: "..path)
    do return end
  end
  self.duration=samples/samplerate
  self.cursors={}
  for i=1,16 do
    table.insert(self.cursors,(i-1)*self.duration/16)
  end
  self.ci=1
  self.view={0,self.duration}
  self.height=56
  self.width=128
  self.debounce_zoom=0
  self.waveform_file=waveform_file or "waveform"
  self.waveform_file=self.waveform_file..self.id
  resolution=resolution or 2
  print(path)
  self.dat_path="/home/we/dust/data/break-ops/"..path:gsub("/","_")..".dat"
  if not util.file_exists(self.dat_path) then
    os.execute(string.format("/home/we/dust/code/break-ops/lib/audiowaveform -q -i %s -o %s -z %d -b 8",path,self.dat_path,resolution))
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

  -- load slices or figure out the best number
  self.path_slices=_path.data.."/break-ops/"..path:gsub("/","_")..".slices"
  if util.file_exists(self.path_slices) then 
    -- TODO: try to load slices
  else
    self.slices={}
    for i=1,16 do 
      table.insert(self.slices,(i-1)/16)
    end
  end

  self:render()
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
  self.debounce_zoom=(d>0 and 1 or-1)
end

function Sample:do_move(d)
  self.cursors[self.ci]=util.clamp(self.cursors[self.ci]+d*((self.view[2]-self.view[1])/128),0,self.duration)
  -- TODO: debounce saving the cursor positions
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
    local cursors=self:get_cursors()
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
    self.view[1]=util.clamp(cursor-view_duration*cursor_frac,0,self.duration)
    self.view[2]=util.clamp(self.view[1]+view_duration,0,self.duration)
    self:render()
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
  self:render()
end

function Sample:render()
  os.execute(string.format("/home/we/dust/code/break-ops/lib/audiowaveform -q -i %s -o /dev/shm/%s.png -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.dat_path,self.waveform_file,self.view[1],self.view[2],self.width,self.height))
end

function Sample:redraw(x,y,show_cursor)
  x=x or 0
  y=y or 8
  if show_cursor==nil then
    show_cursor=true
  end
  if self.waveform_file==nil or not util.file_exists("/dev/shm/"..self.waveform_file..".png") then
    do return "NOTHING LOADED" end
  end
  if self.debounce_zoom~=0 then
    if self.debounce_zoom<0 then
      self.debounce_zoom=self.debounce_zoom+1
      if self.debounce_zoom==0 then
        self:zoom(false)
      end
    else
      self.debounce_zoom=self.debounce_zoom-1
      if self.debounce_zoom==0 then
        self:zoom(true)
      end
    end
  end
  screen.aa(1)
  screen.display_png("/dev/shm/"..self.waveform_file..".png",x,y)
  screen.aa(0)
  screen.update()
  if show_cursor then
    local cursors=self:get_cursors()
    for i=1,self:get_slice_num() do
      local cursor=cursors[i]
      if cursor>=self.view[1] and cursor<=self.view[2] then
        local pos=util.linlin(self.view[1],self.view[2],1,128,cursor)
        screen.level(i==self.ci and 15 or 1)
        screen.move(pos,64-self.height)
        screen.line(pos,64)
        screen.stroke()
      end
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
  return string.format("%02d",self.ci).."/"..self:get_slice_num().." "..self.filename
end

return Sample