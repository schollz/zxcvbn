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
  self.blink=0

  self.tosave={"ci","cursors","cursor_durations","cursor_deleted","view","kick"}
end

function Sample:load_sample(path,is_melodic,slices)
  print("sample: load_sample "..path,slices)
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

  self.slice_num=self.is_melodic and 4 or slices
  self.cursors={}
  self.cursor_durations={}
  self.cursor_deleted={}
  self.kick={}
  self.kick_change=0
  for i=1,self.slice_num do
    table.insert(self.cursors,0)
    table.insert(self.kick,-48)
    table.insert(self.cursor_durations,0)
    table.insert(self.cursor_deleted,false)
  end

  -- create dat file
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

  self.is_melodic=is_melodic
  if not is_melodic then
    self:get_onsets()
  else
    self.cursors[2]=self.duration*0.6
    self.cursors[3]=self.duration*0.8
    self.cursors[4]=self.duration-0.1
  end
  engine.load_buffer(self.path)

  if not self.is_melodic then
    local bpm=nil
    for word in string.gmatch(self.path,'([^_]+)') do
      if string.find(word,"bpm") then
        bpm=tonumber(word:match("%d+"))
      end
    end
    if bpm==nil then
      bpm=self:guess_bpm(self.path)
    end
    if bpm==nil then
      bpm=clock.get_tempo()
    end
    params:set(self.id.."bpm",bpm)
  end
  self.loaded=true
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
end

function Sample:dumps()
  local data={}
  for _,k in ipairs(self.tosave) do
    data[k]=self[k]
  end
  return json.encode(data)
end

function Sample:loads(s)
  -- print("sample: loads",s)
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  for k,v in pairs(data) do
    self[k]=v
  end
  self:do_move(0)
end

function Sample:get_onsets()
  show_message("determing onsets",4)
  show_progress(0)
  self.path_to_cursors=_path.data.."/zxcvbn/cursors/"..self.filename.."_"..self.slice_num..".cursors"
  -- try to load the cached cursors
  if util.file_exists(self.path_to_cursors) then
    print("sample: loading existing cursors")
    local f=io.open(self.path_to_cursors,"rb")
    local content=f:read("*all")
    f:close()
    if content~=nil then
      local data=json.decode(content)
      if data~=nil then
        self.cursors=data.cursors
        self:do_move(0)
        show_message(string.format("[%d] loaded",self.id),2)
        do return end
      end
    end
  end

  -- gather the onsets
  print("executing")
  os.execute(_path.code.."zxcvbn/lib/aubiogo/aubiogo --id "..self.id.." --filename '"..self.path.."' --num "..self.slice_num.." &")
  print("executed")
end

function Sample:got_onsets(data_s)
  local data=json.decode(data_s)
  if data==nil then
    print("error getting onset data!")
    do return end
  end
  if data.error~=nil then
    print("error getting onset data: "..data.error)
    do return end
  end
  if data.result==nil then
    print("no onset results!")
    do return end
  end
  self.cursors=data.result
  self:do_move(0)
  show_message(string.format("[%d] loaded",self.id),2)

  -- save the top_slices
  print("writing cursor file",self.path_to_cursors)
  local file=io.open(self.path_to_cursors,"w+")
  io.output(file)
  io.write(json.encode({cursors=self.cursors}))
  io.close(file)
end

function Sample:play(d)
  local filename=self.path
  d.on=d.on or false
  d.id=d.id or "audition"
  d.db=d.db or 0
  d.pan=d.pan or params:get(self.id.."pan")
  d.pitch=d.pitch or 0
  d.watch=d.watch or 0
  d.rate=d.rate or params:get(self.id.."rate")
  d.ci=d.ci or self.ci
  d.retrig=d.retrig or 0
  d.gate=d.gate or 1.0
  d.compressing=d.compressing or params:get(self.id.."compressing")
  d.compressible=d.compressible or params:get(self.id.."compressible")
  d.filter=musicutil.note_num_to_freq(params:get(self.id.."filter"))
  d.decimate=d.decimate or params:get(self.id.."decimate")
  d.attack=d.attack or params:get(self.id.."attack")/1000
  d.release=d.release or params:get(self.id.."release")/1000
  d.reverb=d.reverb or params:get(self.id.."send_reverb")
  d.delay=d.delay or params:get(self.id.."send_delay")
  d.drive=d.drive or params:get(self.id.."drive")
  d.compression=d.compression or params:get(self.id.."compression")
  d.stretch=d.stretch or params:get(self.id.."stretch")
  d.monophonic_release=d.monophonic_release or params:get(self.id.."monophonic_release")/1000
  d.send_tape=d.send_tape or 0
  if self.is_melodic then
    if d.on then
      local sampleStart=self.cursors[1]
      local sampleIn=self.cursors[2]
      local sampleOut=self.cursors[3]
      local sampleEnd=self.cursors[4]
      engine.melodic_on(
        d.id,
        filename,
        params:get(self.id.."db"),
        d.db,
        d.pan,
        d.pitch,
        sampleStart,
        sampleIn,
        sampleOut,
        sampleEnd,
        d.duration or 1,
        d.filter,
        d.gate,
        d.retrig,
        d.compressible,
        d.compressing,
        d.reverb,
      d.watch,d.attack,d.release,d.monophonic_release,d.drive,d.send_tape,d.delay)
    end
  else
    if d.on and self.cursors~=nil then
      if d.rate<0 then
        d.ci=d.ci+1
        if d.ci>#self.cursors then
          d.ci=1
        end
      end
      local pos=self.cursors[d.ci]
      d.duration_slice=d.duration or self.cursor_durations[d.ci]
      d.duration_total=d.duration_slice
      if params:get(self.id.."play_through")==2 and d.duration_slice>self.cursor_durations[d.ci] then
        d.duration_slice=self.cursor_durations[d.ci]
      end
      if d.duration_total/d.retrig<d.duration_slice then
        d.duration_slice=d.duration_total
      end
      if d.duration_slice<0.01 then
        do return end
      end
      -- print("duration",d.duration,"gate",d.gate,"retrig",d.retrig,"rate",d.rate,"pitch",d.pitch)
      local send_pos=1
      engine.slice_on(
        d.id,
        filename,
        params:get(self.id.."db"),
        d.db,
        d.pan,
        d.rate,
        d.pitch,
        pos,
        d.duration_slice,
        d.duration_total,
        d.retrig,
        d.gate,
        d.filter,
        d.decimate,
        d.compressible,
        d.compressing,
        d.reverb,d.drive,d.compression,
      d.watch,d.attack,d.release,d.stretch,d.send_tape,d.delay)
      if self.kick[d.ci]>-48 then
        engine.kick(
          musicutil.note_num_to_freq(params:get("kick_basenote")),
          params:get("kick_ratio"),
          params:get("kick_sweeptime")/1000,
          params:get("kick_preamp"),
          params:get("kick_db")+self.kick[d.ci],
          params:get("kick_decay1")/1000,
          params:get("kick_decay1L")/1000,
          params:get("kick_decay2")/1000,
          params:get("kick_clicky")/1000,
          params:get("kick_compressing"),
          params:get("kick_compressible"),
          d.reverb,d.send_tape,d.send_delay
        )
      end
    elseif not d.on then
      engine.slice_off(d.id)
    end
  end
end

function Sample:audition(on)
  local id="audition"
  self:play({
    on=on,
    id="audition",
    watch=1,
  })
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
  if self.duration==nil then
    do return end
  end
  if d>0 then
    self.cursor_deleted[self.ci]=false
  end
  if self.cursors[self.ci]==nil then 
    do return end 
  end
  self.cursors[self.ci]=util.clamp(self.cursors[self.ci]+d*((self.view[2]-self.view[1])/128),0,self.duration)

  -- update cursor durations
  local cursors={}
  for i,c in ipairs(self.cursors) do
    if not self.cursor_deleted[i] then
      table.insert(cursors,{i=i,c=c})
    end
  end
  table.sort(cursors,function(a,b) return a.c<b.c end)
  for i,v in ipairs(cursors) do
    local next=cursors[i+1] or {c=self.duration}
    self.cursor_durations[v.i]=next.c-v.c
  end
  cursors={}
  for i,c in ipairs(self.cursors) do
    table.insert(cursors,{i=i,c=c})
  end
  self.cursor_sorted=cursors
  if d>0 then
    self:sel_cursor(self.ci)
  end
end

function Sample:adjust_kick(i,d)
  if self.is_melodic then
    do return end
  end
  self.kick[i]=self.kick[i]+d
  if self.kick[i]<-48 then
    self.kick[i]=-48
  elseif self.kick[i]>12 then
    self.kick[i]=12
  end
  self.kick_change=16
end

function Sample:keyboard(k,v)
  print(k,v)
  if k=="EQUAL" and v==1 then
    self:do_zoom(1)
  elseif k=="MINUS" and v==1 then
    self:do_zoom(-1)
  elseif k=="UP" and v>0 then
    self:do_zoom(1)
  elseif k=="DOWN" and v>0 then
    self:do_zoom(-1)
  elseif k=="SHIFT+LEFT" and v==1 then
    self:delta_cursor(-1)
  elseif k=="SHIFT+RIGHT" and v==1 then
    self:delta_cursor(1)
  elseif k=="CTRL+D" and v==1 then
    self:get_onsets()
  elseif k=="CTRL+S" and v==1 then
    self:save_cursors()
  elseif k=="LEFT" and v>0 then
    self:do_move(-1)
  elseif k=="RIGHT" and v>0 then
    self:do_move(1)
  elseif k=="DELETE" and v==1 then
    self.cursor_deleted[self.ci]=not self.cursor_deleted[self.ci]
    self:do_move(0)
  elseif k=="SPACE" or k=="ENTER" then
    if v==1 then
      self:audition(v>0)
    end
  end
end

function Sample:enc(k,d)
  if k==1 then
    self:adjust_kick(self.ci,d)
  elseif k==2 then
    self:do_move(d)
  elseif k==3 and d~=0 then
    self:do_zoom(d)
  end
end

function Sample:key(k,z)
  if k==1 then
    self.k1=z==1
  elseif k==2 and z==1 then
    self:sel_cursor(self.ci+1)
  elseif k==3 then
    if self.k1 then
      if z==1 then
        -- calculate offsets
        self:get_onsets()
      end
    else
      self:audition(z==1)
    end
  end
end

function Sample:set_position(pos)
  self.show=1
  self.show_pos=pos
end

function Sample:delta_cursor(d)
  if self.cursor_sorted==nil then
    do return end
  end
  for i,v in ipairs(self.cursor_sorted) do
    if v.i==self.ci then
      self:sel_cursor(self.cursor_sorted[(i+d-1)%#self.cursor_sorted+1].i)
      do return end
    end
  end
end

function Sample:sel_cursor(ci)
  if self.duration==nil then
    do return end
  end
  if ci<1 then
    ci=ci+self.slice_num
  elseif ci>self.slice_num then
    ci=ci-self.slice_num
  end
  self.ci=ci
  local view_duration=(self.view[2]-self.view[1])
  local cursor=self.cursors[self.ci]
  if view_duration~=self.duration and (cursor<self.view[1] or cursor>self.view[2]) then
    local prev_view=cursor-view_duration/2
    local next_view=cursor+view_duration/2
    self.view={util.clamp(prev_view,0,self.duration),util.clamp(next_view,0,self.duration)}
  end
end

function Sample:zoom(zoom_in,zoom_amount)
  if self.duration==nil then
    do return end
  end

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
    local cmd=string.format("%s -q -i '%s' -o '%s' -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color 757575 --no-axis-labels --compression 0 &",audiowaveform,self.path_to_dat,rendered,self.view[1],self.view[2],self.width,self.height)
    print(cmd)
    os.execute(cmd)
  end
  return rendered
end

function Sample:save_cursors()
  print("writing cursor file",self.path_to_cursors)
  local file=io.open(self.path_to_cursors,"w+")
  io.output(file)
  io.write(json.encode({cursors=self.cursors}))
  io.close(file)
  show_message("cursors saved!")
end

function Sample:redraw()
  if not self.loaded then
    do return end
  end
  self.blink=self.blink-1
  if self.blink<0 then
    self.blink=8
  end
  local sel_level=self.blink>4 and (self.cursor_deleted[self.ci] and 3 or 15) or 1
  local x=7
  local y=8
  if show_cursor==nil then
    show_cursor=true
  end
  self:debounce()
  local png_file=self:get_render()
  if util.file_exists(png_file) then
    screen.aa(1)
    screen.display_png(self:get_render(),x,y)
    screen.aa(0)
  end

  for i,cursor in ipairs(self.cursors) do
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
      local level=i==self.ci and sel_level or (self.cursor_deleted[i] and 1 or 5)
      screen.level(level)
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
  screen.level(5)
  screen.rect(7,0,128,7)
  screen.fill()
  screen.level(params:get(params:get("track").."mute")==1 and 3 or 0)
  screen.move(8,6)
  screen.move(8+x,6)
  screen.text(title)
  screen.move(6+x,6)
  screen.text_right(self.dec_to_hex[self.ci])

  if self.kick_change>0 then
    self.kick_change=self.kick_change-1
    screen.move(128,15)
    screen.level(self.kick_change)
    screen.text_right(self.kick[self.ci].." dB")
  end
end

return Sample
