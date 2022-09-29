json=require("json")
parse_chain=require("parse_chain")
tli_=require("tli")
d
tli=tli_:new()
local data,err=tli:parse_tli([[
chain (b b a)*2 a

pattern b
C#m7
pattern a
d3
  ]])

if err ~= nil then 
    print("error",err)
else
    for i,v in ipairs(data.track) do
    if next(v.on)~=nil then 
        print(i,json.encode(v.on))
    end
    end
end