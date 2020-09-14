local data = SkillBar.data
local event = SkillBar.event
local common = SkillBar.common


----------------------- class --------------------------
local class_enum =
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

local class = data:new(
   "nil",
   {
      valid = false,
      id = class_enum.NIL,
   }
)

function class:load()

   --print("class:load()")
   
   local _, name = UnitClass("player") -- second return matches class_enum
   self.id = class_enum[name]
   self.name = string.lower(name)

   self.valid = false
   local data = SkillBar[self.name]
   if (data) then
      self.valid = true
      self.data = data
      self.data:load()
   else
      print(string.format("SkillBar: unsupported class %s", self.name))
   end
   
end

function class:activate(spec)
   --print("class:activate()")
   if (self.valid) then
      for _,s in pairs(self.data.specs) do
	 event:deactivate(s)
	 if (s == spec) then
	    event:activate(s)
	 end
      end
   end
end

function class:update(now)
   --print("class:update()")
   if (self.valid) then
      self.data:update(now)
   end
end


----------------------- spec --------------------------
local spec_enum =
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

local spec = data:new(
   "nil",
   {
      valid = false,
      id = 0,
   }
)

function spec:load(class)

   --print("spec:load()")

   local current = GetSpecialization()
   self.id, self.name = GetSpecializationInfo(current)
   self.name = string.lower(self.name)

   self.valid = false
   if (class.valid) then
      
      class:activate(spec.name)
      
      local data = class.data[self.name]
      if (data) then
	 self.valid = true
	 self.data = data
	 self.data:load()
	 print(string.format("SkillBar: loaded %s", self.name))
      else
	 print(string.format("SkillBar: unsupported spec %s", self.name))
      end
      
   end

   -- PLAYER_TALENT_UPDATE fires before PLAYER_LOGIN
   -- so fire another one to update talents now that spec is active
   event:fire("PLAYER_TALENT_UPDATE")
   
   --event:printall()
   
end

function spec:update(now)
   --print("spec:update()")
   if (self.valid) then
      self.data:update(now)
   end
end


----------------------- driver --------------------------
local driver =
   {
      class = class,
      spec = spec,
   }

--perform initializtion here
function driver:playerlogin(event, foo, bar)
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
end
event:register(driver, "INTERNAL_UPDATE", driver.update)


----------------------- Skill Bar --------------------------
SkillBar.driver = driver
