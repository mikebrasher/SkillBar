local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warlock = SkillBar.warlock


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
local soulshard = prototype.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents = extends(prototype.talents)

function talents:new()
   local o = talents.__super.new(
      self,
      {
	 absolutecorruption = { selected = false },
	 creepingdeath = { selected = false },
	 drainsoul = { selected = false },
      }
   )
   setmetatable(o, self)
   return o
end

function talents:playertalentupdate()
   
   talents.__super.playertalentupdate(self)

   self.absolutecorruption.selected = select(4, GetTalentInfo(2, 2, 1))
   self.creepingdeath.selected = select(4, GetTalentInfo(7, 2, 1))
   self.drainsoul.selected = select(4, GetTalentInfo(1, 3, 1))
   
end


----------------- malefic ------------------
local malefic = extends(prototype.data)

function malefic:new()
   local o = malefic.__super.new(
      self,
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
   )
   setmetatable(o, self)
   return o
end

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

function malefic:update(now)

   malefic.__super.update(self, now)
   
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
local shadowbolt = extends(prototype.skill)

function shadowbolt:new()
   local o = shadowbolt.__super.new(self, warlock.skill_enum.SHADOW_BOLT)
   setmetatable(o, self)
   return o
end
    
function shadowbolt:update(now)
   
   shadowbolt.__super.update(self, now)
   
   -- shadowbolt is always usable
   -- so check talent choice
   self.usable = self.usable and (not talents.drainsoul.selected)
   
end


----------------- drain soul ------------------
local drainsoul = extends(prototype.skill)

function drainsoul:new()
   local o = drainsoul.__super.new(self, skill_enum.DRAIN_SOUL)
   o.execute_phase = false
   setmetatable(o, self)
   return o
end

function drainsoul:update(now)
   
   drainsoul.__super.update(self, now)
   
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
local skills = prototype.datalist:new(
   {
      agony              = prototype.skill:new(skill_enum.AGONY),
      corruption         = prototype.skill:new(warlock.skill_enum.CORRUPTION),
      drainsoul          = drainsoul:new(),
      haunt              = prototype.skill:new(skill_enum.HAUNT),
      maleficrapture     = prototype.skill:new(skill_enum.MALEFIC_RAPTURE),
      shadowbolt         = shadowbolt:new(),
      siphonlife         = prototype.skill:new(skill_enum.SIPHON_LIFE),
      unstableaffliction = prototype.skill:new(skill_enum.UNSTABLE_AFFLICTION),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      darksoulmisery   = prototype.buff:new("player", buff_enum.DARK_SOUL_MISERY),
      inevitabledemise = prototype.buff:new("player", buff_enum.INEVITABLE_DEMISE),
      nightfall        = prototype.buff:new("player", buff_enum.NIGHTFALL),
   }
)


----------------- unstable affliction ------------------
local unstableaffliction = extends(prototype.pandemicbuff)

function unstableaffliction:new()
   local o = unstableaffliction.__super.new(self, "target", buff_enum.UNSTABLE_AFFLICTION, skill_enum.UNSTABLE_AFFLICTION)
   o.other = false
   setmetatable(o, self)
   return o
end

function unstableaffliction:update(now)
   
   unstableaffliction.__super.update(self, now)
   
   -- is unstable affliction out on some other target?
   local count = malefic.unstableaffliction or 0
   self.other = (count > 0) and (not self.active)
   
end


----------------- shadow embrace ------------------
local shadowembrace = extends(prototype.buff)

function shadowembrace:new()
   local o = shadowembrace.__super.new(self, "target", buff_enum.SHADOW_EMBRACE)
   o.known = false
   o.max = 3
   o.actual = 0
   o.expected = 0
   o.shadowbolt = {}
   setmetatable(o, self)
   return o
end

function shadowembrace:load()
   shadowembrace.__super.load(self)
   self.known = IsSpellKnown(skill_enum.SHADOW_EMBRACE)
end

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
        
   shadowembrace.__super.update(self, now)
   
   self.actual = self.count
   self.expected = 0
   
   if (UnitExists("target") and (not talents.drainsoul.selected)) then
      
      local targetGUID = UnitGUID("target")
      local queue = self.shadowbolt[targetGUID]
      if (queue) then
	 self.expected = table.getn(queue)
      end
   
      self.count = self.actual + self.expected
      if (self.count > self.max) then
	 self.count = self.max
      end
      
   end
   
end

function shadowembrace:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)

    -- SPELL_AURA_REFRESH doesn't seem to be firing for shadow embrace
    -- just track the shadow bolt spell damage
   if ((sourceGUID == common.player.guid) and
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


----------------- target debuffs ------------------
local target_debuffs = prototype.target_debuffs:new(
   {
      -- normal
      haunt                = prototype.buff:new("target", buff_enum.HAUNT),
      viletaint            = prototype.buff:new("target", buff_enum.VILE_TAINT),
      phantomsingularity   = prototype.buff:new("target", buff_enum.PHANTOM_SINGULARITY),
      impendingcatastrophe = prototype.buff:new("target", buff_enum.IMPENDING_CATASTROPHE),
      shadowembrace        = shadowembrace:new(),
      -- pandemic
      agony              = prototype.pandemicbuff:new("target", buff_enum.AGONY, skill_enum.AGONY),
      corruption         = prototype.pandemicbuff:new("target", buff_enum.CORRUPTION, warlock.skill_enum.CORRUPTION),
      siphonlife         = prototype.pandemicbuff:new("target", buff_enum.SIPHON_LIFE, skill_enum.SIPHON_LIFE),
      unstableaffliction = unstableaffliction:new(),
   }
)


----------------- affliction ------------------
local affliction = extends(prototype.spec)

function affliction:new()
   local o = affliction.__super.new(
      self,
      "affliction",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 soulshard = soulshard,
	 talents = talents:new(),
	 malefic = malefic:new(),
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

function affliction:load()

   affliction.__super.load(self)

   --self:register(self.talents, "PLAYER_TALENT_UPDATE", talents.playertalentupdate)
   --self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", target_debuffs.updatethreshold)
   self:register(self.target_debuffs.shadowembrace, "COMBAT_LOG_EVENT_UNFILTERED", self.target_debuffs.shadowembrace.cleu)
   
end

function affliction:update(now)

   affliction.__super.update(self, now)
   
   local gcd = common.gcd.current
   local malefic = self.malefic
   
   ----- power -----
   --soulshard:update()
   
   ----- buffs -----
   --player_buffs:update(now)
   --target_debuffs:update(now)
   
   ----- malefic -----
   --malefic:update()
    
   ----- skills -----
   --skills:update(now)
    
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
      broadcast:skill(skill)
   end
   
end


----------------------- warlock --------------------------
warlock.affliction = affliction:new()
