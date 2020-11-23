local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local mage = SkillBar.mage


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      ALTER_TIME = 342245,
      ARCANE_BARRAGE = 44425,
      ARCANE_BLAST = 30451,
      ARCANE_FAMILIAR = 205022,
      ARCANE_MISSILES = 5143,
      ARCANE_ORB = 153626,
      ARCANE_POWER = 12042,
      CONJURE_MANA_GEM = 759,
      EVOCATION = 12051,
      GREATER_INVISIBILITY = 110959,
      NETHER_TEMPEST = 114923,
      PRESENCE_OF_MIND = 205025,
      PRISMATIC_BARRIER = 235450,
      SLOW = 31589,
      SUPERNOVA = 157980,
      TOUCH_OF_THE_MAGI = 321507,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      ARCANE_POWER = 12042,
      CLEARCASTING = 263725,
      EVOCATION = 12051,
      RULE_OF_THREES = 264774,
      RUNE_OF_POWER = 116014,

      -- player debuffs
      
      -- debuffs
      TOUCH_OF_THE_MAGI = 210824,
   }


----------------- phase enum ------------------
local phase_enum = 
   {
      CONSERVE = 1,
      BURN = 2,
      EVOCATION = 3,
   }


----------------------- arcane charges --------------------------
local arcanecharges = prototype.power:new(Enum.PowerType.ArcaneCharges)


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      runeofpower = prototype.talent:new(3, 1)
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      arcanebarrage   = prototype.skill:new(skill_enum.ARCANE_BARRAGE),
      arcaneblast     = prototype.skill:new(skill_enum.ARCANE_BLAST),
      arcaneexplosion = prototype.skill:new(mage.skill_enum.ARCANE_EXPLOSION),
      arcanemissiles  = prototype.skill:new(skill_enum.ARCANE_MISSILES),
      arcanepower     = prototype.skill:new(skill_enum.ARCANE_POWER),
      evocation       = prototype.skill:new(skill_enum.EVOCATION),
      presenceofmind  = prototype.skill:new(skill_enum.PRESENCE_OF_MIND),
      runeofpower     = prototype.skill:new(mage.skill_enum.RUNE_OF_POWER),
      touchofthemagi  = prototype.skill:new(skill_enum.TOUCH_OF_THE_MAGI),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      arcanepower  = prototype.buff:new("player", buff_enum.ARCANE_POWER),
      clearcasting = prototype.buff:new("player", buff_enum.CLEARCASTING),
      evocation    = prototype.buff:new("player", buff_enum.EVOCATION),
      ruleofthrees = prototype.buff:new("player", buff_enum.RULE_OF_THREES),
      runeofpower  = prototype.buff:new("player", buff_enum.RUNE_OF_POWER),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      touchofthemagi = prototype.buff:new("target", buff_enum.TOUCH_OF_THE_MAGI),
   }
)


----------------- phase ------------------
local phase = prototype.data:new(
   {
      current = phase_enum.CONSERVE,
      goforburn = false,
   }
)

function phase:update(now)

   if (InCombatLockdown()) then

      -- in combat, cycle phases based on usage
      -- of arcane power and evocation
      -- CONSERVE -> BURN -> EVOCATION -> CONSERVE
      if (self.current == phase_enum.CONSERVE and
	     player_buffs.arcanepower.active
      ) then
	 self.current = phase_enum.BURN
      elseif (self.current == phase_enum.BURN and
		 player_buffs.evocation.active
      ) then
	 self.current = phase_enum.EVOCATION
      elseif (self.current == phase_enum.evocation and
		 not player_buffs.evocation.active
      ) then
	 self.current = phase_enum.CONSERVE
      end
      
   else
      -- out of combat, reset to conserve
      self.current = phase_enum.CONSERVE
   end

   self.goforburn = (mage.mana.percent >= 50) and
      skills.arcanepower.usable and
      skills.touchofthemagi.usable
   
end


----------------- arcane ------------------
local arcane = extends(prototype.spec)

function arcane:new()
   local o = arcane.__super.new(
      self,
      "arcane",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 arcanecharges = arcanecharges,
	 talents = talents,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
	 phase = phase,
      }
   )
   setmetatable(o, self)
   return o
end

function arcane:update(now)
   
   --print("arcane update")
   
   arcane.__super.update(self, now)
   
   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.melee

   local phase = self.phase
   
   if (InCombatLockdown()) then
      
      if (phase.current == phase_enum.CONSERVE) then
	 
	 local miniburn = (skills.touchofthemagi.usable) and
	    (skills.arcanepower.cd >= 30) and
	    (
	       (
		  talents.runeofpower.selected and
		     (skills.runeofpower.usable)
	       ) or
		  not talents.runeofpower.selected
	    )
	 
	 if (skills.touchofthemagi.usable and
		(arcanecharges.current == 0) and
		miniburn
	 ) then
	    skill = skill_enum.TOUCH_OF_THE_MAGI
	 elseif (skills.runeofpower.usable and
		    (not player_buffs.runeofpower.active) and
		    target_debuffs.touchofthemagi.active
	 ) then
	    skill = mage.skill_enum.RUNE_OF_POWER
	 elseif (skills.arcanemissiles.usable and
		    player_buffs.clearcasting.active
	 ) then
	    skill = skill_enum.ARCANE_MISSILES
	 elseif (skills.arcanebarrage.usable and
		    (
		       (
			  arcanecharges.capped and
			     miniburn
		       ) or
			  (
			     mage.mana.percent <= 90
			  )
		    )
	 ) then
	    skill = skill_enum.ARCANE_BARRAGE
	 elseif (skills.arcaneblast.usable) then
	    skill = skill_enum.ARCANE_BLAST
	 elseif (skills.arcanebarrage.usable) then
	    skill = skill_enum.ARCANE_BARRAGE
	 end
	 
      elseif (phase.current == phase_enum.BURN) then
	 
	 if (skills.runeofpower.usable and
		    (not player_buffs.runeofpower.active)
	 ) then
	    skill = mage.skill_enum.RUNE_OF_POWER
	 elseif (skills.presenceofmind.usable and
		    (
		       player_buffs.arcanepower.active and
			  (player_buffs.arcanepower.remaining < skills.arcaneblast.casttime)
		    )
	 ) then
	    skill = skill_enum.PRESENCE_OF_MIND
	 elseif (skills.arcanemissiles.usable and
		    player_buffs.clearcasting.active
	 ) then
	    skill = skill_enum.ARCANE_MISSILES
	 elseif (skills.arcaneblast.usable) then
	    skill = skill_enum.ARCANE_BLAST
	 elseif (skills.evocation.usable) then
	    skill = skill_enum.EVOCATION
	 elseif (skills.arcanebarrage.usable) then
	    skill = skill_enum.ARCANE_BARRAGE
	 end

      elseif (phase.current == phase_enum.EVOCATION) then
	 -- let evocation finish
      end
      
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end

end


----------------------- mage --------------------------
mage.arcane = arcane:new()
