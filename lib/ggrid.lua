local GGrid={}

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.apm=args.apm or {}
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  local midigrid=util.file_exists(_path.code.."midigrid")
  local grid=midigrid and include "midigrid/lib/mg_128" or grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.visualf={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    m.visualf[i]={}
    for j=1,16 do
        m.visual[i][j]=0
        m.visualf[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=midigrid and 0.12 or 0.07
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  self.pressed_buttons={}

  return m
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  local ct=clock.get_beats()*clock.get_beat_sec()
  local hold_time=0
  local id=(row-1)*16+col
  if on then
    self.pressed_buttons[row..","..col]=ct
  else
    hold_time=ct-self.pressed_buttons[row..","..col]
    self.pressed_buttons[row..","..col]=nil
  end
  local play_fn=tracks[params:get("track")].play_fn[params:get(params:get("track").."track_type")]
  local note_ind=((9-row)+(4*(col-1))-1)%#tracks[params:get("track")].scale_notes+1
  local note=tracks[params:get("track")].scale_notes[note_ind]
  print(note)
  if on then 
    play_fn.note_on({duration_scaled=10,note_to_emit=note},{})
  elseif play_fn.note_off~=nil then  
    play_fn.note_off({note_to_emit=note})
  end
end


function GGrid:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
        if self.visualf[row][col]>0 and self.pressed_buttons[row..","..col]==nil then 
            local release=params:get(params:get("track").."monophonic_release")>0 and params:get(params:get("track").."monophonic_release") or params:get(params:get("track").."release")
            release=release/1000
            self.visualf[row][col]=self.visualf[row][col]-15/(release/self.grid_refresh.time)
            if self.visualf[row][col]<0 then 
                self.visualf[row][col]=0
            end
        end
        if self.visualf[row][col]>0 then
            self.visual[row][col]=util.round(self.visualf[row][col])
        else
            self.visual[row][col]=0
        end
    end
  end

  -- illuminate currently pressed button
  for k,_ in pairs(self.pressed_buttons) do
    local row,col=k:match("(%d+),(%d+)")
    if self.visualf[tonumber(row)][tonumber(col)]<15 then 
        self.visualf[tonumber(row)][tonumber(col)]=self.visualf[tonumber(row)][tonumber(col)]+15/(params:get(params:get("track").."attack")/1000/self.grid_refresh.time)
        if self.visualf[tonumber(row)][tonumber(col)]>15 then 
            self.visualf[tonumber(row)][tonumber(col)]=15
        end
    end
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
      if gd~=nil and gd[row]~=nil and gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()

end

return GGrid
