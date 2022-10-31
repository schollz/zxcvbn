local Archive={}

function Archive:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Archive:init()
    self.archive="TODO.zip"
end

function Archive:get_list()
    local s=util.os_capture(string.format("cd %s && zipinfo -1 %s",_path.data.."zxcvbn",self.archive_name))
    local lines={}
    for line in s:gmatch("[^\r\n]+") do
      line=self.trim(line)
      if #line>0 then
        table.insert(lines,line)
      end
    end
    return lines
end

function Archive:save_and_parse_pset()
 -- "5sample_file": /home/we/dust/data/zxcvbn/samples/Diver_Break_172_PL_key_bpm172_beats8_.flac

end

return Archive
