json=require("json")
parse_chain=require("parse_chain")
tli_=require("tli")
tli=tli_:new()
local data,err=tli:parse_tli([[
chain a b
 
w12
 
pattern b
C#m7 ru s3 t8
pattern a
d3 d4 
c3
  ]])
print(json.encode(data))

for i,v in pairs(data.track) do
  print(i,json.encode(v))
end
