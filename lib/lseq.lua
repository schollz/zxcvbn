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
    64,64,64,64,64,64,64,
  }
  self.current_step=0

  for i=1,15 do
    self.d.steps[i]={
      places={},
      arp=false,
      active=false,
      ppm=1,-- pulses per measure
    }
  end
end

function Lseq:update()
  local seqs={}
  local total_pulses=0
  for i,step in ipairs(self.d.steps) do
    if next(step.places)~=nil and step.active then
      local seq={}
      local pulses=self.ppms[step.ppm]
      local notes={}
      for j,rowcol in ipairs(step.places) do
        local row=rowcol[1]
        local col=rowcol[2]
        local note_ind=((9-row)+(4*(col-1))-1)%#tracks[self.id].scale_notes+1
        local note=tracks[self.id].scale_notes[note_ind]
        if step.arp then
          table.insert(seqs,{pulse=1+total_pulses+(j-1)*math.floor(pulses/#step.places),notes={note}})
        else
          table.insert(notes,note)
        end
      end
      if not step.arp then
        table.insert(seqs,{pulses=1+total_pulses,notes=notes,step=i})
      end
      total_pulses=total_pulses+pulses
    end
  end
  self.d.pulses=total_pulses
  self.d.seq={}
  for _,v in ipairs(seqs) do
    self.d.seq[v.pulses]={pulses=v.pulses,notes=v.notes,step=v.step}
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

------------------------------------------------
--                  setters                   --
------------------------------------------------

function Lseq:toggle_play()
  self.d.play=not self.d.play
end

function Lseq:set_ppm(i,x)
  self.d.steps[i].ppm=x
end

function Lseq:toggle_arp(i)
  self.d.steps[i].arp=not self.d.steps[i].arp
  self:update()
end

function Lseq:toggle_active(i)
  self.d.steps[i].active=not self.d.steps[i].active
  self:update()
end

function Lseq:toggle_note(i,row,col)
  for _,v in ipairs(self.d.steps) do
    if v[1]==row and v[2]==col then
      self:remove(i,row,col)
      do return end
    end
  end
  self:add(i,row,col)
end

function Lseq:add(i,row,col)
  table.insert(self.d.steps[i].places,{row,col})
  self:update()
end

function Lseq:remove(i,row,col)
  local steps={}
  for _,v in ipairs(self.d.steps) do
    if v[1]==row and v[2]==col then
    else
      table.insert(steps,v)
    end
  end
  self.d.steps=steps
  self:update()
end

------------------------------------------------
--                  letters                   --
------------------------------------------------

function Lseq:emit(beat)
  if self.d.pulses==0 || not self.d.play then
    do return end
  end
  local i=(beat-1)%self.d.pulses+1
  if self.d.seq[i]==nil then
    do return end
  end
  self.current_step=d.seq[i].step
  for _,note in ipairs(self.d.seq[i].notes) do
    local d={duration=i}
    d.duration_scaled=d.duration*(clock.get_beat_sec()/24)
    local note_to_emit=note
    if note_to_emit~=nil then
      -- add transposition to note before getting scale
      note_to_emit=track[self.id]:note_in_scale(note_to_emit+params:get(self.id.."transpose"))
    end
    if note_to_emit==nil or params:get(self.id.."mute")==1 then
      do return end
    end
    if math.random(0,100)<=params:get(self.id.."probability") then
      d.note_to_emit=note_to_emit
      self.play_fn[params:get(self.id.."track_type")].note_on(d,{})
    end
  end
end

return Lseq
