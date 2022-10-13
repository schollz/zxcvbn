local SoftSample={}

function SoftSample:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function SoftSample:init()
  local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local random_string=function(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock()^5)
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

  self.path_to_save=_path.data.."zxcvbn/softcut/"
  os.execute("mkdir -p "..self.path_to_save)
  self.path_to_save=self.path_to_save....random_string(6)..self.id..".wav"

  self.dec_to_hex={"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

  -- initialize debouncer
  self.debounce_fn={}

  -- choose audiowaveform binary
  self.tosave={"ci","cursors","cursor_durations","view","path_to_save"}

  -- initialize
  self.duration=self.duration or 30
  self.ci=1
  self.view={0,self.duration}
  self.height=56
  self.width=120
  self.debounce_zoom=0

  self.slice_num=16
  self.cursors={}
  self.cursor_durations={}
  for i=1,self.slice_num do
    table.insert(self.cursors,(i-1)/16*self.duration)
    table.insert(self.cursor_durations,self.duration/16)
  end


  self.render={}
  self.phase=0

  -- enable playback head
  local i=self.id
  softcut.buffer(i,softcut_buffers[i])
  softcut.enable(i,1)
  softcut.play(i,1)
  softcut.loop(i,0)
  softcut.fade_time(i,0.05)
  softcut.loop_start(i,softcut_offsets[i])
  softcut.loop_end(i,softcut_offsets[i]+30) -- will get overridden when we load sample folders, anyway
  softcut.position(i,softcut_offsets[i]+30) -- set to the loop end for each voice, so we aren't playing anything
  softcut.rate(i,1)
  softcut.pan_slew_time(i,0.01)
  softcut.level_slew_time(i,0.01)
  softcut.post_filter_dry(i,0)
  softcut.post_filter_lp(i,1)
  softcut.post_filter_fc(i,12000)
  softcut.level(i,1)

    -- enable recording head (decoupled from playback head)
  i=self.id+3
  softcut.buffer(i,softcut_buffers[i])
  softcut.enable(i,1)
  softcut.play(i,1)
  softcut.loop(i,1)
  softcut.rec(i,1)
  softcut.level(i,0)
  softcut.rec_level(i,0)
  softcut.fade_time(i,0.05)
  softcut.loop_start(i,softcut_offsets[i])
  softcut.loop_end(i,softcut_offsets[i]+30) -- will get overridden when we load sample folders, anyway


end

function Sample:get_onsets()
  show_message("determing onsets",4)
  show_progress(0)

  self:write_wav()

  debounce_fn[self.id.."onsets"]={1,function() 
    os.execute(_path.code.."zxcvbn/lib/aubiogo/aubiogo --id "..self.id.." --filename "..self.path_to_save.." --num 16 --rm &")
  end}
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
end

function SoftSample:write_wav()
  softcut.buffer_write_mono(self.path_to_save, softcut_offsets[self.id], 60, softcut_buffers[self.id])
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
    softcut.buffer_read_mono (self.path_to_save, 0, softcut_offsets[self.id],, 60, 1, softcut_buffers[self.id], 0, 1)
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
  if d.duration_slice==0 then
    do return end
  end

  -- modulate duration slice if retrigged
  if d.retrig>0 then
    d.duration_slice=d.duration_slice/(d.retrig+1)
    softcut.loop(self.id,1)
    local sleep_pulses=util.round(24*(d.duration_slice/clock.get_beat_sec()))
    debounce_fn["sc"..self.id]={sleep_pulses,function() softcut.loop(self.id,0) end}
  else
    softcut.loop(self.id,0)
  end

  softcut.level(self.id,util.dbamp(d.db+params:get(self.id.."db")))
  softcut.post_filter_fc(self.id,d.filter)
  softcut.loop_start(self.id,pos)
  softcut.loop_end(self.id,pos+d.duration_slice)
  softcut.position(self.id,pos)
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
  softcut.render_buffer(softcut_buffers[self.id],self.view[1]+softcut_offsets[self.id],self.view[2]-self.view[1],self.width)
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
    self:sel_cursor(self.ci-1)
  elseif k=="SHIFT+RIGHT" and v==1 then
    self:sel_cursor(self.ci+1)
  elseif k=="LEFT" and v>0 then
    self:do_move(-1)
  elseif k=="RIGHT" and v>0 then
    self:do_move(1)
  elseif k=="SPACE" or k=="ENTER" then
    if v==1 then
      self:audition(v>0)
    end
  end
end

function SoftSample:enc(k,d)
  if k==1 then
  elseif k==2 then
    self:do_move(d)
  elseif k==3 and d~=0 then
    self:do_zoom(d)
  end
end

function SoftSample:key(k,z)
  if k==2 and z==1 then
    self:sel_cursor(self.ci+1)
  elseif k==3 then
    self:audition(z==1)
  end
end

function SoftSample:set_render(render)
  self.render=render  
end

function SoftSample:set_phase(phase)
  self:set_position(phase-softcut_offsets[self.id])
end

function SoftSample:set_position(pos)
  self.show=1
  self.show_pos=pos
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
  if view_duration~=self.duration and cursor-self.cursor_durations[ci]<self.view[1] or cursor+self.cursor_durations[ci]>self.view[2] then
    local cursor_frac=0.5
    local next_view=cursor+self.cursor_durations[ci]
    if ci<self.slice_num then
      next_view=next_view+self.cursor_durations[ci+1]/2
    end
    local prev_view=cursor-self.cursor_durations[ci]
    if ci>1 then
      prev_view=self.cursors[ci-1]+self.cursor_durations[ci-1]/3
    end
    self.view={util.clamp(prev_view,0,self.duration),util.clamp(next_view,0,self.duration)}
  end
end

function SoftSample:zoom(zoom_in,zoom_amount)
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
  self:do_render()
end

function SoftSample:redraw()
  local x=7
  local y=8
  if show_cursor==nil then
    show_cursor=true
  end
  self:debounce()

  -- display waveform
  for i,v in ipairs(self.render) do 
    screen.move(i+x,y+(self.height-v))
    screen.line(i+x,y+v)
    screen.stroke()
  end

  for i,cursor in ipairs(self.cursors) do
    if cursor>=self.view[1] and cursor<=self.view[2] then
      local pos=util.linlin(self.view[1],self.view[2],1,self.width,cursor)
      screen.level(i==self.ci and 15 or 5)
      screen.move(pos+x,64-self.height)
      screen.line(pos+x,64)
      screen.stroke()
    end
  end

  local title="/".."soft"..self.id
  screen.level(15)
  screen.move(8+x,6)
  screen.text(title)
  screen.move(6+x,6)
  screen.text_right(self.dec_to_hex[self.ci])
  screen.blend_mode(1)
  screen.level(5)
  screen.rect(x,0,128,7)
  screen.fill()
  screen.blend_mode(0)
  screen.move(126,58)
  screen.level(15)
  screen.text_right(self.kick[self.ci].." dB")
end

return SoftSample
