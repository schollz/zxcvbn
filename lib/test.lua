json=require("json")
parse_chain=require("parse_chain")
tli_=require("tli")
tli=tli_:new()

print(json.encode(tli.numdashcom("3-100")))
print(json.encode(tli.numdashcomr("3-100")))
print(json.encode(tli.numdashcomr("3-100")))
print(json.encode(tli.numdashcomr("3-100")))
print(json.encode(tli.numdashcomr("3-100")))
print(json.encode(tli.numdashcomr("3-100")))
-- local data,err=tli:parse_tli([[
-- chain a*3

-- w48

-- pattern a
-- 0 w48 a 4 b
-- 0 d n-8 4 1
-- b 4 0 c x4
--   ]],true)

-- if err~=nil then
--   print(err)
-- else
--   print(json.encode(data))
-- end

-- for i,v in pairs(data.track) do
--   print(i,json.encode(v))
-- end

