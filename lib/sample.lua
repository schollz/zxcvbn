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
  -- choose audiowaveform binary
  self.audiowaveform="/home/we/dust/code/break-ops/lib/audiowaveform"
  local foo=util.os_capture(self.audiowaveform.." --help")
  if not string.find(foo,"Options") then
    self.audiowaveform="audiowaveform"
  end

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
  os.execute("mkdir -p ".._path.data.."break-ops/dats/")
  os.execute("mkdir -p ".._path.data.."break-ops/cursors/")
  os.execute("mkdir -p ".._path.data.."break-ops/pngs/")
  self.path_to_dat=_path.data.."break-ops/dats/"..self.filename..".dat"
  self.path_to_pngs=_path.data.."break-ops/pngs/"
  if not util.file_exists(self.path_to_dat) then
    local cmd=string.format("%s -q -i %s -o %s -z %d -b 8",self.audiowaveform,self.path,self.path_to_dat,2)
    print(cmd)
    os.execute(cmd)
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
  self.path_to_cursors=_path.data.."/break-ops/cursors/"..self.filename..".cursors"
  if util.file_exists(self.path_to_cursors) then -- TODO debug
    print("sample: loading existing cursors")
    self:load_cursors()
  else
    self.cursors={}
    self.cursor_durations={}
    local onsets=self:get_onsets(self.path,self.duration)
    for i=1,16 do
      table.insert(self.cursors,onsets[i])
      if i<16 then
        table.insert(self.cursor_durations,onsets[i+1]-onsets[i])
      else
        table.insert(self.cursor_durations,self.duration-onsets[i])
      end
    end
    tab.print(self.cursors)
    self:save_cursors()
  end

  engine.load_buffer(self.path)
  self.loaded=true
end

function Sample:get_onsets(fname,duration)
  local average=function(t)
    local sum=0
    for _,v in pairs(t) do -- Get the sum of all numbers in t
      sum=sum+v
    end
    return sum/#t
  end
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
  return top16
end

function Sample:play(amp,rate,pos,duration,gate,retrig)
  duration=duration or 100000
  rate=rate*clock.get_tempo()/self.bpm -- normalize tempo to bpm
  print("sample: play",amp,rate,pos,duration,gate,retrig)
  engine.play(self.path,amp,rate,pos,duration,gate,retrig,sampler.cur==self.path and 1 or 0)
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
  print(content)
  local data=json.decode(content)
  if data~=nil then
    self.cursors=data.cursors
    self.cursor_durations=data.cursor_durations
  end
end

function Sample:save_cursors()
  local filename=self.path_to_cursors
  local file=io.open(self.path_to_cursors,"w+")
  io.output(file)
  io.write(json.encode({cursors=self.cursors,cursor_durations=self.cursor_durations}))
  io.close(file)
  print("sample: save_cursors done")
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
    self.debounce_fn["zoom"]={1,function() self:zoom(true) end}
  else
    self.debounce_fn["zoom"]={1,function() self:zoom(false) end}
  end
end

function Sample:do_move(d)
  tab.print(self.cursors)
  self.cursors[self.ci]=util.clamp(self.cursors[self.ci]+d*((self.view[2]-self.view[1])/128),0,self.duration)

  -- update cursor durations
  local cursors={}
  for i,c in ipairs(self.cursors) do
    table.insert(cursors,{i=i,c=c})
  end
  table.insert(cursors,{i=17,c=self.duration})
  table.sort(cursors,function(a,b) return a.c<b.c end)
  for i=1,16 do
    print(i)
    self.cursor_durations[cursors[i].i]=cursors[i+1].c-cursors[i].c
  end

  self.debounce_fn["save_cursors"]={30,function() self:save_cursors() end}
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

  for i=1,16 do
    local cursor=self.cursors[i]
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
    print(self.view[1],self.view[2],cursor)
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
  return string.format("%02d",self.ci).."/16 "..self.filename
end

return Sample
