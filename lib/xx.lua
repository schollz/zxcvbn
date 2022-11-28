json=require("json")


function calc(s)
  -- returns ok, val
  return pcall(assert(loadstring("return "..s)))
end

calc_p=function(s)
    s=s:gsub("m","96")
    s=s:gsub("h","48")
    s=s:gsub("q","24")
    s=s:gsub("s","12")
    s=s:gsub("e","6")
    return calc(s)
end

function table.append(t1,t2)
  for i=1,#t2 do
    t1[#t1+1]=t2[i]
  end
end

trim=function(s)
  return (s:gsub("^%s*(.-)%s*$","%1"))
end
er=function(k,n,w)
  w=w or 0
  -- results array, intially all zero
  local r={}
  for i=1,n do r[i]=false end

  if k<1 then return r end

  -- using the "bucket method"
  -- for each step in the output, add K to the bucket.
  -- if the bucket overflows, this step contains a pulse.
  local b=n
  for i=1,n do
    if b>=n then
      b=b-n
      local j=i+w
      while (j>n) do
        j=j-n
      end
      while (j<1) do
        j=j+n
      end
      r[j]=true
    end
    b=b+k
  end
  return r
end

function recurse_line(t,all_parts,line,pulses)
  --print("recurse_line",line,pulses)
  line=trim(line)
  local par_count=0
  local has_par=false
  local parts={}
  local part=""
  for i=1,#line do
    local c=line:sub(i,i)
    if c=="(" then
      if par_count==0 and part~="" then
        table.insert(parts,part)
        part=""
      end
      par_count=par_count+1
      has_par=true
      if par_count~=1 then
        part=part..c
      end
    elseif c==")" then
      par_count=par_count-1
      if par_count~=0 then
        part=part..c
      elseif par_count==0 then
        table.insert(parts,part)
        part=""
      end
    else
      if par_count==0 and
        ((string.byte(c)>=string.byte("a") and string.byte(c)<=string.byte("g")) or
        (string.byte(c)>=string.byte("A") and string.byte(c)<=string.byte("G")) or 
        c=="." or c=="-") then
        part=trim(part)
        if part~="" then
          table.insert(parts,part)
        end
        part=c
      else
        part=part..c
      end
    end
  end
  part=trim(part)
  if part~="" then
    table.insert(parts,part)
  end
  if not string.find(line,"%(") then
    local entites={}
    for _, part in ipairs(parts) do 
      local e=""
      local mods={}
      local i=1
      for w in part:gmatch("%S+") do
        if i==1 then 
          e=w
        else
          local d=w:sub(1,1)
          table.insert(mods,{d,tonumber(w:sub(2)) or w:sub(2)})
        end
        i=i+1
      end
      table.insert(entites,{e=e,mods=mods})
    end
    print(json.encode(entites),pulses)
    local shift=0
    for _, part in ipairs(entites) do 
      for _, mod in ipairs(part.mods) do
        if mod[1]=="o" and tonumber(mod[2])~=nil then
          shift=mod[2]
        end
      end
    end
    table.append(t,er(#parts,pulses,shift))
    table.append(all_parts,entites)
    do return end
  end
  -- print(json.encode(parts),pulses,#parts)
  for _,part in ipairs(parts) do
    recurse_line(t,all_parts,part,math.floor(pulses/#parts))
  end
end

function parse_positions(lines,default_pulses)
  local elast=nil
  local entities={}
  local pulse_index=0
  local pulses=default_pulses or 24*4 
  for _, line in ipairs(lines) do 
    -- <line>
    -- determine if there is a nuew number of pulses
    for w in line:gmatch("%S+") do
      local c=w:sub(1,1)
      if c=="p" then
        local ok,vv=calc_p(w:sub(2))
        if vv==nil or (not ok) then
          error(string.format("bad '%s'",w))
        end
        pulses=vv
      end
    end
    local pos={}
    local ele={}
    recurse_line(pos,ele,line,pulses)
    s=""
    for _,v in ipairs(pos) do
      s=s..(v and "1" or "0")
    end
    print(s)
    local ei=0
    for pi,p in ipairs(pos) do
      pulse_index=pulse_index+1
      if p then
        if elast~=nil and ele[ei+1].e~="-" then
          table.insert(entities,{el=elast.el,
              start=elast.start,
              stop=pulse_index,
              mods=elast.mods,
              line=elast.line})
          mods=nil
          elast=nil
        end
        if ele[ei+1].e~="-" then
          elast={el=ele[ei+1].e,start=pulse_index,mods=ele[ei+1].mods,line=i}
        end
        ei=ei+1
      end
    end
    
    -- </line>
  end
  if elast~=nil then
    table.insert(entities,{el=elast.el,
        start=elast.start,
        stop=pulse_index+1,
        mods=elast.mods,
        line=elast.line})
    elast=nil
  end

  return entities,pulse_index
end

local e,p=parse_positions({"(a o1 p8 Z12 mi1 . h50) c o2","(a p32 a a a) - . d"},64)
for _, f in ipairs(e) do 
  print(json.encode(f))
end
print(json.encode(p))

