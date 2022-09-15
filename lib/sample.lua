local Sample={}

function Sample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Sample:init(path,num_cursors,waveform_file,height,width,resolution)
  print("Sample:init",path,num_cursors)
  pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.path=path
  self.filename=string.upper(filename)
  local ch,samples,samplerate=audio.file_info(path)
  if samples<10 or samples==nil then
    print("ERROR PROCESSING FILE: "..path)
    do return end
  end
  self.octave=4
  self.duration=samples/samplerate
  self.cursors={}
  self.cursors[1]={}
  for i=1,64 do
    table.insert(self.cursors[1],(i-1)*self.duration/64)
  end
  self.cursors[2]={0,self.duration*0.6,self.duration*0.9,self.duration}
  self.ci=1
  self.view={0,self.duration}
  self.height=height or 56
  self.width=width or 128
  self.debounce_zoom=0
  self.waveform_file=waveform_file or "waveform"
  self.waveform_file=self.waveform_file..self.id
  resolution=resolution or 2
  print(path)
  self.dat_path="/home/we/dust/data/zxcvbn/"..path:gsub("/","_")..".dat"
  if not util.file_exists(self.dat_path) then
    os.execute(string.format("/home/we/dust/code/zxcvbn/lib/audiowaveform -q -i %s -o %s -z %d -b 8",path,self.dat_path,resolution))
  end
  self:render()

  self.keyboard_fn={}
  self.keyboard_fn.LEFT=function(x) self:do_move(x*-1) end
  self.keyboard_fn.RIGHT=function(x) self:do_move(x) end
  self.keyboard_fn.UP=function(x) self:do_zoom(1) end
  self.keyboard_fn.DOWN=function(x) self:do_zoom(-1) end
  self.keyboard_fn["SHIFT+UP"]=function(x) params:delta(self.id.."slices",self:is_drum_mode() and 1 or 0) end
  self.keyboard_fn["SHIFT+DOWN"]=function(x) params:delta(self.id.."slices",self:is_drum_mode() and-1 or 0) end
  self.keyboard_fn["SHIFT+LEFT"]=function(x) self:sel_cursor(self.ci-1) end
  self.keyboard_fn["SHIFT+RIGHT"]=function(x) self:sel_cursor(self.ci+1)end
  self.keyboard_fn.BACKSLASH=function(x) self:do_autosplice() end
  self.keyboard_fn.SPACE=function(x) self:play(48) end
  self.keyboard_fn.ESC=function(x)
    if params:get(self.id.."sound")==1 then
      params:set(self.id.."sound",2)
    else
      params:set(self.id.."sound",1)
    end
    show_message(params:string(self.id.."sound"):upper().." MODE")
  end
  -- https://tutorials.renoise.com/wiki/Playing_Notes_with_the_Computer_Keyboard
  self.keyboard_notes={
    "Z","S","X","D","C","V","G","B","H","N","J","M","COMMA","L","DOT","SEMICOLON","SLASH",
    "Q","2","W","3","E","R","5","T","6","Y","7","U","I","9","O","0","P","LEFTBRACE","EQUAL","RIGHTBRACE"
  }
  self.keyboard_nn={}
  for i,kn in ipairs(self.keyboard_notes) do
    self.keyboard_nn[kn]=function(x)
      local val=i>17 and i-5 or i
      if not self:is_drum_mode() then
        local new_note=(val-1)+(self.octave*12)
        if x==1 then
          self:play(new_note)
        elseif x==0 and not self:is_drum_mode() then
          self:play_stop(new_note)
        end
      elseif x==1 then
        local slice=(val-1)%self:get_slice_num()+1
        self:sel_cursor(slice)
        self:play()
      end
    end
  end

  self:do_autosplice()
end

function Sample:drum_or_melodic()
  print("drum or melodic")
  self:update_slices()
end

function Sample:do_autosplice()
  local num_cursors=self:get_slice_num()
  for i=1,num_cursors do
    self.cursors[(params:get(self.id.."sound")-1)%2+1][i]=(i-1)*self.duration/num_cursors
  end
end

function Sample:do_zoom(d)
  -- zoom
  self.debounce_zoom=(d>0 and 1 or-1)
end

function Sample:do_move(d)
  self.cursors[(params:get(self.id.."sound")-1)%2+1][self.ci]=util.clamp(self.cursors[(params:get(self.id.."sound")-1)%2+1][self.ci]+d*((self.view[2]-self.view[1])/128),0,self.duration)
end

function Sample:get_cursors()
  return self.cursors[(params:get(self.id.."sound")-1)%2+1]
end

function Sample:is_drum_mode()
  return (params:get(self.id.."sound")-1)%2+1==1
end

function Sample:get_slice_num()
  if (params:get(self.id.."sound")-1)%2+1==1 then
    return params:get(self.id.."slices")
  else
    return 4
  end
end

function Sample:get_sample_points(x)
  local cursors=self:get_cursors()
  local ci=(x-1)%self:get_slice_num()+1
  print(ci)
  if (params:get(self.id.."sound")-1)%2+1==1 then
    local last=params:get(self.id.."slices")==ci and self.duration or cursors[ci+1]
    if last==nil then last=self.duration end
    if params:get(self.id.."sliceplay")==2 then last=self.duration end
    return {cursors[ci],last}
  else
    return cursors
  end
end

function Sample:update_slices()
  if self.path==nil then
    do return end
  end
  if self.ci>self:get_slice_num() then
    self.ci=self:get_slice_num()
  end
end

function Sample:play(note)
  local cursors=self:get_cursors()
  if self:is_drum_mode() then
    local start=cursors[self.ci]
    local stop=self.ci==self:get_slice_num() and self.duration or cursors[self.ci+1]
    --print(self.path,start,stop)
    -- engine.audition(self.path,start,stop)
    engine.oneshot(self.id,self.path,"audition_1",48,48,0.5,start,stop,10,1)
  elseif note~=nil then
    engine.inandout(self.path,string.format("audition%d",note),note,48,1.0,cursors[1],cursors[2],cursors[3],cursors[4],15+self.id/100,0.005,0.5,0.9,0.1)
  end
end

function Sample:play_stop(note)
  engine.inandout_release(string.format("audition%d",note))
end

function Sample:play_all()
  engine.audition(self.path,0,self.duration)
end

function Sample:keyboard(code,value)
  print(code,value)
  if value==1 then
    print(code)
  end
  if value>0 and self.keyboard_fn[code]~=nil then
    self.keyboard_fn[code](value)
  elseif self.keyboard_nn[code]~=nil then
    self.keyboard_nn[code](value)
  end
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
    print(self.path,cursors[self.ci],cursors[self.ci+1] or self.duration)
    engine.audition(self.path,cursors[self.ci],cursors[self.ci+1] or self.duration)
  end
end

function Sample:sel_cursor(ci)
  if ci<1 then
    ci=ci+self:get_slice_num()
  elseif ci>self:get_slice_num() then
    ci=ci-self:get_slice_num()
  end
  self.ci=ci
  local view_duration=(self.view[2]-self.view[1])
  local cursors=self:get_cursors()
  if view_duration~=self.duration and cursors[self.ci]<self.view[1]
    or cursors[self.ci]>self.view[2] then
    local cursor_frac=0.5
    self.view[1]=util.clamp(cursors[self.ci]-view_duration*cursor_frac,0,self.duration)
    self.view[2]=util.clamp(self.view[1]+view_duration,0,self.duration)
    self:render()
  end
end

function Sample:zoom(zoom_in,zoom_amount)
  zoom_amount=zoom_amount or 1.5
  local view_duration=(self.view[2]-self.view[1])
  local view_duration_new=zoom_in and view_duration/zoom_amount or view_duration*zoom_amount
  local cursors=self:get_cursors()
  local cursor_frac=(cursors[self.ci]-self.view[1])/view_duration
  local view_new={0,0}
  view_new[1]=util.clamp(cursors[self.ci]-view_duration_new*cursor_frac,0,self.duration)
  view_new[2]=util.clamp(view_new[1]+view_duration_new,0,self.duration)
  if (view_new[2]-view_new[1])<0.005 then
    do return end
  end
  self.view={view_new[1],view_new[2]}
  self:render()
end

function Sample:render()
  os.execute(string.format("/home/we/dust/code/zxcvbn/lib/audiowaveform -q -i %s -o /dev/shm/%s.png -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.dat_path,self.waveform_file,self.view[1],self.view[2],self.width,self.height))
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