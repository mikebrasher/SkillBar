local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common

local skillbar_color = "FF8D1428"


----------------------- class --------------------------
-- driver version of class, different from prototype.class
-- an instance of prototype.class ends up as class.data here
local class = extends(prototype.data)
class.enum = 
   {
      NIL = 0,
      WARRIOR = 1,
      PALADIN = 2,
      HUNTER = 3,
      ROGUE = 4,
      PRIEST = 5,
      DEATHKNIGHT = 6,
      SHAMAN = 7,
      MAGE = 8,
      WARLOCK = 9,
      MONK = 10,
      DRUID = 11,
      DEMONHUNTER = 12,
   }

function class:new()
   local o = class.__super.new(
      self,
      {
	 valid = false,
	 id = self.enum.NIL,
	 name = "foo",
	 data = {},
      }
   )
   setmetatable(o, self)
   return o
end

function class:load()

   --print("class:load()")
   class.__super.load(self)
   
   local _, name = UnitClass("player") -- second return matches enum
   self.id = self.enum[name]
   self.name = string.lower(name)

   self.valid = false
   local data = SkillBar[self.name]
   if (data) then
      self.valid = true
      self.data = data
      self.data:load()
   else
      print(string.format("|c%sSkillBar:|r unsupported class %s", skillbar_color, self.name))
   end
   
end

function class:deactivate()
   --print("class:deactivate()")
   if (self.valid) then
      for _,s in pairs(self.data.specs) do
	 event:deactivate(s)
      end
   end
end

function class:activate(spec)
   --print("class:activate()")
   if (self.valid) then
      for _,s in pairs(self.data.specs) do
	 if (s == spec) then
	    event:activate(s)
	 end
      end
   end
end

function class:update(now)

   --print("class:update()")
   class.__super.update(self, now)

   if (self.valid) then
      self.data:update(now)
   end
   
end


----------------------- spec --------------------------
local spec = extends(prototype.data)
spec.enum =
   {
      deathknight =
	 {
	    BLOOD = 250,
	    FROST = 251,
	    UNHOLY = 252,
	 },
      demonhunter =
	 {
	    HAVOC = 577,
	    VENGEANCE = 581,
	 },
      druid =
	 {
	    BALANCE = 102,
	    FERAL = 103,
	    GUARDIAN = 104,
	    RESTORATION = 105,
	 },
      hunter =
	 {
	    BEAST_MASTERY = 253,
	    MARKSMANSHIP = 254,
	    SURVIVAL = 255,
	 },
      mage =
	 {
	    ARCANE = 62,
	    FIRE = 63,
	    FROST = 64,
	 },
      monk =
	 {
	    BREWMASTER = 268,
	    WINDWALKER = 269,
	    MISTWEAVER = 270,
	 },
      paladin =
	 {
	    HOLY = 65,
	    PROTECTION = 66,
	    RETRIBUTION = 70,
	 },
      priest =
	 {
	    DISCIPLINE = 256,
	    HOLY = 257,
	    SHADOW = 258,
	 },
      rogue =
	 {
	    ASSASSINATION = 259,
	    OUTLAW = 260,
	    SUBTLETY = 261,
	 },
      shaman =
	 {
	    ELEMENTAL = 262,
	    ENHANCEMENT = 263,
	    RESTORATION = 264,
	 },
      warlock =
	 {
	    AFFLICTION = 265,
	    DEMONOLOGY = 266,
	    DESTRUCTION = 267,
	 },
      warrior =
	 {
	    ARMS = 71,
	    FURY = 72,
	    PROTECTION = 73,
	 },
   }

function spec:new()
   local o = spec.__super.new(
      self,
      {
	 valid = false,
	 id = 0,
	 name = "nil",
	 data = {},
      }
   )
   setmetatable(o, self)
   return o
end

function spec:load(class)

   --print("spec:load()")
   spec.__super.load(self)

   local current = GetSpecialization()
   self.id, self.name = GetSpecializationInfo(current)
   self.name = string.lower(self.name)

   self.valid = false
   if (class.valid) then
      
      class:deactivate()
      
      local data = class.data[self.name]
      if (data) then
	 
	 self.valid = true
	 self.data = data
	 self.data:load()

	 class:activate(self.name)
	 print(string.format("|c%sSkillBar:|r loaded %s", skillbar_color, self.name))
	 
      else
	 print(string.format("|c%sSkillBar:|r unsupported spec %s", skillbar_color, self.name))
      end
      
   end

   -- PLAYER_TALENT_UPDATE fires before PLAYER_LOGIN
   -- so fire another one to update talents now that spec is active
   event:fire("PLAYER_TALENT_UPDATE")
   
   --event:printall()
   
end

function spec:update(now)
   
   --print("spec:update()")
   spec.__super.update(self, now)

   if (self.valid) then
      self.data:update(now)
   end

end


----------------------- driver --------------------------
local driver = 
   {
      class = class:new(),
      spec = spec:new(),
   }

--perform initializtion here
function driver:playerlogin(event, foo, bar)
   --print("driver load")
   common:load()
   self.class:load()
   self.spec:load(self.class)
end
event:register(driver, "PLAYER_LOGIN", driver.playerlogin)

function driver:specchanged(event, unit)
   --print(string.format("driver:specchanged: %s %s", event, unit))
   if (unit == "player") then
      self.spec:load(self.class)
   end
end
event:register(driver, "PLAYER_SPECIALIZATION_CHANGED", driver.specchanged)

function driver:update(event, now)
   
   --print(string.format("driver: %s %f", event, now))
   
   common:update(now)
   self.class:update(now)
   self.spec:update(now)

   broadcast:clocktick(now)
   
end
event:register(driver, "INTERNAL_UPDATE", driver.update)


----------------------- Skill Bar --------------------------
SkillBar.driver = driver
