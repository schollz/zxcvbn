local VTerm={}

function VTerm:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function VTerm:init()
  self.history={}
  self.history_pos=0
  self.view={row=1,col=1}
  self.cursor={row=4,col=8,x=0,blink=0}
  self.text=""
  self.lines={""}
  self.tosave={"history","history_pos","view","cursor","text"}
  self:move_cursor(0,0)

end

function VTerm:dumps()
  local data={}
  for _,k in ipairs(self.tosave) do
    data[k]=self[k]
  end
  return json.encode(data)
end

function VTerm:loads(s)
  local data=json.decode(s)
  if data==nil then
    do return end
  end
  for k,v in pairs(data) do
    self[k]=v
  end
  self:load_text(self.text)
  if self.on_save~=nil then
    self.on_save(table.concat(self.lines,"\n"))
  end
end

function VTerm:insert(row,col,s)
  return self.lines[row]:sub(1,col)..s..self.lines[row]:sub(col+1)
end

function VTerm:cursor_insert(s)
  self.history_dirty=true
  local row=self.cursor.row
  local col=self.cursor.col
  if s=="\n" then
    print("enter")
    local lines={}
    for i,line in ipairs(self.lines) do
      if i==row then
        table.insert(lines,line:sub(1,col))
        table.insert(lines,line:sub(col+1))
      else
        table.insert(lines,line)
      end
    end
    self.lines=lines
    self:move_cursor(0,1000)
  else
    if col==0 then
      self.lines[row]=s..self.lines[row]
    else
      self.lines[row]=self:insert(row,col,s)
    end
    self:move_cursor(0,1)
  end
  self:update_text()
end

function VTerm:cursor_delete()
  local row=self.cursor.row
  local col=self.cursor.col
  if col==0 then
    if row>1 then
      -- combine current line with previous line
      local lines={}
      local pos=0
      for i,line in ipairs(self.lines) do
        if i==row-1 then
          pos=#line
          table.insert(lines,line..self.lines[i+1])
        elseif i==row then
        else
          table.insert(lines,line)
        end
      end
      self.lines=lines
      self:move_cursor(-1,pos)
    end
    do return end
  end
  self.lines[row]=self.lines[row]:sub(1,col-1)..self.lines[row]:sub(col+1)
  self:move_cursor(0,-1)
  self:update_text()
end

function VTerm:update_text()
  if self.lines~=nil then
    self.text=table.concat(self.lines,"\n")
    self.unsaved=true -- used to add to the history
  end
end

function VTerm:get_text()
  return table.concat(self.lines,"\n")
end

function VTerm:save()
  if self.on_save==nil then
    do return end
  end
  local success=self.on_save(table.concat(self.lines,"\n"))
  if not success then
    do return end
  end
  self.history_dirty=false
  -- remove future history
  for i=self.history_pos+1,#self.history do
    self.history[i]=nil
  end
  -- add to history if it is a new entry
  if self.text~=self.history[#self.history] then
    table.insert(self.history,self.text)
    self.history_pos=#self.history
  end
  -- write it to a page
  debounce_fn["ignore_page"]={
    30,function()
    end
  }

  -- save all
  debounce_fn["save_all"]={3,function() 
    local f=io.open(_path.data.."zxcvbn/pages/"..self.id,"w")
    io.output(f)
    io.write(self.text)
    io.close(f)
  
    local s=(tracks[1].states[1].text or "")
    for i=2,10 do 
      s=string.format("%s\n\n###\n\n%s",s,(tracks[i].states[1].text or ""))
    end
    local f=io.open(_path.data.."zxcvbn/pages/all","w")
    io.output(f)
    io.write(s)
    io.close(f)      
  end}

end

function VTerm:undo()
  if #self.history==0 then
    do return end
  end
  if self.history_dirty then
    self.history_pos=#self.history
    self.history_dirty=false
  elseif self.history_pos>1 then
    self.history_pos=self.history_pos-1
  end
  self:load_text(self.history[self.history_pos])
  show_message("undo")
end

function VTerm:redo()
  if self.history_pos<#self.history and self.history_pos>0 then
    self.history_pos=self.history_pos+1
    self:load_text(self.history[self.history_pos])
    show_message("redo")
  end
end

function VTerm:copy()
  -- copy the current line
  self.copied=""..self.lines[self.cursor.row]
  show_message("copied")
end

function VTerm:paste()
  -- paste the line after the current
  if self.copied==nil then
    do return end
  end
  local lines={}
  for i,v in ipairs(self.lines) do
    if i==self.cursor.row then
      table.insert(lines,self.copied)
    end
    table.insert(lines,v)
  end
  self:load_text(table.concat(lines,"\n"))
  self.history_dirty=true
  show_message("pasted")
end

function VTerm:remove()
  local lines={}
  for i,v in ipairs(self.lines) do
    if i~=self.cursor.row then
      table.insert(lines,v)
    end
  end
  self:load_text(table.concat(lines,"\n"))
  self.history_dirty=true
end

function VTerm:blank()
  self:load_text("")
  -- self.cursor={row=0,col=0}
  -- self:move_cursor(0,0)
  self.history_dirty=true
end

function VTerm:load_text(text)
  self.text=text
  self.lines={}
  for line in text:gmatch("([^\n]*)\n?") do
    table.insert(self.lines,line)
  end
  if next(self.history)==nil then
    self.history={text}
    self.history_pos=1
  end
end

function VTerm:change_octave_in_line(str,octave_change)
  for i=2,#str do
    local c1=str:sub(i,i)
    local c0=str:sub(i-1,i-1)
    local c1neg=str:sub(i-2,i-2)
    if tonumber(c1)~=nil and 
      (c0==";" or  (string.byte(c0)>=string.byte("a") and string.byte(c0)<=string.byte("g")) or c0=="#") then
      str=str:sub(1,i-1)..math.floor(tonumber(c1)+octave_change)..str:sub(i+1)
    elseif tonumber(c1)~=nil and c0=="-" and (c1neg==";" or  (string.byte(c1neg)>=string.byte("a") and string.byte(c1neg)<=string.byte("g")) or c1neg=="#")  then 
        str=str:sub(1,i-2)..math.floor(tonumber(c0..c1)+octave_change)..str:sub(i+1)
    end
  end
  return str
end

function VTerm:move_cursor(row,col)
  if next(self.lines)==nil then
    do return end
  end
  self.cursor={row=self.cursor.row+row,col=self.cursor.col+col,blink=0}
  if self.cursor.row>#self.lines then
    self.cursor.row=#self.lines
  elseif self.cursor.row<1 then
    self.cursor.row=1
  end

  if self.cursor.col>#self.lines[self.cursor.row] then
    if self.cursor.row<#self.lines and col~=0 then
      self.cursor.row=self.cursor.row+1
      self.cursor.col=0
    else
      self.cursor.col=#self.lines[self.cursor.row]
    end
  elseif self.cursor.col<0 then
    if self.cursor.row>1 then
      self.cursor.row=self.cursor.row-1
      self.cursor.col=#self.lines[self.cursor.row]
    else
      self.cursor.col=0
    end
  end
  local line=self.lines[self.cursor.row]
  line=line:gsub(" ","-")
  self.cursor.x=screen.text_extents(line:sub(self.view.col,self.cursor.col))+2
  while self.cursor.x>120 do
    self.view.col=self.view.col+1
    self.cursor.x=screen.text_extents(line:sub(self.view.col,self.cursor.col))+2
  end
  while self.cursor.col<self.view.col do
    self.view.col=self.view.col-1
  end
  if self.cursor.col==0 then
    self.cursor.x=1
  end
  if self.cursor.row>self.view.row+5 then
    self.view.row=self.cursor.row-6
  end
  if self.cursor.row<self.view.row then
    self.view.row=self.cursor.row
  end
end

function VTerm:keyboard(k,v)
  local upper=false
  if k=="BACKSPACE" then
    if v>0 then
      self:cursor_delete()
    end
  elseif k=="DELETE" then
    if v>0 then
      if self.cursor.col<#self.lines[self.cursor.row] then
        self:move_cursor(0,1)
        self:cursor_delete()
      elseif self.cursor.col==#self.lines[self.cursor.row] and self.cursor.row<#self.lines then
        local first_pos=self.cursor.col
        self:move_cursor(1,-10000)
        self:cursor_delete()
        self:move_cursor(0,-10000)
        self:move_cursor(0,first_pos)
      end
    end
  elseif k=="LEFT" then
    if v>0 then
      self:move_cursor(0,-1)
    end
  elseif k=="SHIFT+RIGHT" then
    if v>0 then
      params:delta(self.id.."track_type",1)
    end
  elseif k=="SHIFT+LEFT" then
    if v>0 then
      params:delta(self.id.."track_type",-1)
    end
  elseif k=="SHIFT+UP" then
    self.shift_updown(v)
  elseif k=="SHIFT+DOWN" then
    self.shift_updown(v*-1)
  elseif k=="CTRL+LEFT" then
    if v==1 then
      params:delta("track",-1)
      do return end
    end
  elseif k=="CTRL+RIGHT" then
    if v==1 then
      params:delta("track",1)
      do return end
    end
  elseif k=="CTRL+UP" then
    self.lines[self.cursor.row]=self:change_octave_in_line(self.lines[self.cursor.row],v)
  elseif k=="CTRL+DOWN" then
    self.lines[self.cursor.row]=self:change_octave_in_line(self.lines[self.cursor.row],-1*v)
  elseif k=="RIGHT" then
    if v>0 then
      self:move_cursor(0,1)
    end
  elseif k=="DOWN" then
    if v>0 then
      self:move_cursor(1,0)
    end
  elseif k=="UP" then
    if v>0 then
      self:move_cursor(-1,0)
    end
  elseif k=="CTRL+E" then
    if v==1 then
      -- do explode
      if tracks[self.id].tli~=nil then
        local f=io.open(_path.data.."zxcvbn/tli.json","w")
        io.output(f)
        io.write(json.encode(tracks[self.id].tli))
        io.close(f)
        os.execute(_path.code.."zxcvbn/lib/acrostic/acrostic --in ".._path.data.."zxcvbn/tli.json --out ".._path.data.."zxcvbn/pages/")
      end
    end
  elseif k=="CTRL+T" or k=="CTRL+L" then
    if v==1 then
      if tracks[self.id].loop.pos_rec<0 then
        tracks[self.id]:loop_record()
      else
        tracks[self.id]:loop_toggle()
      end
    end
    do return end
  elseif k=="CTRL+R" then
    if v==1 then
      tracks[self.id]:loop_record()
    end
    do return end
  elseif k=="CTRL+P" then
    if v==1 then
      params:set(self.id.."play",1-params:get(self.id.."play"))
    end
  elseif k=="CTRL+Q" then
    if v==1 then
      self:blank()
    end
  elseif k=="CTRL+Z" then
    if v==1 then
      self:undo()
    end
  elseif k=="CTRL+Y" then
    if v==1 then
      self:redo()
    end
  elseif k=="CTRL+C" then
    if v==1 then
      self:copy()
    end
  elseif k=="CTRL+V" then
    if v==1 then
      self:paste()
    end
  elseif k=="CTRL+X" then
    if v==1 then
      self:remove()
    end
  elseif k=="CTRL+S" then
    if v==1 then
      show_message("saved",2)
      self:save()
    end
  elseif v==1 then
    local unknown=false
    if k=="SPACE" then
      k=" "
    elseif k=="SEMICOLON" then
      k=";"
    elseif k=="SHIFT+SEMICOLON" then
      k=":"
    elseif k=="APOSTROPHE" then
      k="'"
    elseif k=="SHIFT+APOSTROPHE" then
      k='"'
    elseif k=="SLASH" then
      k="/"
    elseif k=="SHIFT+SLASH" then
      k="?"
    elseif k=="DOT" then
      k="."
    elseif k=="SHIFT+DOT" then
      k=">"
    elseif k=="ENTER" then
      k="\n"
    elseif k=="MINUS" then
      k="-"
    elseif k=="SHIFT+MINUS" then
      k="_"
    elseif k=="COMMA" then
      k=","
    elseif k=="SHIFT+COMMA" then
      k="<"
    elseif k=="EQUAL" then
      k="="
    elseif k=="SHIFT+EQUAL" then
      k="+"
    elseif k=="SHIFT+1" then
      k="!"
    elseif k=="SHIFT+2" then
      k="@"
    elseif k=="SHIFT+3" then
      k="#"
    elseif k=="SHIFT+4" then
      k="$"
    elseif k=="SHIFT+5" then
      k="%"
    elseif k=="SHIFT+6" then
      k="^"
    elseif k=="SHIFT+7" then
      k="&"
    elseif k=="SHIFT+8" then
      k="*"
    elseif k=="SHIFT+9" then
      k="("
    elseif k=="SHIFT+0" then
      k=")"
    elseif string.find(k,"SHIFT") and #k:sub(7)==1 then
      k=k:sub(7)
      upper=true
    elseif #k>1 then
      unknown=true
      print("vterm: unknown character: "..k)
    end
    if not unknown then
      self:cursor_insert(upper and k or string.lower(k))
    end
  end
end

function VTerm:enc(k,d)
  if k==1 then
    params:delta(self.id.."db",d)
    debounce_fn["1"]={15,function() return "vol: "..params:string(self.id.."db") end}
  elseif k==2 then
    params:delta(self.id.."filter",d)
    debounce_fn["2"]={15,function() return "lpf: "..math.floor(musicutil.note_num_to_freq(params:get(self.id.."filter"))) end}
  elseif k==3 then
    params:delta(self.id..self.enc3(),d)
    if params.id_to_name[self.id..self.enc3()]~=nil then 
      debounce_fn["3"]={15,function() return params.id_to_name[self.id..self.enc3()]..": "..params:string(self.id..self.enc3()) end}
    end
  end
end

function VTerm:key(k,z)
  if k==1 then
    self.k1=z==1
  elseif k==2 and z==1 then
    if self.k1 then
      params:set(self.id.."mute",1-params:get(self.id.."mute"))
    else
      params:delta("track",-1)
    end
  elseif k==3 and z==1 then
    if self.k1 then
      params:set(self.id.."play",1-params:get(self.id.."play"))
    else
      params:delta("track",1)
    end
  end
end

function VTerm:redraw()
  screen.level(15)
  local x_offset=7
  local y_offset=6
  for i,line in ipairs(self.lines) do
    if i>=self.view.row then
      screen.level(15)
      screen.move(1+x_offset,8*(i-self.view.row+1)+y_offset)
      -- if i==4 then
      --   print(i,self.view.col,line:sub(self.view.col))
      -- end
      screen.text(line:sub(self.view.col))
    end
    if self.cursor.row==i then
      self.cursor.blink=self.cursor.blink+1
      if self.cursor.blink<7 then
        screen.level(5)
        screen.move(self.cursor.x+x_offset,8*(i-self.view.row+1)-6+y_offset)
        screen.line(self.cursor.x+x_offset,8*(i-self.view.row+1)+2+y_offset)
        screen.stroke()
      end
      if self.cursor.blink==10 then
        self.cursor.blink=0
      end
    end
  end

  screen.level(7)
  screen.rect(7,0,128,7)
  screen.fill()
  screen.level(params:get(params:get("track").."mute")==1 and 3 or 0)
  screen.move(8,6)
  screen.text(tracks[params:get("track")]:description())

  for i=1,3 do
    local k=""..i
    if debounce_fn[k]~=nil then
      screen.level(debounce_fn[k][1])
      screen.move(128,15+(i-1)*8)
      screen.text_right(debounce_fn[k][2]())
    end
  end

  if tracks[params:get("track")].loop.pos_rec>0 then
    local pos=tracks[params:get("track")].loop.pos_play
    screen.level(3)
    screen.move(7,64)
    screen.line(util.linlin(0,1,7,128,tracks[params:get("track")].loop.pos_rec),64)
    screen.stroke()
    screen.level(0)
    if pos>-1 then
      screen.level(debounce_fn[params:get("track").."looping"][1]+1)
      pos=util.linlin(0,1,7,128,pos)
      screen.move(7,64)
      screen.line(pos,64)
      screen.stroke()
    end
  elseif tracks[params:get("track")].loop.arm_rec then
    screen.level(self.cursor.blink%2==1 and 3 or 0)
    screen.move(7,64)
    screen.line(128,64)
    screen.stroke()
  elseif tracks[params:get("track")].loop.arm_play then
    screen.level(self.cursor.blink%2==1 and 15 or 3)
    screen.move(7,64)
    screen.line(128,64)
    screen.stroke()
  end

end

return VTerm
