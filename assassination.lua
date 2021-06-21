local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local rogue = SkillBar.rogue


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      CRIMSON_TEMPEST = 121411,
      ENVENOM = 32645,
      EXSANGUINATE = 200806,
      FAN_OF_KNIVES = 51723,
      GARROTE = 703,
      MARKED_FOR_DEATH = 137619,
      MUTILATE = 1329,
      POISONED_KNIFE = 185565,
      RUPTURE = 1943,
      SHADOWSTEP = 36554,
      VENDETTA = 79140,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      ENVENOM = 32645,
      SLICE_AND_DICE = 315496,
      SUBTERFUGE = 115192,
      
      -- debuffs
      CRIMSON_TEMPEST = 121411,
      DEADLY_POISON = 2818,
      GARROTE = 703,
      INTERNAL_BLEEDING = 154953,
      RUPTURE = 1943,
      SHIV = 319504,
      VENDETTA = 79140,
      WOUND_POISON = 8680,

      -- covenant debuffs
      FLAGELLATION = 323654,

   }


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      subterfuge = prototype.talent:new(2, 2),
   }
)


----------------- regen ------------------
local regen = prototype.data:new(
   {
      base = 0,
      garrote = 0,
      internalbleeding = 0,
      rupture = 0,
      bleeds = 0,
      tick =
	 {
	    regen = 8,
	    interval = 2,
	    rate = 4,
	 },
      current = 0,
   }
)

function regen:clear()
   self.base = 0
   self.garrote = 0
   self.internalbleeding = 0
   self.rupture = 0
   self.bleeds = 0
   self.current = 0
end

function regen:update(now)

   --print(string.format("malefic update: %s", now))
   
   self:clear()

   self.base,_ = GetPowerRegen()
   
   for iunit = 1, 40 do
      
      local unit = "nameplate" .. iunit
      
      -- target debuffs
      local unit_poisoned = false
      local unit_garrote = false
      local unit_internalbleeding = false
      local unit_rupture = false
      if (UnitExists(unit)) then -- and (not UnitIsEnemy("target", "player"))) then

	 --print(string.format("  unit: %s", unit))
	 
	 for ibuff = 1, 40 do
	    
	    local name, _, count, _, duration, expirationTime, unitCaster, _, _, spellID
	       = UnitAura(unit, ibuff, "HARMFUL")

	    --if (name) then
	    --   print(string.format("    spellID: %d, name = %s", name, spellID))
	    --end
	    
	    if (unitCaster == "player") then
	       if ((spellID == buff_enum.DEADLY_POISON) or
		  (spellID == buff_enum.WOUND_POISON)) then
		  unit_poisoned = true
	       elseif (spellID == buff_enum.GARROTE) then
		  unit_garrote = true
	       elseif (spellID == buff_enum.INTERNAL_BLEEDING) then
		  unit_internalbleeding = true
	       elseif (spellID == buff_enum.RUPTURE) then
		  unit_rupture = true
	       end
	    end
	    
	 end
	 
      end

      if (unit_poisoned) then
	 
	 if (unit_garrote) then
	    self.garrote = self.garrote + 1
	 end

	 if (unit_internalbleeding) then
	    self.internalbleeding = self.internalbleeding + 1
	 end

	 if (unit_rupture) then
	    self.rupture = self.rupture + 1
	 end
	 
      end
      
   end

   self.bleeds =
      self.garrote +
      self.internalbleeding +
      self.rupture

   local tick = self.tick
   tick.interval = 2 / (1 + common.player.haste / 100)
   tick.rate = tick.regen / tick.interval

   self.current = 
      self.base +
      self.bleeds * tick.rate

end


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      ambush         = prototype.skill:new(rogue.skill_enum.AMBUSH),
      crimsontempest = prototype.skill:new(skill_enum.CRIMSON_TEMPEST),
      flagellation   = prototype.skill:new(rogue.skill_enum.FLAGELLATION),
      garrote        = prototype.skill:new(skill_enum.GARROTE),
      mutilate       = prototype.skill:new(skill_enum.MUTILATE),
      envenom        = prototype.skill:new(skill_enum.ENVENOM),
      rupture        = prototype.skill:new(skill_enum.RUPTURE),
      fanofknives    = prototype.skill:new(skill_enum.FAN_OF_KNIVES),
      shadowstep     = prototype.skill:new(skill_enum.SHADOWSTEP),
      shiv           = prototype.skill:new(rogue.skill_enum.SHIV),
      sliceanddice   = prototype.skill:new(rogue.skill_enum.SLICE_AND_DICE),
      vendetta       = prototype.skill:new(skill_enum.VENDETTA),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      envenom      = prototype.buff:new("player", buff_enum.ENVENOM),
      sliceanddice = prototype.pandemicbuff:new("player", buff_enum.SLICE_AND_DICE, rogue.skill_enum.SLICE_AND_DICE),
      subterfuge   = prototype.buff:new("player", buff_enum.SUBTERFUGE),
   }
)


----------------- garrote ------------------
local garrote = extends(prototype.pandemicbuff)

function garrote:new()
   local o = garrote.__super.new(self, "target", buff_enum.GARROTE, skill_enum.GARROTE)
   o.subterfuge = false
   o.database = {}
   setmetatable(o, self)
   return o
end

function garrote:clear(guid)
   self.database[guid] = nil
end
    
function garrote:record(guid, timestamp)

   --print(string.format("garrote: %f", timestamp))
   self.database[guid] = self.database[guid] or {}
   
   local entry = self.database[guid]
   entry.subterfuge = IsStealthed() or player_buffs.subterfuge.active
   entry.timestamp = timestamp
   
end
    
function garrote:update(now)
        
   garrote.__super.update(self, now)

   if (not talents.subterfuge.selected) then
      return
   end
   
   if (UnitExists("target")) then
      
      local targetGUID = UnitGUID("target")
      local entry = self.database[targetGUID]
      if (entry) then
	 self.subterfuge = entry.subterfuge
      end
      
   end

   self.subterfuge = self.subterfuge and self.active
   
end

function garrote:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)
   
   if ((sourceGUID == common.player.guid) and
      (spellID == buff_enum.GARROTE)) then
      
      if (subevent == "SPELL_AURA_APPLIED") then
	 --print("garrote applied")
	 self:record(destGUID, timestamp)
      elseif (subevent == "SPELL_AURA_REFRESH") then
	 --print("garrote refresh")
	 self:record(destGUID, timestamp)
      elseif (subevent == "SPELL_AURA_REMOVED") then
	 --print("garrote removed")
	 self:clear(destGUID)
      end
      
   elseif (subevent == "UNIT_DIED") then
      
      --print("garrote unit died")
      self:clear(destGUID)
      
   end
   
end


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      flagellation = prototype.buff:new("target", buff_enum.FLAGELLATION),
      shiv         = prototype.buff:new("target", buff_enum.SHIV),
      vendetta     = prototype.buff:new("target", buff_enum.VENDETTA),
      -- pandemic
      crimsontempest = prototype.pandemicbuff:new("target", buff_enum.CRIMSON_TEMPEST, skill_enum.CRIMSON_TEMPEST),
      garrote = garrote:new(),
      rupture = prototype.pandemicbuff:new("target", buff_enum.RUPTURE, skill_enum.RUPTURE),
   }
)


----------------- assassination ------------------
local assassination = extends(prototype.spec)

function assassination:new()
   local o = assassination.__super.new(
      self,
      "assassination",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 talents = talents,
	 regen = regen,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

function assassination:load()
   
   assassination.__super.load(self)
   
   self:register(self.target_debuffs.garrote, "COMBAT_LOG_EVENT_UNFILTERED", self.target_debuffs.garrote.cleu)
   
end

function assassination:update(now)

   assassination.__super.update(self, now)
   
   local gcd = common.gcd.current

   -- use range8 instead of 10 due to combat reach being ignored (says hero rotation)
   local enemies = common.enemies.range8

   local use_filler = (rogue.combopoints.deficit > 1) or
      (rogue.energy.deficit <= 25 + regen.current) or
      (enemies > 1)
      
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown() and UnitExists("target")) then
      if (skills.sliceanddice.usable and
	     (
		(not player_buffs.sliceanddice.active) and
		   (rogue.combopoints.current >= 3)
	     )
      ) then
	 skill = rogue.skill_enum.SLICE_AND_DICE
      elseif (skills.envenom.usable and
		 (
		    (player_buffs.sliceanddice.remaining < 5) and
		       (rogue.combopoints.deficit <= 1)
		 )
      ) then
	 skill = skill_enum.ENVENOM
      elseif (skills.rupture.usable and
		 (
		    target_debuffs.rupture.pandemic.active and
		       (rogue.combopoints.deficit <= 1)
		 )
      ) then
	 skill = skill_enum.RUPTURE
      elseif (skills.garrote.usable and
		 (
		    (
		       target_debuffs.garrote.pandemic.active and
			  (
			     -- don't override empowered garrote with unempowered
			     (not target_debuffs.garrote.subterfuge) or
				-- new garrote will be empowered
				(player_buffs.subterfuge.active)
			  )
		    ) and
		       (not rogue.combopoints.capped)
	     )
      ) then
	 skill = skill_enum.GARROTE
      elseif (skills.crimsontempest.usable and
		 (
		    (enemies > 1) and
		       (rogue.combopoints.deficit <= 1) and
		       (regen.current > 20) and
		       (target_debuffs.crimsontempest.pandemic.active)
		 )
      ) then
	 skill = skill_enum.CRIMSON_TEMPEST
      elseif (skills.shiv.usable and
		 (not rogue.combopoints.capped)
      ) then
	 skill = rogue.skill_enum.SHIV
      elseif (skills.envenom.usable and
		 (
		    (rogue.combopoints.deficit <= 1) and
		       (
			  target_debuffs.vendetta.active or
			     target_debuffs.shiv.active or
			     target_debuffs.flagellation.active or
			     (rogue.energy.deficit <= 25 + regen.current) or
			     (enemies > 1)
		       )
		 )
      ) then
	 skill = skill_enum.ENVENOM
      elseif (skills.fanofknives.usable and
		 (
		    (enemies >= 4) and
		       use_filler
		 )
      ) then
	 skill = skill_enum.FAN_OF_KNIVES
      elseif (skills.ambush.usable and
		 use_filler
      ) then
	 skill = rogue.skill_enum.AMBUSH
      elseif (skills.mutilate.usable and
		 use_filler
      ) then
	 skill = skill_enum.MUTILATE
      end
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end
   
end


----------------------- assassination --------------------------
rogue.assassination = assassination:new()
