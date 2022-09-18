local GGrid={}

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  m.to_binary=function(num)
    -- returns a table of bits, least significant first.
    local t={0,0,0,0} -- will contain the bits
    if num<0 or num>15 then
      return t
    end
    local j=1
    while num>0 do
      rest=math.fmod(num,2)
      t[5-j]=math.floor(rest)
      num=(num-rest)/2
      j=j+1
    end

    return t
  end

  return m
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end

  if col>8 and on then
    self:set_start_stop()
  elseif col<5 then
    self:set_binaries(row,col,on)
  end
end

function GGrid:set_binaries(row,col,on)
  local i=col+1
  if row>4 then
    i=i+4
  end
  sampler:set_focus(i,on)

  local inds={}
  for k,_ in pairs(self.pressed_buttons) do
    local r,c=k:match("(%d+),(%d+)")
    if col==c then
    end
  end
  if #inds<2 then
    do return end
  end
  table.sort(inds)
  local s=sampler:get_sample()
  s:set_start_stop(inds[1],inds[#inds])
end

function GGrid:set_start_stop()
  sampler:set_focus(1)
  local inds={}
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    if col>8 then
      table.insert(inds,(row-1)*8+col-8)
    end
  end
  if #inds<2 then
    do return end
  end
  table.sort(inds)
  local s=sampler:get_sample()
  s:set_start_stop(inds[1],inds[#inds])
end

function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-1
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- get the current sample
  local s=sampler:get_sample()

  -- illuminate binary options
  for j,k in ipairs(s.ordering) do
    if j>1 then
      local col=(j-2)%4+1
      local row_start=j<6 and 1 or 5
      for ii,vv in ipairs(self.to_binary(s.seq[k].vali-1)) do
        self.visual[row_start+ii-1][col]=(vv>0 and 5 or 1)*(s.focus==j and 2 or 1)
      end
    end
  end

  -- illuminate slices
  for row=3,6 do
    for col=5,8 do
      self.visual[row][col]=s.focus==1 and 10 or 5
    end
  end

  -- illuminate positions
  -- sampler.samples[1].seq.pos.stop=8
  -- sampler.samples[1].seq.pos.start=4
  local seq=s:get_seq()
  for row=1,8 do
    for col=9,16 do
      local i=(row-1)*8+col-8
      if i>=seq.start and i<=seq.stop then
        self.visual[row][col]=seq.vals[i]-1
        if i==seq.i then
          self.visual[row][col]=15
        end
      end
    end
  end

  -- illuminate currently pressed button
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=15
  end

  return self.visual
end

function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()
  screen.level(0)
  screen.rect(1,1,128,64)
  screen.fill()
  local gd=self.visual
  rows=#gd
  cols=#gd[1]
  for row=1,rows do
    for col=1,cols do
      if gd[row][col]~=0 then
        screen.level(gd[row][col])
        screen.rect(col*8-7,row*8-8+1,6,6)
        screen.fill()
      end
    end
  end
  -- screen.level(15)
  -- screen.rect(position[2]*8-7,position[1]*8-8+1,7,7)
  -- screen.stroke()
end

return GGrid
