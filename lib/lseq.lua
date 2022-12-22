local Lseq={}

function Lseq:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Lseq:init()
  self.d={
    pulses=0,
    steps={},
    play=false,
  }
  self.ppms={
    96,72,48,36,24,12,6,
  }
  self.times={
    12,8,6,4,3,2,1
  }
  self.current_step=1
  self.current_places={}
  self.step=1

  for i=1,15 do
    self.d.steps[i]={
      places={},
      arp=true,
      active=false,
      ppm=1,-- pulses per measure
      t=7, -- index of times to play
    }
  end
end

function Lseq:update()
  local seqs={}
  local total_pulses=0
  for i,step in ipairs(self.d.steps) do
    if next(step.places)~=nil and step.active then
      for times=1,self.times[step.t] do 
        local seq={}
        local pulses=self.ppms[step.ppm]
        local notes={}
        for j,rowcol in ipairs(step.places) do
          local row=rowcol[1]
          local col=rowcol[2]
          local note_ind=((9-row)+(4*(col-1))-1)%#tracks[self.id].scale_notes+1
          local note=tracks[self.id].scale_notes[note_ind]
          if step.arp then
            table.insert(seqs,{duration=math.floor(pulses/#step.places),pulses=1+total_pulses+(j-1)*math.floor(pulses/#step.places),notes={note},step=i,places={rowcol}})
          else
            table.insert(notes,note)
          end
        end
        if not step.arp then
          table.insert(seqs,{duration=pulses,pulses=1+total_pulses,notes=notes,step=i,places=step.places})
        end
        total_pulses=total_pulses+pulses  
      end
    end
  end
  self.d.pulses=total_pulses
  self.d.seq={}
  for _,v in ipairs(seqs) do
    self.d.seq[v.pulses]={duration=v.duration,pulses=v.pulses,notes=v.notes,step=v.step,places=v.places}
  end
end

------------------------------------------------
--                  getters                   --
------------------------------------------------

function Lseq:get_active(i)
  return self.d.steps[i].active
end

function Lseq:get_arp(i)
  return self.d.steps[i].arp
end

function Lseq:get_places(i)
  return self.d.steps[i].places
end

function Lseq:get_step()
  return self.current_step
end

function Lseq:get_ppm(i)
  return self.d.steps[i].ppm
end

function Lseq:get_play()
  return self.d.play
end

function Lseq:get_current_step()
  if not self.play then
    do return end
  end
  return self.current_step
end

function Lseq:get_current_places()
  if not self.play then
    do return end
  end
  return self.current_places
end

------------------------------------------------
--                  setters                   --
------------------------------------------------

function Lseq:toggle_play()
  self.d.play=not self.d.play
  self.current_step=1
  self.current_places={}
end

function Lseq:clear(all)
  if all then 
    self:init()
  else
    self.d.steps[self.step].places={}
  end
  self:update()
end

function Lseq:set_ppm(x)
  local i=self.step
  self.d.steps[i].ppm=x
  self:update()
end

function Lseq:set_times(x)
  local i=self.step
  self.d.steps[i].t=x
  self:update()
end

function Lseq:toggle_arp()
  local i=self.step
  self.d.steps[i].arp=not self.d.steps[i].arp
  self:update()
end

function Lseq:toggle_active(i)
  self.d.steps[i].active=not self.d.steps[i].active
  self:update()
end

function Lseq:toggle_note(row,col)
  local i=self.step
  for _,v in ipairs(self.d.steps[i].places) do
    if v[1]==row and v[2]==col then
      self:remove(i,row,col)
      do return end
    end
  end
  if next(self.d.steps[i].places)==nil then 
    self.d.steps[i].active=true 
  end
  self:add(i,row,col)
end

function Lseq:add(i,row,col)
  print("[lseq] add",i,row,col)
  table.insert(self.d.steps[i].places,{row,col})
  self:update()
end

function Lseq:remove(i,row,col)
  print("[lseq] rem",i,row,col)
  local places={}
  for _,v in ipairs(self.d.steps[i].places) do
    if v[1]==row and v[2]==col then
    else
      table.insert(places,v)
    end
  end
  self.d.steps[i].places=places
  self:update()
end

------------------------------------------------
--                  letters                   --
------------------------------------------------

function Lseq:emit(beat)
  if self.d.pulses==0 or not self.d.play then
    do return end
  end
  local i=(beat-1)%self.d.pulses+1
  if self.d.seq[i]==nil then
    do return end
  end
  self.current_step=self.d.seq[i].step
  self.current_places=self.d.seq[i].places
  for _,note in ipairs(self.d.seq[i].notes) do
    local d={duration=self.d.seq[i].duration}
    d.duration_scaled=d.duration*(clock.get_beat_sec()/24)
    local note_to_emit=note
    if note_to_emit~=nil then
      -- add transposition to note before getting scale
      note_to_emit=tracks[self.id]:note_in_scale(note_to_emit+params:get(self.id.."transpose"))
    end
    if note_to_emit==nil then
      do return end
    end
    if math.random(0,100)<=params:get(self.id.."probability") then
      d.note_to_emit=note_to_emit
      tracks[self.id].play_fn[params:get(self.id.."track_type")].note_on(d,{})
    end
  end
end

return Lseq
