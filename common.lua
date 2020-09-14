local data = SkillBar.data
local event = SkillBar.event

----------------------- gcd --------------------------
local gcd =
   {
      max = 1.5,
      current = 1.5,
   }
    
function gcd:update()
   local haste = UnitSpellHaste("player") / 100.0
   self.current = 1.5 / (1 + haste)
end


----------------------- buff --------------------------
local buff = {}
buff.__index = buff
    
function buff:new(unit, buffID)
   
   local o = {
      unit = unit,
      buffID = buffID,
      active = false,
      count = 0,
      expirationTime = 0,
      remaining = 0,
   }
   setmetatable(o, self)
   return o
   
end

function buff:update(now)
   
   --print(string.format("Update - Unit: %s buffID: %d", self.unit, self.buffID))
   
   self.active = false
   self.count = 0
   self.expirationTime = 0
   self.remaining = 0
   
   for ibuff = 1, 40 do
      
      local name, _, count, _, duration, expirationTime, source, _, _, spellID, _, _, castByPlayer
	 = UnitAura(self.unit, ibuff, "PLAYER")
      
      --if (spellID and source) then
      --    print(string.format("unit: %s    spellID: %d    source: %s",
      --    self.unit, spellID, source))
      --end
      
      -- "PLAYER" filter can pass pets, so check source variable as well
      if (name and (source == "player")) then
	 
	 if (spellID == self.buffID) then
	    
	    self.active = true
	    self.count = count
	    self.expirationTime = expirationTime
	    self.remaining = expirationTime - now
	    
	    --print(string.format("  found: %d %s %d %5.2f",
	    --        self.buffID, tostring(self.active), self.count, self.remaining))
	    
	    break
	    
	 end
	 
      end
      
   end
   
end

function buff:display(now)
   return self.expirationTime - now
end


----------------------- pandemic buff --------------------------
local pandemicbuff = {}
setmetatable(pandemicbuff, buff)
pandemicbuff.__index = pandemicbuff
pandemicbuff.__super = getmetatable(pandemicbuff) -- hack to use "super" syntax
    
function pandemicbuff:updatethreshold()
   local desc = GetSpellDescription(self.pandemic.spellID) or ""
   self.pandemic.duration = tonumber(string.match(desc, 'over (%d*.?%d*) sec')) or -1
   self.pandemic.threshold = self.pandemic.duration * 0.3
end
    
-- buffID is the buff, spellID is the spell that caused the buff
-- might be the same, but probably not
function pandemicbuff:new(unit, buffID, spellID)
        
   -- need to call pandemicBuff.__super.new and not
   -- self.__super.new to avoid stack overflow
   local o = pandemicbuff.__super.new(self, unit, buffID)
   o.pandemic =
      {
	 spellID = spellID,
	 duration = 0,
	 threshold = 0,
	 active = false,
	 soon = false,
      }
   
   setmetatable(o, self)
   o:updatethreshold()
   
   return o
   
end

function pandemicbuff:update(now)
   
   pandemicbuff.__super.update(self, now)
   
   if (self.remaining and self.pandemic.threshold) then
      self.pandemic.active = self.remaining < self.pandemic.threshold
      self.pandemic.soon   = self.remaining < self.pandemic.threshold + gcd.current
   else
      local spellID = self.spellID or -1
      local remaining = self.remaining or -1
      local threshold = self.pandemic.threshold or -1
      print(string.format("spellID: %d remaining: %f threshold: %f", spellID, remaining, threshold))
   end
   
end


----------------------- target --------------------------
local target = {}
target.__index = index

function target:new()
   local o = 
      {
	 count = 0,
	 expirationTime = 0,
	 remaining = 0,
      }
   setmetatable(o, self)
   return o
end


----------------------- multitarget --------------------------
local multitarget = {}
multitarget.__index = multitarget

function multitarget:new(buffID)
   local o = {
      buffID = buffID,
      active = false,
      targets = {},
      count = 0,
      minremaining = nil,
   }
   setmetatable(o, self)
   return o
end

function multitarget:clear()
   self.active = false
   self.targets = {}
   self.count = 0
   self.minremaining = nil
end

function multitarget:update(now)

   self:clear()

   local totalcount = 0
   for iunit = 1, 40 do
      
      local unit = "nameplate" .. iunit
      
      -- target debuffs
      if (UnitExists(unit)) then -- and (not UnitIsEnemy("target", "player"))) then
	 
	 for ibuff = 1, 40 do
	    
	    local name, _, count, _, duration, expirationTime, source, _, _, spellID, _, _, castByPlayer
	       = UnitAura(unit, ibuff, "PLAYER")
	    
	    -- "PLAYER" filter can pass pets, so check source variable as well
	    if (name and (source == "player")) then
	       
	       if (spellID == self.buffID) then
		  
		  count = (count > 0) and count or 1 -- UnitAura returns 0 for non-stackable auras
		  
		  self.targets[unit] = self.targets[unit] or target:new()
		  local t = self.targets[unit]
		  t.count = count
		  t.expirationTime = expirationTime
		  t.remaining = expirationTime - now

		  totalcount = totalcount + count

		  if ((self.minremaining == nil) or
			(t.remaining < self.minremaining.remaining)
		  ) then
		     self.minremaining = t
		  end
		  
		  break
		  
	       end
	       
	    end
	    
	 end
	 
      end
      
   end

   self.count = totalcount
   self.active = totalcount > 0
   
end


----------------------- multi-target debuff --------------------------
local multitargetdebuff = {}
setmetatable(multitargetdebuff, buff)
multitargetdebuff.__index = multitargetdebuff
multitargetdebuff.__super = getmetatable(multitargetdebuff)
    
function multitargetdebuff:new(buffID)
   
   local o = multitargetdebuff.__super.new(self, "target", buffID)
   o.multitarget = multitarget:new(buffID)
   setmetatable(o, self)
   return o
   
end

function multitargetdebuff:update(now)
   multitargetdebuff.__super.update(self, now)
   self.multitarget:update(now)
end


----------------------- power --------------------------
local power =
   {
      unit = "player",
      type = Enum.PowerType.Mana,
      current = 0,
      max = 0,
      deficit = 0,
      unmodified = false,
   }
power.__index = power
    
function power:new(type, unmodified)
   local o =
      {
	 type = type,
	 unmodified = unmodified or false,
	 
      }
   setmetatable(o, self)
   return o
end

function power:update()
   self.current = UnitPower(self.unit, self.type, self.unmodified)
   self.max = UnitPowerMax(self.unit, self.type, self.unmodified)
   self.deficit = self.max - self.current
end


----------------------- skill --------------------------
local charges = 
   {
      current = 0,
      max = 0,
      capped = false,
   }

function charges:update(name)
   self.current, self.max = GetSpellCharges(name)
   self.capped = false
   if (self.current and self.max) then
      self.capped = self.current >= self.max
   end
end

local skill =
   {
      spellID = 0,
      name = "",
      charges = charges,
      cd = 0,
   }
skill.__index = skill

function skill:new(spellID)
   local o =
      {
	 spellID = spellID,
	 name = GetSpellInfo(spellID),
      }
   setmetatable(o, self)
   return o
end

function skill:update(now)
   
   -- need to check by name to respect talents for some reason
   local usable = IsUsableSpell(self.name)
   
   local start, duration, enabled = GetSpellCooldown(self.name)
   self.cd = 0
   if (start and duration) then
      if (start > 0 and duration > 0) then
	 self.cd = start + duration - now
      end
   end

   self.usable = usable and (self.cd <= gcd.current)
   self.charges:update(self.name)
   
end


----------------------- enemies --------------------------
local enemies =
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

function enemies:update()
   
   local target = self.target
   
   target.min = -999
   target.max = -999
   target.near5 = 0
   target.near10 = 0
   if (UnitExists("target") and (not UnitIsFriend("target", "player"))) then
      target.min, target.max = WeakAuras.GetRange("target") or -100, 100
   end
   
   enemies.melee = 0
   enemies.ranged = 0
   enemies.tanking = false
   for i = 1, 40 do
      local enemy = "nameplate" .. i
      if (UnitExists(enemy) and (not UnitIsFriend(enemy, "player"))) then
	 
	 local min, max = WeakAuras.GetRange(enemy) or -100, 100
	 
	 if (max <= 5) then
	    enemies.melee = enemies.melee + 1
	 end
	 
	 if (max <= 40) then
	    enemies.ranged = enemies.ranged + 1
	 end
	 
	 if ((min >= target.min - 5) and (max <= target.max + 5)) then
	    target.near5 = target.near5 + 1
	 end
	 
	 if ((min >= target.min - 10) and (max <= target.max + 10)) then
	    target.near10 = target.near10 + 1
	 end
	 
	 local status = UnitDetailedThreatSituation("player", enemy)
	 if (status) then
	    enemies.tanking = true
	 end
      end
   end
   
end


----------------------- casting --------------------------
local casting =
   {
      spellID = 0,
      startTimeMS = 0,
      endTimeMS = 0,
      duration = 0,
      remaining = 0,
   }

function casting:update(now)
   
   name, _, _, startTimeMS, endTimeMS, _, _, _, spellID = UnitCastingInfo("player")
   if (spellID and startTimeMS and endTimeMS) then
      casting.spellID = spellID
      casting.startTimeMS = startTimeMS
      casting.endTimeMS = endTimeMS
      casting.duration = (endTimeMS - startTimeMS) / 1000
      casting.remaining = endTimeMS / 1000 - now
   else
      casting.spellID = 0
      casting.startTimeMS = 0
      casting.endTimeMS = 0
      casting.duration = 0
      casting.remaining = 0
   end
   
end


----------------------- lastcast --------------------------
local lastcast =
   {
      active = false,
      spellID = 0,
      spellName = "nil",
      timestamp = 0,
   }

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
   local duration = self:duration(now)
   if (duration > gcd.max) then
      self.active = false
   end
end

function lastcast:cleu(event, timestamp, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName)
   --print(string.format("lastcast: %s %s", sourceGUID, subevent))
   if ((sourceGUID == UnitGUID("player")) and
      (subevent == "SPELL_CAST_SUCCESS")) then
      --print(string.format("spellID = %d", spellID))
      self:record(spellID, spellName)
   end
end
event:register(lastcast, "COMBAT_LOG_EVENT_UNFILTERED", lastcast.cleu)


----------------------- common --------------------------
local common = data:new(
   "common",
   {
      gcd = gcd,
      buff = buff,
      pandemicbuff = pandemicbuff,
      multitargetdebuff = multitargetdebuff,
      power = power,
      skill = skill,
      timer = timer,
      enemies = enemies,
      casting = casting,
      lastcast = lastcast,
   }
)

function common:broadcastskill(skill)
   if (WeakAuras and WeakAuras.ScanEvents) then
      WeakAuras.ScanEvents("SKILLBAR_SKILL_CHANGED", skill)
   end
end

function common:broadcasttimer(now)
   if (WeakAuras and WeakAuras.ScanEvents) then
      WeakAuras.ScanEvents("SKILLBAR_CLOCK_TICK", now)
   end
end

function common:update(now)
   gcd:update()
   enemies:update()
   casting:update(now)
   lastcast:update(now)
   self:broadcasttimer(now)
end


----------------------- Skill Bar --------------------------
SkillBar.common = common
