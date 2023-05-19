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
   o.name = name or "nil"
   setmetatable(o, self)
   return o
end

function spec:register(obj, event, func)
   SkillBar.event:register(obj, event, func, self.name)
end

function spec:load()

   --print(string.format("spec:load(%s)", self.name))

   spec.__super.load(self)
   
   if (self.talents and self.talents.playertalentupdate) then
      --print("registering playertalentupdate")
      self:register(self.talents, "PLAYER_TALENT_UPDATE", self.talents.playertalentupdate)
   end
   
   if (self.traits and self.traits.traitconfigupdated) then
      --print("registering trait config updated")
      self:register(self.traits, "TRAIT_CONFIG_UPDATED", self.traits.traitconfigupdated)
      self:register(self.traits, "PLAYER_TALENT_UPDATE", self.traits.traitconfigupdated)
   end

   --[[
   if (self.player_buffs and self.player_buffs.updatethreshold) then
      --print("registering player_buffs.updatethreshold")
      -- spell description update seems delayed after talent changes, so just check on combat
      --self:register(self.player_buffs, "PLAYER_TALENT_UPDATE", self.player_buffs.updatethreshold)
      self:register(self.player_buffs, "PLAYER_REGEN_DISABLED", self.player_buffs.updatethreshold)
   end

   if (self.target_debuffs and self.target_debuffs.updatethreshold) then
      --print("registering target_debuffs.updatethreshold")
      --self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", self.target_debuffs.updatethreshold)
      self:register(self.target_debuffs, "PLAYER_REGEN_DISABLED", self.target_debuffs.updatethreshold)
   end
   --]]

end


----------------------- buff --------------------------
local buff = extends(data)

function buff:new(unit, buffID, mask)
   local o = buff.__super.new(
      self,
      {
	 unit = unit,
	 buffID = buffID,
	 mask = mask,
	 active = false,
	 count = 0,
	 duration = 0,
	 expirationTime = 0,
	 remaining = 0,
	 extra = {},
      }
   )
   setmetatable(o, self)
   return o
end

function buff:load()
   
   buff.__super.load(self)

   -- default behavior is player buff, target debuff
   -- but don't override mask if supplied
   if (self.mask == nil) then
      self.mask = "HELPFUL|PLAYER"
      if (self.unit == "target") then
	 self.mask = "HARMFUL|PLAYER"
      end
   end
   
end

function buff:update(now)

   buff.__super.update(self, now)
   
   --print(string.format("Update - unit: %s mask: %s buffID: %d", self.unit, self.mask, self.buffID))
   
   self.active = false
   self.count = 0
   self.duration = 0
   self.expirationTime = 0
   self.remaining = 0
   self.extra[1] = 0
   self.extra[2] = 0
   self.extra[3] = 0
   
   for ibuff = 1, 40 do
      
      local name, _, count, _, duration, expirationTime, source, _, _, spellID, _, _, castByPlayer, extra1, extra2, extra3
	 = UnitAura(self.unit, ibuff, self.mask)
      
      --if (spellID and source) then
      --    print(string.format("unit: %s    spellID: %d    source: %s",
      --    self.unit, spellID, source))
      --end
      
      if (name and (source == "player")) then
	 
	 if (spellID == self.buffID) then
	    
	    self.active = true
	    self.count = count
	    self.duration = duration
	    self.expirationTime = expirationTime
	    self.remaining = expirationTime - now
	    self.extra[1] = extra1
	    self.extra[2] = extra2
	    self.extra[3] = extra3
	    
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


----------------------- buff list --------------------------
--[[
local bufflist = extends(datalist)

function bufflist:new(obj)
   local o = bufflist.__super.new(self, obj)
   setmetatable(o, self)
   return o
end

function bufflist:updatethreshold()
   --print(string.format("update threshold on %s", tostring(self)))
   iterate(self, "updatethreshold")
end
--]]


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
	 updatethreshold = false,
	 duration = 0,
	 threshold = 0,
	 active = false,
	 soon = false,
      }
   setmetatable(o, self)
   return o
   
end

--[[
function pandemicbuff:updatethreshold()
   --print("pandemic:updatethreshold()")
   self.pandemic.description = GetSpellDescription(self.pandemic.spellID) or ""
   self.pandemic.duration = tonumber(string.match(self.pandemic.description, 'over (%d*.?%d*) sec')) or -1
   self.pandemic.threshold = self.pandemic.duration * 0.3
end
--]]

--[[
function pandemicbuff:load()
   pandemicbuff.__super.load(self)
   self:updatethreshold()
end
--]]

function pandemicbuff:update(now)
   
   pandemicbuff.__super.update(self, now)

   local pandemic = self.pandemic

   if (self.active) then
      
      if (pandemic.updatethreshold) then
	 pandemic.duration = self.duration
	 pandemic.threshold = 0.3 * self.pandemic.duration
      end
      
      pandemic.active = self.remaining < pandemic.threshold
      pandemic.soon = self.remaining < pandemic.threshold + 2 * self.gcd.current

   else

      pandemic.active = true
      pandemic.soon = true
      
   end

   pandemic.updatethreshold = not self.active
   
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
	 percent = 0,
	 capped = false,
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
   self.percent = 100 * self.current / self.max
   self.capped = self.current >= self.max
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
	 basecooldown = 0,
	 cd = 0,
	 casttime = 0,
	 charges =
	    {
	       current = 0,
	       max = 0,
	       start = 0,
	       duration = 0,
	       capped = false,
	       partial = 0,
	       missing = 0,
	       timetocap = 0,
	    },
      }
   )
   setmetatable(o, self)
   return o
end

function skill:load()
   skill.__super.load(self)
   self.name = GetSpellInfo(self.spellID)
   local bcd = (GetSpellBaseCooldown(self.spellID) or -1000) / 1000
   --print(string.format("Skill Load: %06d %s %s", self.spellID, tostring(self.name), bcd))
   self.basecooldown = bcd --GetSpellBaseCooldown(self.spellID) / 1000
end

function skill:updatecharges(now)

   local charges = self.charges

   local current, max, start, duration = GetSpellCharges(self.spellID)  -- name)

   charges.current = current
   charges.max = max
   charges.start = start
   charges.duration = duration
   
   if (current and max and start and duration) then
      
      charges.capped = charges.current >= charges.max
      
      local partial = (current < max) and (now - start) / duration or 0
      local missing = max - current - partial
      
      charges.partial = partial
      charges.missing = missing
      charges.timetocap = missing * duration

   end
   
end

function skill:update(now)

   skill.__super.update(self, now)

   -- need to check by name to respect talents for some reason
   if (self.name) then
      
      local usable = IsUsableSpell(self.spellID)  -- name)
      
      --print(string.format("skill:update(%s): %f", self.name, now))
      local start, duration, enabled = GetSpellCooldown(self.spellID)  -- name)
      self.cd = 0
      if (start and duration) then
	 if (start > 0 and duration > 0) then
	    self.cd = start + duration - now
	 end
      end
      
      self.usable = usable and (self.cd <= self.gcd.current)

      self.casttime = select(4, GetSpellInfo(self.spellID)) / 1000
      
      self:updatecharges(now)
      
   end
   
end


----------------- execute skill ------------------
local executeskill = extends(skill)

function executeskill:new(spellID, threshold)
   --print("executeskill:new(" .. spellID .. ", " .. threshold .. ")")
   local o = executeskill.__super.new(self, spellID)
   o.threshold = threshold or 0.2
   o.execute_phase = false
   setmetatable(o, self)
   return o
end

function executeskill:update(now)
   
   executeskill.__super.update(self, now)
   
   local fraction = 1
   if (UnitExists("target")) then
      local health = UnitHealth("target")
      local max = UnitHealthMax("target")
      fraction = health / max
   end

   --print("threshold: " .. tostring(self.threshold))
   self.execute_phase = fraction <= self.threshold
   
end


----------------------- talent --------------------------
local talent = extends(data)

function talent:new(row, col)
   local o = talent.__super.new(
      self,
      {
	 row = row,
	 col = col,
	 selected = false,
      }
   )
   setmetatable(o, self)
   return o
end

function talent:gettalentinfo()
   self.selected = select(4, GetTalentInfo(self.row, self.col, 1))
end


----------------------- pvp talent --------------------------
local pvptalent = extends(data)

function pvptalent:new(talentID)
   local o = talent.__super.new(
      self,
      {
	 talentID = talentID,
	 selected = false,
      }
   )
   setmetatable(o, self)
   return o
end

function pvptalent:gettalentinfo()

   --[[
   local talentID, name, icon, selected, available, spellID, unlocked, row, column, known, grantedByAura
      = GetPvpTalentInfoByID(self.talentID)
   print("pvptalent:gettalentinof()")
   print("  talentID = " .. talentID)
   print("  name = " .. name)
   print("  icon = " .. icon)
   print("  selected = " .. tostring(selected))
   print("  available = " .. tostring(available))
   print("  spellID = " .. spellID)
   print("  unlocked = " .. tostring(unlocked))
   print("  row = " .. row)
   print("  column = " .. column)
   print("  known = " .. tostring(known))
   print("  grantedByAura = " .. tostring(grantedByAura))
   --]]

   self.selected = select(10, GetPvpTalentInfoByID(self.talentID))
   
end


----------------------- talentlist --------------------------
local talentlist = extends(datalist)

function talentlist:new(obj)
   local o = talentlist.__super.new(self, obj)
   setmetatable(o, self)
   return o
end

function talentlist:playertalentupdate()
   iterate(self, "gettalentinfo")
end


----------------------- trait --------------------------

local trait = extends(data)

function trait:new(id)
   local o = trait.__super.new(
      self,
      {
	 id = id, -- nodeID
	 selected = false,
      }
   )
   setmetatable(o, self)
   return o
end

function trait:getinfo()
   -- print("get info")
   local configID = C_ClassTalents.GetActiveConfigID()
   local nodeInfo = C_Traits.GetNodeInfo(configID, self.id)
   -- print(string.format("configID: %d, nodeID: %d", configID, nodeID))
   if (nodeInfo) then
      local activeEntry = nodeInfo.activeEntry
      local activeRank = nodeInfo.activeRank
      self.selected = activeEntry and activeRank > 0
   else
      print(string.format("warning: trait id:%d is not valid", self.id))
   end
end


----------------------- traitlist --------------------------
local traitlist = extends(datalist)

function traitlist:new(obj)
   local o = traitlist.__super.new(self, obj)
   setmetatable(o, self)
   return o
end

-- https://wowpedia.fandom.com/wiki/TRAIT_CONFIG_UPDATED
function traitlist:traitconfigupdated()
   --print("trait config updated")
   iterate(self, "getinfo")
end


----------------------- prototype --------------------------
local prototype =
   {
      data = data,
      datalist = datalist,
      class = class,
      spec = spec,
      buff = buff,
      bufflist = bufflist,
      pandemicbuff = pandemicbuff,
      multitargetdebuff = multitargetdebuff,
      power = power,
      skill = skill,
      executeskill = executeskill,
      talent = talent,
      pvptalent = pvptalent,
      talentlist = talentlist,
      trait = trait,
      traitlist = traitlist,
   }


----------------------- Skill Bar --------------------------
SkillBar.prototype = prototype
