json=require("json")
parse_chain=require("parse_chain")
tli_=require("tli")
tli=tli_:new()

-- print(json.encode(tli.numdashcom("3-100")))
-- print(json.encode(tli.numdashcomr("3-100")))
-- print(json.encode(tli.numdashcomr("3-100")))
-- print(json.encode(tli.numdashcomr("3-100")))
-- print(json.encode(tli.numdashcomr("3-100")))
-- print(json.encode(tli.numdashcomr("3-100")))
local data,err=tli:parse_tli([[
chain a
 
pattern a
g1b1e1
Em
  ]],false)

if err~=nil then
  print(err)
else
  print(json.encode(data))
end

for i,v in pairs(data.track) do
  print(i,json.encode(v))
end

