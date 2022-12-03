local SoftSample={}

function SoftSample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function SoftSample:init()
  local charset={} do -- [0-9a-zA-Z]
    for c=48,57 do table.insert(charset,string.char(c)) end
    for c=65,90 do table.insert(charset,string.char(c)) end
    for c=97,122 do table.insert(charset,string.char(c)) end
  end

  random_string=function(length)
    if not length or length<=0 then return '' end
    math.randomseed(os.clock()^5)
    return random_string(length-1)..charset[math.random(1,#charset)]
  end

  self.path_to_save=_path.data.."zxcvbn/softcut/"
  os.execute("mkdir -p "..self.path_to_save)
  self.path_to_save=self.path_to_save..random_string(6)..self.id..".wav"

  self.dec_to_hex={"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

  -- initialize debouncer
  self.debounce_fn={}

  -- choose audiowaveform binary
  self.tosave={"ci","cursors","cursor_durations","cursor_deleted","view","path_to_save"}

  -- initialize
  self.ci=1
  self.view={0,params:get(self.id.."sc_loop_end")}
  self.height=56
  self.width=120
  self.debounce_zoom=0
  self.blink=0

  self.slice_num=16
  self.cursors={}
  self.cursor_durations={}
  self.cursor_deleted={}
  for i=1,self.slice_num do
    table.insert(self.cursors,(i-1)/16*params:get(self.id.."sc_loop_end"))
    table.insert(self.cursor_durations,params:get(self.id.."sc_loop_end")/16)
    table.insert(self.cursor_deleted,false)
  end
  self:do_move(0)

  self.phase=0
end

function SoftSample:get_onsets()
  show_message("determing onsets",4)
  show_progress(0)

  self:write_wav()

  debounce_fn[self.id.."onsets"]={1,function()
    os.execute(_path.code.."zxcvbn/lib/aubiogo/aubiogo --id "..self.id.." --filename '"..self.path_to_save.."' --num 16 --rm &")
  end}
end

function SoftSample:got_onsets(data_s)
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
end

function SoftSample:write_wav()
  softcut.buffer_write_mono(self.path_to_save,softcut_offsets[params:get(self.id.."sc")],
  params:get(self.id.."sc_loop_end"),softcut_buffers[params:get(self.id.."sc")])
end

function SoftSample:load_sample(path,get_onsets)
  self.ch,self.samples,self.sample_rate=audio.file_info(path)
  if self.samples<10 or self.samples==nil then
    print("ERROR PROCESSING FILE: "..path)
    do return end
  end
  self.duration=self.samples/self.sample_rate
  print("self.duration",self.duration)
  self.duration=self.duration<=60 and self.duration or 60
  softcut.buffer_read_mono(path,0,softcut_offsets[params:get(self.id.."sc")],self.duration,0,softcut_buffers[params:get(self.id.."sc")],0,1)
  params:set(self.id.."sc_loop_end",self.duration)
  self.view={0,params:get(self.id.."sc_loop_end")}
  self.cursors={}
  self.cursor_durations={}
  for i=1,self.slice_num do
    table.insert(self.cursors,(i-1)/16*params:get(self.id.."sc_loop_end"))
    table.insert(self.cursor_durations,params:get(self.id.."sc_loop_end")/16)
  end
  self:do_render_buffer()
end

function SoftSample:update_loop()
  self.view={0,params:get(self.id.."sc_loop_end")}
  self:do_render_buffer()
end

function SoftSample:do_render_buffer()
  if softcut_rendering[params:get(self.id.."sc")] then
    do return end
  end
  debounce_fn["render"]={10,function()
    print("softsample: rendering",softcut_buffers[params:get(self.id.."sc")],self.view[1]+softcut_offsets[params:get(self.id.."sc")],self.view[2]-self.view[1],self.width)
    softcut_rendering[params:get(self.id.."sc")]=true
    softcut.render_buffer(softcut_buffers[params:get(self.id.."sc")],self.view[1]+softcut_offsets[params:get(self.id.."sc")],self.view[2]-self.view[1],self.width)
  end}
end

function SoftSample:dumps()
  local data={}
  for _,k in ipairs(self.tosave) do
    data[k]=self[k]
  end
  self:write_wav()
  return json.encode(data)
end

function SoftSample:loads(s)
  print("sample: loads",s)
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  for k,v in pairs(data) do
    self[k]=v
  end
  if util.file_exists(self.path_to_save) then
    self:load_sample(self.path_to_save)
  end
  self:do_move(0)
end

function SoftSample:play(d)
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
  d.filter=musicutil.note_num_to_freq(params:get(self.id.."filter"))

  local pos=self.cursors[d.ci]
  d.duration_slice=d.duration or self.cursor_durations[d.ci]
  d.duration_total=d.duration_slice
  if params:get(self.id.."play_through")==2 and d.duration_slice>self.cursor_durations[d.ci] then
    d.duration_slice=self.cursor_durations[d.ci]
  end
  d.duration_slice=d.duration_slice*d.gate
  if d.duration_slice==0 then
    do return end
  end

  local i=params:get(self.id.."sc")

  -- modulate duration slice if retrigged
  if d.retrig>0 then
    d.duration_slice=d.duration_slice/(d.retrig+1)
    softcut.loop(i,1)
    if params:get(self.id.."sc_sync")==2 then
      softcut.loop(i+3,1)
    end
    local sleep_pulses=util.round(24*(d.duration_slice/clock.get_beat_sec()))
    debounce_fn["sc"..self.id]={sleep_pulses,function()
      softcut.loop(i,0)
      if params:get(self.id.."sc_sync")==2 then
        softcut.loop(i+3,0)
      end
    end}
    self.has_retrigged=true
  else
    if self.has_retrigged==nil or self.has_retrigged==true then
      self.has_retrigged=false
      softcut.loop(i,0)
      softcut.loop_start(i,softcut_offsets[i]-0.005)
      if params:get(self.id.."sc_sync")==2 then
        softcut.loop(i+3,0)
        softcut.loop_start(i+3,softcut_offsets[i]-0.005)
      end
    end
  end

  local foo=util.dbamp(d.db+params:get(self.id.."db"))
  if foo~=self.cache_level then
    self.cache_level=foo
    softcut.level(i,self.cache_level)
  end

  local foo=d.rate*musicutil.interval_to_ratio (d.pitch)
  if foo~=self.cache_rate then
    self.cache_rate=foo
    softcut.rate(i,self.cache_rate)
    if params:get(self.id.."sc_sync")==2 then
      softcut.rate(i+3,self.cache_rate)
    end
  end

  local foo=d.filter
  if foo~=self.cache_filter then
    self.cache_filter=foo
    softcut.post_filter_fc(i,self.cache_filter)
  end

  local loop_end=pos+d.duration_slice+softcut_offsets[i]
  if params:get(self.id.."play_through")==1 then
    loop_end=softcut_offsets[i]+params:get(self.id.."sc_loop_end")
  end
  if loop_end~=self.cache_loop_end then
    softcut.loop_end(i,loop_end)
    if params:get(self.id.."sc_sync")==2 then
      softcut.loop_end(i+3,loop_end)
    end
  end

  print(i,pos+softcut_offsets[i])
  softcut.position(i,pos+softcut_offsets[i])
  if params:get(self.id.."sc_sync")==2 then
    softcut.position(i+3,pos+softcut_offsets[i])
  end
end

function SoftSample:audition(on)
  local id="audition"
  self:play({
    on=on,
    id="audition",
    watch=1,
  })
end

function SoftSample:debounce()
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

function SoftSample:do_render()
  print("rendering",softcut_buffers[params:get(self.id.."sc")],self.view[1]+softcut_offsets[params:get(self.id.."sc")],self.view[2]-self.view[1],self.width)
  softcut.render_buffer(softcut_buffers[params:get(self.id.."sc")],self.view[1]+softcut_offsets[params:get(self.id.."sc")],self.view[2]-self.view[1],self.width)
end

function SoftSample:do_zoom(d)
  -- zoom
  if d>0 then
    self.debounce_fn["zoom"]={1,function() self:zoom(true) end}
  else
    self.debounce_fn["zoom"]={1,function() self:zoom(false) end}
  end
end

function SoftSample:do_move(d)
  if d>0 then
    self.cursor_deleted[self.ci]=false
  end
  self.cursors[self.ci]=util.clamp(self.cursors[self.ci]+d*((self.view[2]-self.view[1])/128),0,params:get(self.id.."sc_loop_end"))

  -- update cursor durations
  local cursors={}
  for i,c in ipairs(self.cursors) do
    if not self.cursor_deleted[i] then
      table.insert(cursors,{i=i,c=c})
    end
  end
  table.sort(cursors,function(a,b) return a.c<b.c end)
  for i,v in ipairs(cursors) do
    if v.i<#self.cursor_durations then
      local next=cursors[i+1] or {c=params:get(self.id.."sc_loop_end")}
      self.cursor_durations[v.i]=next.c-v.c
    end
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

function SoftSample:keyboard(k,v)
  print("softsample",k,v)
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
  elseif k=="LEFT" and v>0 then
    self:do_move(-1)
  elseif k=="CTRL+D" and v==1 then
    self:get_onsets()
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

function SoftSample:enc(k,d)
  if k==1 then
    params:delta(self.id.."sc_rec_level",d)
    debounce_fn["rec_change"]={15,function()end}
  elseif k==2 then
    self:do_move(d)
  elseif k==3 and d~=0 then
    self:do_zoom(d)
  end
end

function SoftSample:key(k,z)
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

function SoftSample:set_position(pos)
  self.show=1
  self.show_pos=pos
end

function SoftSample:delta_cursor(d)
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

function SoftSample:sel_cursor(ci)
  if ci<1 then
    ci=ci+self.slice_num
  elseif ci>self.slice_num then
    ci=ci-self.slice_num
  end
  self.ci=ci
  local view_duration=(self.view[2]-self.view[1])
  local cursor=self.cursors[self.ci]
  if view_duration~=params:get(self.id.."sc_loop_end") and (cursor<self.view[1] or cursor>self.view[2]) then
    local prev_view=cursor-view_duration/2
    local next_view=cursor+view_duration/2
    self.view={util.clamp(prev_view,0,self.duration),util.clamp(next_view,0,self.duration)}
    self:do_render()
  end
end

function SoftSample:zoom(zoom_in,zoom_amount)
  zoom_amount=zoom_amount or 1.5
  local view_duration=(self.view[2]-self.view[1])
  local view_duration_new=zoom_in and view_duration/zoom_amount or view_duration*zoom_amount
  local cursor=self.cursors[self.ci]
  local cursor_frac=(cursor-self.view[1])/view_duration
  local view_new={0,0}
  view_new[1]=util.clamp(cursor-view_duration_new*cursor_frac,0,params:get(self.id.."sc_loop_end"))
  view_new[2]=util.clamp(view_new[1]+view_duration_new,0,params:get(self.id.."sc_loop_end"))
  if (view_new[2]-view_new[1])<0.005 then
    do return end
  end
  self.view={view_new[1],view_new[2]}
  self:do_render()
end

function SoftSample:redraw()
  self.blink=self.blink-1
  if self.blink<0 then
    self.blink=8
  end
  local sel_level=self.blink>4 and (self.cursor_deleted[self.ci] and 3 or 15) or 1
  local x=7
  local y=15
  if show_cursor==nil then
    show_cursor=true
  end
  self:debounce()

  -- TODO if recording and no debounce is set, then setup a debounce to render
  if self.debounce_fn[params:get(self.id.."sc").."render"]==nil and params:get(self.id.."sc_rec_level")>0 then
    self.debounce_fn[params:get(self.id.."sc").."render"]={5,function() self:do_render() end}
  end

  -- display waveform
  for i,v in ipairs(softcut_renders[params:get(self.id.."sc")]) do
    v=v*self.height/2
    screen.level(10)
    screen.move(i+x,y/2+self.height/2)
    screen.line(i+x,y/2+self.height/2+v)
    screen.move(i+x,y/2+self.height/2)
    screen.line(i+x,y/2+self.height/2-v)
    screen.stroke()
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

  -- display playback cursor
  local cursor=softcut_positions[params:get(self.id.."sc")]-softcut_offsets[params:get(self.id.."sc")]
  local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
  screen.level(15)
  screen.move(pos+x,64-self.height)
  screen.line(pos+x,64)
  screen.stroke()

  -- display recording cursor
  local cursor=softcut_positions[params:get(self.id.."sc")+3]-softcut_offsets[params:get(self.id.."sc")]
  local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
  screen.level(10)
  screen.move(pos+x,64-self.height)
  screen.line(pos+x,64)
  screen.stroke()

  if debounce_fn["rec_change"]~=nil then
    screen.level(debounce_fn["rec_change"][1])
    screen.move(128,15)
    screen.text_right(params:string(self.id.."sc_rec_level"))
  end

  -- display title
  local title="/".."softcut "..params:get(self.id.."sc")
  screen.level(5)
  screen.rect(7,0,128,7)
  screen.fill()
  screen.level(params:get(params:get("track").."mute")==1 and 3 or 0)
  screen.move(8,6)
  screen.move(8+x,6)
  screen.text(title)
  screen.move(6+x,6)
  screen.text_right(self.dec_to_hex[self.ci])
end

return SoftSample
