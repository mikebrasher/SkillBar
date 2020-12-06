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
      SEED_OF_CORRUPTION = 27243,
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
      AGONY = 980,
      CORRUPTION = 146739,
      HAUNT = 48181,
      PHANTOM_SINGULARITY = 205179,
      SEED_OF_CORRUPTION = 27243,
      SHADOW_EMBRACE = 32390,
      SIPHON_LIFE = 63106,
      UNSTABLE_AFFLICTION = 316099,
      VILE_TAINT = 278350,

      -- covenant debuffs
      IMPENDING_CATASTROPHE = 322170,
      SOUL_ROT = 325640,
   }


----------------- soulshard ------------------
local soulshard = prototype.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      absolutecorruption = prototype.talent:new(2, 2),
      creepingdeath      = prototype.talent:new(7, 2),
      drainsoul          = prototype.talent:new(1, 3),
      inevitabledemise   = prototype.talent:new(1, 2),
      phantomsingularity = prototype.talent:new(4, 2),
      sowtheseeds        = prototype.talent:new(4, 1),
      viletaint          = prototype.talent:new(4, 3),
   }
)


----------------- malefic ------------------
local malefic = prototype.data:new(
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
      soulrot = 0,
   }
)

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
   self.soulrot = 0
end

function malefic:update(now)

   --print(string.format("malefic update: %s", now))
   
   self:clear()
   
   for iunit = 1, 40 do
      
      local unit = "nameplate" .. iunit
      
      -- target debuffs
      if (UnitExists(unit)) then -- and (not UnitIsEnemy("target", "player"))) then

	 --print(string.format("  unit: %s", unit))
	 
	 for ibuff = 1, 40 do
	    
	    local name, _, count, _, duration, expirationTime, unitCaster, _, _, spellID
	       = UnitAura(unit, ibuff, "HARMFUL")

	    --if (name) then
	    --   print(string.format("    spellID: %d, name = %s", name, spellID))
	    --end
	    
	    if (unitCaster == "player") then
	       if (spellID == buff_enum.AGONY) then
		  self.agony = self.agony + 1   
	       elseif (spellID == buff_enum.CORRUPTION) then
		  self.corruption = self.corruption + 1
	       elseif (spellID == buff_enum.SIPHON_LIFE) then
		  self.siphonlife = self.siphonlife + 1
	       elseif (spellID == buff_enum.UNSTABLE_AFFLICTION) then
		  self.unstableaffliction = self.unstableaffliction + 1
	       elseif (spellID == buff_enum.VILE_TAINT) then
		  self.viletaint = self.viletaint + 1
	       elseif (spellID == buff_enum.PHANTOM_SINGULARITY) then
		  self.phantomsingularity = self.phantomsingularity + 1
	       elseif (spellID == buff_enum.IMPENDING_CATASTROPHE) then
		  self.impendingcatastrophe = self.impendingcatastrophe + 1
	       elseif (spellID == buff_enum.SOUL_ROT) then
		  self.soulrot = self.soulrot + 1
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
      self.impendingcatastrophe +
      self.soulrot

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


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      agony              = prototype.skill:new(skill_enum.AGONY),
      corruption         = prototype.skill:new(warlock.skill_enum.CORRUPTION),
      drainlife          = prototype.skill:new(warlock.skill_enum.DRAIN_LIFE),
      drainsoul          = prototype.executeskill:new(skill_enum.DRAIN_SOUL, 0.2),
      haunt              = prototype.skill:new(skill_enum.HAUNT),
      maleficrapture     = prototype.skill:new(skill_enum.MALEFIC_RAPTURE),
      phantomsingularity = prototype.skill:new(skill_enum.PHANTOM_SINGULARITY),
      seedofcorruption   = prototype.skill:new(skill_enum.SEED_OF_CORRUPTION),
      shadowbolt         = shadowbolt:new(),
      siphonlife         = prototype.skill:new(skill_enum.SIPHON_LIFE),
      unstableaffliction = prototype.skill:new(skill_enum.UNSTABLE_AFFLICTION),
      viletaint          = prototype.skill:new(skill_enum.VILE_TAINT),
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
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      haunt                = prototype.buff:new("target", buff_enum.HAUNT),
      viletaint            = prototype.buff:new("target", buff_enum.VILE_TAINT),
      phantomsingularity   = prototype.buff:new("target", buff_enum.PHANTOM_SINGULARITY),
      impendingcatastrophe = prototype.buff:new("target", buff_enum.IMPENDING_CATASTROPHE),
      seedofcorruption     = prototype.buff:new("target", buff_enum.SEED_OF_CORRUPTION),
      shadowembrace        = shadowembrace:new(),
      soulrot              = prototype.buff:new("target", buff_enum.SOUL_ROT),
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
	 talents = talents,
	 malefic = malefic,
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
      if (skills.agony.usable and
	     target_debuffs.agony.pandemic.active
      ) then
	 skill = skill_enum.AGONY
      elseif (skills.haunt.usable) then
	 skill = skill_enum.HAUNT
      elseif (skills.seedofcorruption.usable and
		 (
		    talents.sowtheseeds.selected and
		       (common.lastcast.spellID ~= skill_enum.SEED_OF_CORRUPTION) and
		       (not target_debuffs.seedofcorruption.active)
		 )
      ) then
	 skill = skill_enum.SEED_OF_CORRUPTION
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
		    soulshard.capped or
		       target_debuffs.phantomsingularity.active or
		       target_debuffs.viletaint.active or
		       target_debuffs.soulrot.active or
		       talents.sowtheseeds.selected
		 )
      ) then
	 skill = skill_enum.MALEFIC_RAPTURE
      elseif (skills.drainlife.usable and
		 (
		    talents.inevitabledemise.selected and
		       (player_buffs.inevitabledemise.count > 40)
		 )
      ) then
	 skill = skill_enum.DRAIN_LIFE
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
			  (target_debuffs.shadowembrace.count < target_debuffs.shadowembrace.max) or
			     (target_debuffs.shadowembrace.remaining < 4 * gcd)
		       )
		 )
      ) then
	 skill = warlock.skill_enum.SHADOW_BOLT
      elseif (skills.maleficrapture.usable and
		 (
		    (soulshard.deficit < 2) and
		       (
			  (
			     talents.phantomsingularity.selected and
				(skills.phantomsingularity.cd > 10)
			  ) or
			     (
				talents.viletaint.selected and
				   (skills.viletaint.cd > 10)
			     )
		       )
		 )
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
