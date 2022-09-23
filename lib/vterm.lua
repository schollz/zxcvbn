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
  self.view={row=1,col=1}
  self.cursor={row=1,col=3}
  self:load_text[[file amenbreak_bpm136.wav
bpm 136 
 
chain a
ppq 4 
 
pattern a
0
1
2
3 3 3 3  
]]
  self:move_cursor(0,0)
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
      for i,line in ipairs(self.lines) do
        if i==row-1 then
          table.insert(lines,line..self.lines[i+1])
        elseif i==row then
        else
          table.insert(lines,line)
        end
      end
      self.lines=lines
      self:move_cursor(-1,10000)
    end
    do return end
  end
  self.lines[row]=self.lines[row]:sub(1,col-1)..self.lines[row]:sub(col+1)
  print(col)
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

function VTerm:update_history()
  if self.unsaved then
    self.unsaved=nil
    table.insert(self.history,self.text)
  end
end

function VTerm:load_text(text)
  self.text=text
  self.lines={}
  for line in text:gmatch("([^\n]*)\n?") do
    table.insert(self.lines,line)
  end
end

function VTerm:move_cursor(row,col)
  self.cursor={row=self.cursor.row+row,col=self.cursor.col+col}
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
  self.cursor.x=screen.text_extents(line:sub(1,self.cursor.col))+2
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
  if k=="BACKSPACE" then
    if v>0 then
      self:cursor_delete()
    end
  elseif k=="DELETE" then
    if v>0 then
      if self.cursor.col<#self.lines[self.cursor.row] then
        self:move_cursor(0,1)
        self:cursor_delete()
      end
    end
  elseif k=="LEFT" then
    if v==1 then
      self:move_cursor(0,-1)
    end
  elseif k=="RIGHT" then
    if v==1 then
      self:move_cursor(0,1)
    end
  elseif k=="DOWN" then
    if v==1 then
      self:move_cursor(1,0)
    end
  elseif k=="UP" then
    if v==1 then
      self:move_cursor(-1,0)
    end
  elseif self.ctrl then
    if k=="S" and v==1 then
    elseif k=="Z" and v==1 then
      -- TODO: undo
    elseif tonumber(k)~=nil and tonumber(k)>0 and tonumber(k)<10 then
      -- TODO: switch?
    end
  elseif k=="SHIFT+S" then
    show_message("saved",2)
    if self.on_save~=nil then
      self.on_save(table.concat(self.lines,"\n"))
    end
    -- TODO: add to history
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
    elseif #k>1 then
      unknown=true
      print("vterm: unknown character: "..k)
    end
    if not unknown then
      self:cursor_insert(self.shift and k or string.lower(k))
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
      screen.text(line:sub(self.view.col))
    end
    if self.cursor.row==i then
      screen.level(5)
      screen.move(self.cursor.x+x_offset,8*(i-self.view.row+1)-6+y_offset)
      screen.line(self.cursor.x+x_offset,8*(i-self.view.row+1)+2+y_offset)
      screen.stroke()
    end
  end
end

return VTerm
