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

function recurse_line(t,line,pulses)

  print("recurse_line",line,pulses)
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
        (string.byte(c)>=string.byte("A") and string.byte(c)<=string.byte("G"))) then
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
    print(json.encode(parts),pulses)
    table.append(t,er(#parts,pulses,0))
    do return end
  end
  -- print(json.encode(parts),pulses,#parts)
  for _,part in ipairs(parts) do
    recurse_line(t,part,math.floor(pulses/#parts))
  end
end

local t={}
-- recurse_line(t,"(b c) a a",12)
-- recurse_line({},"a a",96)
recurse_line(t,"(a a a ) a a a",24)
s=""
for _,v in ipairs(t) do
  s=s..(v and "1" or "0")
end
print(s)
