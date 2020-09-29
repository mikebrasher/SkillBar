local extends = SkillBar.extends
local iterate = SkillBar.iterate

-- extend prototypes if overriding or adding methods
-- create new instance if just want to use existing methods

-- using convention that extending classes call these super
-- functions, and instances of data just override


----------------------- data --------------------------
-- this is an abstract interface object
-- don't put any code here
local data = {}
data.__index = data
-- static data defined here, i.e.
-- data.staticvar = "foo"

-- new function should only: create table or use
-- supplied object, set the metatable, and return.
-- define all fields here with default values
function data:new(obj)
   local o = obj or {}
   setmetatable(o, self)
   return o
end

-- further initialization that needs logic or wow calls
function data:load()
   --stub
end

-- per tick update function, just ignore now argument if not needed
function data:update(now)
   --stub
end


----------------- datalist ------------------
-- this is a collection of data objects that can be
-- automatically iterated over
local datalist = extends(data)

function datalist:new(obj)
   local o = datalist.__super.new(self, obj)
   setmetatable(o, self)
   return o
end

function datalist:load()
   datalist.__super.load(self)
   iterate(self, "load")
end

function datalist:update(now)
   datalist.__super.update(self, now)
   iterate(self, "update", now)
end


----------------------- class --------------------------
-- base class for all class definitions
-- has a name, defines specs, but does not iterate over all contained data
-- override load/update in each class to avoid automatically updating
-- every spec when class is loaded/updated
local class = extends(data)

function class:new(name, specs, obj)
   local o = class.__super.new(self, obj)
   o.name = name
   o.specs = specs
   setmetatable(o, self)
   return o
end


----------------------- spec --------------------------
-- base class for all spec definitions
-- has a name and iterates over all contained data
local spec = extends(datalist)

function spec:new(name, obj)
   local o = spec.__super.new(self, obj)
   o.name = name
   setmetatable(o, self)
   return o
end

function spec:register(obj, event, func)
   SkillBar.event:register(obj, event, func, self.name)
end

function spec:load()

   spec.__super.load(self)
   
   if (self.talents and self.talents.playertalentupdate) then
      self:register(self.talents, "PLAYER_TALENT_UPDATE", self.talents.playertalentupdate)
   end

   if (self.target_debuffs and self.target_debuffs.updatethreshold) then
      self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", self.target_debuffs.updatethreshold)
   end

end


----------------------- buff --------------------------
local buff = extends(data)

function buff:new(unit, buffID)
   local o = buff.__super.new(
      self,
      {
	 unit = unit,
	 mask = nil,
	 buffID = buffID,
	 active = false,
	 count = 0,
	 expirationTime = 0,
	 remaining = 0,
      }
   )
   setmetatable(o, self)
   return o
end

function buff:load()
   buff.__super.load(self)
   self.mask = "HELPFUL|PLAYER"
   if (self.unit == "target") then
      self.mask = "HARMFUL|PLAYER"
   end
end

function buff:update(now)

   buff.__super.update(self, now)
   
   --print(string.format("Update - unit: %s mask: %s buffID: %d", self.unit, self.mask, self.buffID))
   
   self.active = false
   self.count = 0
   self.expirationTime = 0
   self.remaining = 0
   
   for ibuff = 1, 40 do
      
      local name, _, count, _, duration, expirationTime, source, _, _, spellID, _, _, castByPlayer
	 = UnitAura(self.unit, ibuff, self.mask)
      
      --if (spellID and source) then
      --    print(string.format("unit: %s    spellID: %d    source: %s",
      --    self.unit, spellID, source))
      --end
      
      if (name and (source == "player")) then
	 
	 if (spellID == self.buffID) then
	    
	    self.active = true
	    self.count = count
	    self.expirationTime = expirationTime
	    self.remaining = expirationTime - now
	    
	    --print(string.format("  found: %d %s %d %5.2f",
	    --      self.buffID, tostring(self.active), self.count, self.remaining))
	    
	    break
	    
	 end
	 
      end
      
   end
   
end

function buff:display(now)
   return self.expirationTime - now
end


----------------------- pandemic buff --------------------------
local pandemicbuff = extends(buff)
pandemicbuff.gcd = { current = 0 } -- placeholder
    
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
   return o
   
end
    
function pandemicbuff:updatethreshold()
   local desc = GetSpellDescription(self.pandemic.spellID) or ""
   self.pandemic.duration = tonumber(string.match(desc, 'over (%d*.?%d*) sec')) or -1
   self.pandemic.threshold = self.pandemic.duration * 0.3
end

function pandemicbuff:load()
   pandemicbuff.__super.load(self)
   self:updatethreshold()
end

function pandemicbuff:update(now)
   
   pandemicbuff.__super.update(self, now)

   if (self.remaining and self.pandemic.threshold) then
      self.pandemic.active = self.remaining < self.pandemic.threshold
      self.pandemic.soon   = self.remaining < self.pandemic.threshold + self.gcd.current
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
	       = UnitAura(unit, ibuff, "HARMFUL|PLAYER")
	    
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
local multitargetdebuff = extends(buff)
    
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


----------------- target_debuffs ------------------
local target_debuffs = extends(datalist)

function target_debuffs:new(obj)
   local o = target_debuffs.__super.new(self, obj)
   setmetatable(o, self)
   return o
end

function target_debuffs:updatethreshold()
   iterate(self, "updatethreshold")
end


----------------------- power --------------------------
local power = extends(data)

function power:new(type, unmodified)
   local o = power.__super.new(
      self,
      {
	 unit = "player",
	 type = type or Enum.PowerType.Mana,
	 unmodified = unmodified or false,
	 current = 0,
	 max = 0,
	 deficit = 0,
      }
   )
   setmetatable(o, self)
   return o
end

function power:update(now)
   power.__super.update(self, now)
   self.current = UnitPower(self.unit, self.type, self.unmodified)
   self.max = UnitPowerMax(self.unit, self.type, self.unmodified)
   self.deficit = self.max - self.current
end


----------------------- skill --------------------------
local skill = extends(data)
skill.gcd = { current = 0 } -- placeholder reference overwritten in gcd:load

function skill:new(spellID)
   local o = skill.__super.new(
      self,
      {
	 spellID = spellID,
	 name = "nil",
	 cd = 0,
	 charges =
	    {
	       current = 0,
	       max = 0,
	       capped = false,
	    },
      }
   )
   setmetatable(o, self)
   return o
end

function skill:load()
   skill.__super.load(self)
   self.name = GetSpellInfo(self.spellID)
   --print(string.format("Skill Load: %06d %s", self.spellID, tostring(self.name)))
end

function skill:updatecharges()

   local charges = self.charges
   
   charges.current, charges.max = GetSpellCharges(self.name)
   charges.capped = false
   if (charges.current and charges.max) then
      charges.capped = charges.current >= charges.max
   end
   
end

function skill:update(now)

   skill.__super.update(self, now)

   -- need to check by name to respect talents for some reason
   local usable = IsUsableSpell(self.name)
   
   local start, duration, enabled = GetSpellCooldown(self.name)
   self.cd = 0
   if (start and duration) then
      if (start > 0 and duration > 0) then
	 self.cd = start + duration - now
      end
   end

   self.usable = usable and (self.cd <= self.gcd.current)

   self:updatecharges()
   
end


----------------------- prototype --------------------------
local prototype =
   {
      data = data,
      datalist = datalist,
      class = class,
      spec = spec,
      talents = talents,
      buff = buff,
      pandemicbuff = pandemicbuff,
      multitargetdebuff = multitargetdebuff,
      target_debuffs = target_debuffs,
      power = power,
      skill = skill,
   }


----------------------- Skill Bar --------------------------
SkillBar.prototype = prototype
