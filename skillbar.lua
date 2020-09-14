----------------------- data --------------------------
local data = {}
data.__index = data

function data:new(name, o)
   local o = o or {}
   o.name = name
   setmetatable(o, self)
   return o
end

function data:load()
   -- stub
end

function data:update(now)
   -- stub
end


----------------------- Skill Bar --------------------------
SkillBar = { data = data }
