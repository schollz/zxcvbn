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
    self:move_cursor(1,-100)
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
  if self.on_save~=nil then
    self.on_save(table.concat(self.lines,"\n"))
  end
  if self.history_pos==0 then
    do return end
  end
  -- remove future history
  for i=self.history_pos+1,#self.history do
    self.history[i]=nil
  end
  if #self.history==0 or self.text~=self.history[#self.history] then
    table.insert(self.history,self.text)
  end
end

function VTerm:undo()
  if self.history_pos>1 then
    self.history_pos=self.history_pos-1
    self:load_text(self.history[self.history_pos])
  end
end

function VTerm:redo()
  if self.history_pos<#self.history and self.history_pos>0 then
    self.history_pos=self.history_pos+1
    self:load_text(self.history[self.history_pos])
  end
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

function VTerm:move_cursor(row,col)
  if next(self.lines)==nil then
    do return end
  end
  self.cursor={row=self.cursor.row+row,col=self.cursor.col+col,blink=0}
  if self.cursor.row>#self.lines then
    self.cursor.row=#self.lines
  end
  if self.cursor.row<1 then
    self.cursor.row=1
  end
  if self.cursor.col>#self.lines[self.cursor.row] then
    self.cursor.col=#self.lines[self.cursor.row]
  end
  if self.cursor.col<0 then
    self.cursor.col=0
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
  if self.cursor.row>self.view.row+6 then
    self.view.row=self.cursor.row-7
  end
  if self.cursor.row<self.view.row then
    self.view.row=self.cursor.row
  end
end

function VTerm:keyboard(k,v)
  print(k,v)
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
  elseif k=="CTRL+P" then
    if v==1 then
      params:set(self.id.."play",1-params:get(self.id.."play"))
      show_message(params:get(self.id.."play")==0 and "stopped" or "playing")
    end
  elseif k=="CTRL+Z" then
    self:undo()
  elseif k=="CTRL+Y" then
    self:redo()
  elseif k=="CTRL+S" then
    show_message("saved",2)
    self:save()
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
  if k==2 then
    self:move_cursor(0,d)
  elseif k==3 then
    self:move_cursor(d,0)
  end
end

function VTerm:key(k,z)
  if k==3 and z==1 then
    self:cursor_insert("z")
  elseif k==2 and z==1 then
    self:cursor_delete()
  end
end

function VTerm:redraw()
  screen.level(15)
  local x_offset=7
  local y_offset=-2
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
end

return VTerm
