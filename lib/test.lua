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
C;4 b4 d4
Em
Am;3
F
 
  ]],false)

-- if err~=nil then
--   print(err)
-- else
--   print(json.encode(data))
-- end

for name,pattern in pairs(data.patterns) do
  print(name)
  local lines={}
  for _,position in ipairs(pattern.parsed.positions) do
    -- print(json.encode(position))
    -- print(position.stop)
    -- print(json.encode(position.parsed))
    if lines[position.line]==nil then
      lines[position.line]={}
    end
    for _,note in ipairs(position.parsed) do
      table.insert(lines[position.line],note.m%12)
    end
  end
  print(json.encode(lines))
end
