local data = SkillBar.data
local common = SkillBar.common
local warlock = SkillBar.warlock

local specname = "affliction"


----------------- spec event ------------------
local specevent = {}
function specevent:register(obj, event, func)
   SkillBar.event:register(obj, event, func, specname)
end


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      AGONY = 980,
      BURNING_RUSH = 111400,
      DARK_PACT = 108416,
      DARK_SOUL_MISERY = 113860,
      DRAIN_SOUL = 198590,
      HAUNT = 48181,
      MALEFIC_RAPTURE = 324536,
      PHANTOM_SINGULARITY = 205179,
      SHADOW_EMBRACE = 32388,
      SIPHON_LIFE = 63106,
      SUMMON_DARKGLARE = 205180,
      UNSTABLE_AFFLICTION = 316099,
      VILE_TAINT = 278350,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      DARK_SOUL_MISERY = 113860,
      INEVITABLE_DEMISE = 334320,
      NIGHTFALL = 264571,
      -- debuffs
      HAUNT = 48181,
      VILE_TAINT = 278350,
      PHANTOM_SINGULARITY = 205179,
      IMPENDING_CATASTROPHE = 322170,
      SHADOW_EMBRACE = 32390,
      AGONY = 980,
      CORRUPTION = 146739,
      SIPHON_LIFE = 63106,
      UNSTABLE_AFFLICTION = 316099,
   }


----------------- soulshard ------------------
local soulshard = common.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents =
   {
      absolutecorruption = { selected = false },
      creepingdeath = { selected = false },
      drainsoul = { selected = false },
   }

function talents:update()
   self.absolutecorruption.selected = select(4, GetTalentInfo(2, 2, 1))
   self.creepingdeath.selected = select(4, GetTalentInfo(7, 2, 1))
   self.drainsoul.selected = select(4, GetTalentInfo(1, 3, 1))
end
specevent:register(talents, "PLAYER_TALENT_UPDATE", talents.update)


----------------- malefic ------------------
local malefic =
   {
      active = false,
      count = 0,
      agony = 0,
      corruption = 0,
      siphonlife = 0,
      unstableaffliction = 0,
      viletaint = 0,
      phantomsingularity = 0,
      impendingcatastrophe = 0,
   }
    
function malefic:clear()
   self.active = false
   self.count = 0
   self.agony = 0
   self.corruption = 0
   self.siphonlife = 0
   self.unstableaffliction = 0
   self.viletaint = 0
   self.phantomsingularity = 0
   self.impendingcatastrophe = 0
end

function malefic:update()
   
   self:clear()
   
   for iunit = 1, 40 do
      
      local unit = "nameplate" .. iunit
      
      -- target debuffs
      if (UnitExists(unit)) then -- and (not UnitIsEnemy("target", "player"))) then
	 
	 for ibuff = 1, 40 do
	    
	    local name, _, count, _, duration, expirationTime, unitCaster, _, _, spellID
	       = UnitAura(unit, ibuff, "HARMFUL")
	    
	    if (unitCaster == "player") then             
	       if (spellID == 980) then -- Agony
		  self.agony = self.agony + 1   
	       elseif (spellID == 146739) then -- Corruption
		  self.corruption = self.corruption + 1
	       elseif (spellID == 63106) then -- Siphon Life
		  self.siphonlife = self.siphonlife + 1
	       elseif (spellID == 316099) then -- Unstable Affliction
		  self.unstableaffliction = self.unstableaffliction + 1
	       elseif (spellID == 278350) then -- Vile Taint
		  self.viletaint = self.viletaint + 1
	       elseif (spellID == 205179) then -- Phantom Singularity
		  self.phantomsingularity = self.phantomsingularity + 1
	       elseif (spellID == 322170) then -- Impending Catastrophe
		  self.impendingcatastrophe = self.impendingcatastrophe + 1
	       end
	    end
	    
	 end
	 
      end
      
   end
   
   self.count = 
      self.agony + 
      self.corruption +
      self.siphonlife +
      self.unstableaffliction +
      self.viletaint +
      self.phantomsingularity + 
      self.impendingcatastrophe

   self.active = self.count > 0
   
end


----------------- shadow bolt ------------------
local shadowbolt = common.skill:new(warlock.skill_enum.SHADOW_BOLT)
setmetatable(shadowbolt, common.skill)
    
function shadowbolt:update(now)
   
   common.skill.update(self, now)
   
   -- shadowbolt is always usable
   -- so check talent choice
   self.usable = self.usable and (not talents.drainsoul.selected)
   
end


----------------- drain soul ------------------
local drainsoul = common.skill:new(skill_enum.DRAIN_SOUL)
drainsoul.execute_phase = false
setmetatable(drainsoul, common.skill)

function drainsoul:update(now)
   
   common.skill.update(self, now)
   
   local execute_health = 0.2
   local target_health = 1
   if (UnitExists("target")) then
      local health = UnitHealth("target")
      local health_max = UnitHealthMax("target")
      target_health = health / health_max
   end
   
   self.execute_phase = target_health <= execute_health
   
end


----------------- skills ------------------
local skills =
   {
      agony              = common.skill:new(skill_enum.AGONY),
      corruption         = common.skill:new(warlock.skill_enum.CORRUPTION),
      siphonlife         = common.skill:new(skill_enum.SIPHON_LIFE),
      unstableaffliction = common.skill:new(skill_enum.UNSTABLE_AFFLICTION),
      shadowbolt         = shadowbolt,
      drainsoul          = drainsoul,
      haunt              = common.skill:new(skill_enum.HAUNT),
      maleficrapture     = common.skill:new(skill_enum.MALEFIC_RAPTURE),
   }
    
function skills:update(now)
   for _, v in pairs(self) do
      if (type(v) == "table") then
	 local skill = v
	 skill:update(now)
      end
   end
end


----------------- player buffs ------------------
local player_buffs =
   {
      darksoulmisery   = common.buff:new("player", buff_enum.DARK_SOUL_MISERY),
      inevitabledemise = common.buff:new("player", buff_enum.INEVITABLE_DEMISE),
      nightfall        = common.buff:new("player", buff_enum.NIGHTFALL),
   }

--TODO: move these functions to a common class
function player_buffs:update(now)
   for _, v in pairs(self) do
      if (type(v) == "table") then
	 local buff = v
	 buff:update(now)
      end
   end
end
    

----------------- unstable affliction ------------------
local unstableaffliction = common.pandemicbuff:new("target", buff_enum.UNSTABLE_AFFLICTION, skill_enum.UNSTABLE_AFFLICTION)
unstableaffliction.other = false
setmetatable(unstableaffliction, common.pandemicbuff)
    
function unstableaffliction:update(now)
   
   common.pandemicbuff.update(self, now)
   
   -- is unstable affliction out on some other target?
   local count = malefic.unstableaffliction or 0
   self.other = (count > 0) and (not self.active)
   
end


----------------- shadow embrace ------------------
local shadowembrace = common.buff:new("target", buff_enum.SHADOW_EMBRACE)
shadowembrace.known = IsSpellKnown(skill_enum.SHADOW_EMBRACE)
shadowembrace.max = 3
shadowembrace.actual = 0
shadowembrace.expected = 0
shadowembrace.shadowbolt = {}

function shadowembrace:clear(guid)
   self.shadowbolt[guid] = nil
end
    
function shadowembrace:push(guid, now)
   --print(string.format("shadowbolt: %f", now))
   self.shadowbolt[guid] = self.shadowbolt[guid] or {}
   table.insert(self.shadowbolt[guid], now)
end
    
function shadowembrace:pop(guid)
   
   local queue = self.shadowbolt[guid]
   if (queue) then
      table.remove(queue)
   end
   
   -- delete queue for unit from table
   if (next(queue) == nil) then
      self:clear(guid)
   end
   
end
    
function shadowembrace:update(now)

   if (not self.known) then
      return
   end
        
   common.buff.update(self, now)
   
   self.actual = self.count
   self.expected = 0
   
   if (UnitExists("target") and (not talents.drainsoul.selected)) then
      local targetGUID = UnitGUID("target")
      local queue = self.shadowbolt[targetGUID]
      if (queue) then
	 self.expected = table.getn(queue)
      end
   end
   
   self.count = self.actual + self.expected
   if (self.count > self.max) then
      self.count = self.max
   end
   
end

function shadowembrace:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)

    -- SPELL_AURA_REFRESH doesn't seem to be firing for shadow embrace
    -- just track the shadow bolt spell damage
   if ((sourceGUID == UnitGUID("player")) and
       (spellID == warlock.skill_enum.SHADOW_BOLT)) then
      if (subevent == "SPELL_CAST_SUCCESS") then
	 self:push(destGUID, timestamp)
      elseif (subevent == "SPELL_DAMAGE") then
	 self:pop(destGUID)
      end
   elseif (subevent == "UNIT_DIED") then
      self:clear(destGUID)
   end
   
end
specevent:register(shadowembrace, "COMBAT_LOG_EVENT_UNFILTERED", shadowembrace.cleu)


----------------- target debuffs ------------------
local target_debuffs =
   {
      -- normal
      haunt                = common.buff:new("target", buff_enum.HAUNT),
      viletaint            = common.buff:new("target", buff_enum.VILE_TAINT),
      phantomsingularity   = common.buff:new("target", buff_enum.PHANTOM_SINGULARITY),
      impendingcatastrophe = common.buff:new("target", buff_enum.IMPENDING_CATASTROPHE),
      shadowembrace        = shadowembrace,
      -- pandemic
      agony              = common.pandemicbuff:new("target", buff_enum.AGONY, skill_enum.AGONY),
      corruption         = common.pandemicbuff:new("target", buff_enum.CORRUPTION, warlock.skill_enum.CORRUPTION),
      siphonlife         = common.pandemicbuff:new("target", buff_enum.SIPHON_LIFE, skill_enum.SIPHON_LIFE),
      unstableaffliction = unstableaffliction,
   }

--TODO: move these functions to a common class
function target_debuffs:update(now)
   for _,debuff in pairs(self) do
      if (type(debuff) == "table") then
	 debuff:update(now)
      end
   end
end

--TODO: move these functions to a common class 
function target_debuffs:updatethreshold()
   for k,debuff in pairs(self) do
      if (type(debuff) == "table") then
	 local pandemic = debuff.pandemic
	 if (pandemic) then
	    --print(string.format("%s %s", k, tostring(pandemic)))
	    debuff:updatethreshold()
	 end
      end
   end
end
--specevent:register(target_debuffs, "PLAYER_REGEN_DISABLED", target_debuffs.updatethreshold)
specevent:register(target_debuffs, "PLAYER_TALENT_UPDATE", target_debuffs.updatethreshold)


----------------- affliction ------------------
local affliction = data:new(
   specname,
   {
      skill = skill_enum.NIL,
      skill_enum = skill_enum,
      buff_enum = buff_enum,
      soulshard = soulshard,
      talents = talents,
      malefic = malefic,
      skills = skills,
      player_buffs = player_buffs,
      target_debuffs = target_debuffs,
   }
)

function affliction:update(now)

   local gcd = common.gcd.current
   
   ----- power -----
   soulshard:update()
   
   ----- buffs -----
   player_buffs:update(now)
   target_debuffs:update(now)
    
   ----- malefic -----
   malefic:update()
    
   ----- skills -----
   skills:update(now)
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.haunt.usable) then
	 skill = skill_enum.HAUNT
      elseif (skills.agony.usable and
		 target_debuffs.agony.pandemic.active
      ) then
	 skill = skill_enum.AGONY
      elseif (skills.corruption.usable and
		 (
		    (
		       talents.absolutecorruption.selected and
			  (not target_debuffs.corruption.active)
		    ) or
		       (
			  (not talents.absolutecorruption.selected) and
			     target_debuffs.corruption.pandemic.active
		       )
		 )
      ) then
	 skill = warlock.skill_enum.CORRUPTION
      elseif (skills.siphonlife.usable and
		 target_debuffs.siphonlife.pandemic.active
      ) then
	 skill = skill_enum.SIPHON_LIFE
      elseif (skills.unstableaffliction.usable and
		 (
		    target_debuffs.unstableaffliction.pandemic.active and
		       (not target_debuffs.unstableaffliction.other)
		 ) 
      )then
	 skill = skill_enum.UNSTABLE_AFFLICTION
      elseif (skills.maleficrapture.usable and
		 (
		    (soulshard.deficit == 0) or
		       (malefic.count >= 5)
		 )
      ) then
	 skill = skill_enum.MALEFIC_RAPTURE
      elseif (skills.shadowbolt.usable and
		 (player_buffs.nightfall.active)
      ) then
	 skill = warlock.skill_enum.SHADOW_BOLT
      elseif (skills.drainsoul.usable and
		(
		   skills.drainsoul.execute_phase or
		      (
			 target_debuffs.shadowembrace.known and
			    (
			       (target_debuffs.shadowembrace.count < target_debuffs.shadowembrace.max) or
				  (target_debuffs.shadowembrace.remaining < 2 * gcd)
			    )
		      )
		)
      ) then
	 skill = skill_enum.DRAIN_SOUL
      elseif (skills.shadowbolt.usable and
		 (
		    target_debuffs.shadowembrace.known and
		       (
			  (
			     target_debuffs.shadowembrace.count < target_debuffs.shadowembrace.max
			  ) or
			     (target_debuffs.shadowembrace.remaining < 4 * gcd)
		       )
		 )
      ) then
	 skill = warlock.skill_enum.SHADOW_BOLT
      elseif (skills.maleficrapture.usable and
		 (soulshard.current >= 2)
      ) then
	 skill = skill_enum.MALEFIC_RAPTURE
      elseif (skills.drainsoul.usable) then
	 skill = skill_enum.DRAIN_SOUL
      elseif(skills.shadowbolt.usable) then
	 skill = warlock.skill_enum.SHADOW_BOLT
      end
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      common:broadcastskill(skill)
   end
   
end


----------------------- warlock --------------------------
warlock.affliction = affliction
