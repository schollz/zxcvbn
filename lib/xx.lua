json=require("json")

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
    table.append(t,er(#parts,pulses,0))
    table.append(all_parts,entites)
    do return end
  end
  -- print(json.encode(parts),pulses,#parts)
  for _,part in ipairs(parts) do
    recurse_line(t,all_parts,part,math.floor(pulses/#parts))
  end
end

local t={}
local parts={}
local line="(a Z12 mi1 . h50) c"
print(line)
recurse_line(t,parts,line,36)
s=""
for _,v in ipairs(t) do
  s=s..(v and "1" or "0")
end
print(json.encode(parts))
print(s)