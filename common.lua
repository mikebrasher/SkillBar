local extends = SkillBar.extends
local iterate = SkillBar.iterate
local prototype = SkillBar.prototype
local event = SkillBar.event

-- these are essentially static instances
-- no singleton pattern, just used that way

----------------------- player --------------------------
local player = extends(prototype.data)

function player:new()
   local o = player.__super.new(
      self,
      {
	 guid = "nil",
	 haste = 0,
      }
   )
   setmetatable(o, self)
   return o
end

function player:update(now)
   --print(string.format("player update: %f", now))
   player.__super.update(self, now)
   self.haste = UnitSpellHaste("player")
end

function player:load()
   --print("player load")
   player.__super.load(self)
   self.guid = UnitGUID("player")
   self:update(0)
end


----------------------- enemies --------------------------
local enemies = extends(prototype.data)

function enemies:new()
   local o = enemies.__super.new(
      self,
      {
	 melee = 0,
	 ranged = 0,
	 target = 
	    {
	       min = 0,
	       max = 0,
	       near5 = 0,
	       near10 = 0,
	    },
	 tanking = false,
      }
   )
   setmetatable(o, self)
   return o
end
   
function enemies:update(now)

   --print(string.format("enemies update: %f", now))
   enemies.__super.update(self, now)

   local target = self.target
   
   target.min = -999
   target.max = -999
   target.near5 = 0
   target.near10 = 0
   if (UnitExists("target") and (not UnitIsFriend("target", "player"))) then
      target.min, target.max = WeakAuras.GetRange("target") or -100, 100
   end
   
   self.melee = 0
   self.ranged = 0
   self.tanking = false
   for i = 1, 40 do
      local enemy = "nameplate" .. i
      if (UnitExists(enemy) and (not UnitIsFriend(enemy, "player"))) then
	 
	 local min, max = WeakAuras.GetRange(enemy) or -100, 100
	 
	 if (min <= 5) then
	    self.melee = self.melee + 1
	 end
	 
	 if (min <= 40) then
	    self.ranged = self.ranged + 1
	 end
	 
	 if ((min >= target.min - 5) and (max <= target.max + 5)) then
	    target.near5 = target.near5 + 1
	 end
	 
	 if ((min >= target.min - 10) and (max <= target.max + 10)) then
	    target.near10 = target.near10 + 1
	 end
	 
	 local status = UnitDetailedThreatSituation("player", enemy)
	 if (status) then
	    self.tanking = true
	 end
      end
   end
   
end


----------------------- casting --------------------------
local casting = extends(prototype.data)

function casting:new()
   local o = casting.__super.new(
      self,
      {
	 active = false,
	 spellID = 0,
	 startTimeMS = 0,
	 endTimeMS = 0,
	 duration = 0,
	 remaining = 0,
      }
   )
   setmetatable(o, self)
   return o
end

function casting:update(now)

   casting.__super.update(self, now)

   self.active = false
   name, _, _, startTimeMS, endTimeMS, _, _, _, spellID = UnitCastingInfo("player")
   if (spellID and startTimeMS and endTimeMS) then
      self.active = true
      self.spellID = spellID
      self.startTimeMS = startTimeMS
      self.endTimeMS = endTimeMS
      self.duration = (endTimeMS - startTimeMS) / 1000
      self.remaining = endTimeMS / 1000 - now
   end
   
end


----------------------- lastcast --------------------------
local lastcast = extends(prototype.data)
lastcast.gcd = { max = 0 } -- overwritten in gcd:load()

function lastcast:new()
   local o = lastcast.__super.new(
      self,
      {
	 active = false,
	 spellID = 0,
	 spellName = "nil",
	 timestamp = 0,
      }
   )
   setmetatable(o, self)
   return o
end

function lastcast:record(spellID, spellName)
   self.active = true
   self.spellID = spellID
   self.spellName = spellName
   self.timestamp = GetTime()
end

function lastcast:duration(now)
   return now - self.timestamp
end
    
function lastcast:update(now)

   --print(string.format("lastcast update: %f %d", now, self.spellID))
   lastcast.__super.update(self, now)
   
   local duration = self:duration(now)
   if (duration > self.gcd.max) then
      self.active = false
   end
   
end

function lastcast:cleu(event, timestamp, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName)
   --print(string.format("lastcast: %s %s", sourceGUID, subevent))
   if ((sourceGUID == UnitGUID("player")) and
      (subevent == "SPELL_CAST_SUCCESS")) then
      --print(string.format("lastcast spell success: %d", spellID))
      self:record(spellID, spellName)
   end
end


----------------------- gcd --------------------------
local gcd = extends(prototype.data)

function gcd:new()
   local o = gcd.__super.new(
      self,
      {
	 max = 1.5,
	 current = 1.5,
      }
   )
   setmetatable(o, self)
   return o
end

-- insert self into prototypes that need it.
-- using self instead of gcd ensures actual
-- instance ref is used when it's loaded
function gcd:load()
   gcd.__super.load(self)
   prototype.skill.gcd = self
   prototype.pandemicbuff.gcd = self
   lastcast.gcd = self
end
    
function gcd:update(now)
   
   gcd.__super.update(self, now)

   -- could reference player.haste, but then these would be order dependent
   local haste = UnitSpellHaste("player") / 100
   self.current = 1.5 / (1 + haste)
   
end


----------------------- common --------------------------
local common = extends(prototype.datalist)

function common:new()
   local o = common.__super.new(
      self,
      {
	 player = player:new(),
	 gcd = gcd:new(),
	 enemies = enemies:new(),
	 casting = casting:new(),
	 lastcast = lastcast:new(),
      }
   )
   setmetatable(o, self)
   return o
end

-- event registration needs to happen on instances
function common:load()

   common.__super.load(self)

   event:register(self.lastcast, "COMBAT_LOG_EVENT_UNFILTERED", self.lastcast.cleu)
   
end


----------------------- Skill Bar --------------------------
SkillBar.common = common:new()
