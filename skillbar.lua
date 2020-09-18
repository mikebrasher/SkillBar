----------------------- istable --------------------------
local function istable(obj)
   return obj and (type(obj) == "table")
end


----------------------- isfunction --------------------------
local function isfunction(obj)
   return obj and (type(obj) == "function")
end


----------------------- isstring --------------------------
local function isstring(obj)
   return obj and (type(obj) == "string")
end


----------------------- extends --------------------------
local function extends(parent)
   local child = {}
   setmetatable(child, parent)
   child.__index = child
   child.__super = parent
   return child
end


----------------------- embed --------------------------
local function embed(obj, data)
   if (istable(obj) and istable(data)) then
      for k,v in pairs(data) do
	 obj[k] = v
      end
   end
end


----------------------- checkcall --------------------------
local function checkcall(obj, fname, ...)
   --print(string.format("checkcall: %s", tostring(obj)))
   if (istable(obj) and isstring(fname)) then
      local func = obj[fname]
      --print(string.format("  func: %s", tostring(func)))
      if (isfunction(func)) then
	 return func(obj, ...)
      end
   end
end


----------------------- broadcast --------------------------
local broadcast = {}

function broadcast:skill(skill)
   if (WeakAuras and WeakAuras.ScanEvents) then
      WeakAuras.ScanEvents("SKILLBAR_SKILL_CHANGED", skill)
   end
end

function broadcast:clocktick(now)
   if (WeakAuras and WeakAuras.ScanEvents) then
      WeakAuras.ScanEvents("SKILLBAR_CLOCK_TICK", now)
   end
end


----------------------- iterate --------------------------
local function iterate(list, fname, ...)
   if (istable(list)) then
      --print(string.format("iterate: %s", list.name or tostring(list)))
      for _,obj in pairs(list) do
	 --print(string.format("  obj: %s", tostring(obj)))
	 checkcall(obj, fname, ...)
      end
   end
end


----------------------- Skill Bar --------------------------
SkillBar =
   {
      extends = extends,
      embed = embed,
      checkcall = checkcall,
      iterate = iterate,
      broadcast = broadcast,
   }
