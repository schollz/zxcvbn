json=require("json")
parse_chain=require("parse_chain")
tli_=require("tli")
tli=tli_:new()
local data,err=tli:parse_tli([[
chain a 
w12
 
pattern a 
Cmaj7
  ]])

if err~=nil then
  print(err)
else
  print(json.encode(data))
end

for i,v in pairs(data.track) do
  print(i,json.encode(v))
end
