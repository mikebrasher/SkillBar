local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local mage = SkillBar.mage


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BLAST_WAVE = 157981,
      BLAZING_BARRIER = 235313,
      COMBUSTION = 190319,
      DRAGONS_BREATH = 31661,
      FIREBALL = 133,
      FLAMESTRIKE = 217916,
      LIVING_BOMB = 44457,
      METEOR = 153561,
      PHOENIX_FLAMES = 257541,
      PYROBLAST = 11366,
      SCORCH = 2948,
   }


----------------- buff enum ------------------

local buff_enum =
   {
      -- buffs
      HEATING_UP = 48107,
      HOT_STREAK = 48108,
      PYROCLASM = 269651,
      COMBUSTION = 190319,
      
      -- debuffs
      IGNITE = 12654,
   }


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      searingtouch = prototype.talent:new(1, 3),
      meteor = prototype.talent:new(7, 3),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      heatingup  = prototype.buff:new("player", buff_enum.HEATING_UP),
      hotstreak  = prototype.buff:new("player", buff_enum.HOT_STREAK),
      pyroclasm  = prototype.buff:new("player", buff_enum.PYROCLASM),
      combustion = prototype.buff:new("player", buff_enum.COMBUSTION),
   }
)


----------------- scorch ------------------
local scorch = extends(prototype.executeskill)

function scorch:new()
   local o = scorch.__super.new(self, skill_enum.SCORCH, 0.3)
   setmetatable(o, self)
   return o
end

function scorch:update(now)
   scorch.__super.update(self, now)
   self.execute_phase = self.execute_phase and talents.searingtouch.selected
end


----------------- combustion ------------------
local combustion = prototype.skill:new(skill_enum.COMBUSTION)


----------------- fire blast ------------------
local fireblast = extends(prototype.skill)
fireblast.window = 0.75

function fireblast:new()
   local o = fireblast.__super.new(self, mage.skill_enum.FIRE_BLAST)
   o.pooling = false
   o.usenow = false
   setmetatable(o, self)
   return o
end

function fireblast:update(now)

   fireblast.__super.update(self, now)

   -- can we use another fire blast charge and still cap before combustion is usable?
   self.pooling = self.charges.timetocap + self.charges.duration > combustion.cd

   local usenow = false
   if (self.usable and
	  (
	     (not self.pooling) and
		(
		   (
		      blastermaster_active and
			 (blastermaster_remaining < self.window)
		   ) or
		      (
			 common.casting.active and
			    (common.casting.remaining < self.window)
		      )
		) and
		(
		   (
		      player_buffs.heatingup.active and
			 (
			    (common.casting.spellID == skill_enum.FIREBALL) or
			       (common.casting.spellID == skill_enum.PYROBLAST)
			 )
		   ) or
		      (
			 scorch.execute_phase and
			    (
			       (not player_buffs.heatingup.active) and
				  (not player_buffs.hotstreak.active) and
				  (common.casting.spellID == skill_enum.SCORCH)
			    )
		      )
		)
	  )
   ) then
      usenow = true
   end

   if (self.usenow ~= usenow) then
      -- push event here
      self.usenow = usenow
   end
   
end


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      combustion = combustion,
      dragonsbreath = prototype.skill:new(skill_enum.DRAGONS_BREATH),
      fireball = prototype.skill:new(skill_enum.FIREBALL),
      fireblast = fireblast:new(),
      livingbomb = prototype.skill:new(skill_enum.LIVING_BOMB),
      meteor = prototype.skill:new(skill_enum.METEOR),
      phoenixflames = prototype.skill:new(skill_enum.PHOENIX_FLAMES),
      pyroblast = prototype.skill:new(skill_enum.PYROBLAST),
      runeofpower = prototype.skill:new(mage.skill_enum.RUNE_OF_POWER),
      scorch = scorch:new(),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      ignite = prototype.buff:new("target", buff_enum.IGNITE),
   }
)


----------------- fire ------------------
local fire = extends(prototype.spec)

function fire:new()
   local o = fire.__super.new(
      self,
      "fire",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 talents = talents,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
	 priority = "normal",
      }
   )
   setmetatable(o, self)
   return o
end

function fire:update(now)

   --print("fire update")

   fire.__super.update(self, now)

   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.melee

   if (InCombatLockdown()) then
        
      if (player_buffs.combustion.active) then
	 
	 self.priority = "combustion"
            
	 if (skills.pyroblast.usable and
		player_buffs.hotstreak.active
	 ) then
	    skill = skill_enum.PYROBLAST
	 elseif (skills.fireblast.usable) then
	    skill = mage.skill_enum.FIRE_BLAST
	 elseif (skills.scorch.usable) then
	    skill = skill_enum.SCORCH
	 end
	 
      else
	 
	 self.priority = "normal"
	 
	 if (skills.runeofpower.usable and
		(
		   (
		      talents.meteor.selected and
			 skills.meteor.usable and 
			 (skills.combustion.cd > skills.meteor.basecooldown)
		   ) or
		      (
			    not talents.meteor.selected and
			    (skills.combustion.cd > 15)
		      )
		)
	 ) then
	    skill = mage.skill_enum.RUNE_OF_POWER
	 elseif (skills.meteor.usable and
		    (
		       (skills.combustion.cd > skills.meteor.basecooldown) or
			  skills.combustion.usable
		    )
	 ) then
	    skill = skill_enum.METEOR
	 elseif (skills.livingbomb.usable) then
	    skill = skill_enum.LIVING_BOMB
	 elseif (skills.pyroblast.usable and
                (
		       player_buffs.hotstreak.active and
			  (
			     scorch.execute_phase
			     -- outside of execute, should consume hot streak
			     -- while a fireball is in flight
			     --(lastcast == WA_FALSTAR_FMB_SKILL_ENUM.FIREBALL)
			  )
                )
	 ) then
	    skill = skill_enum.PYROBLAST
	 elseif (skills.phoenixflames.usable and
		    skills.phoenixflames.charges.capped
	 ) then
	    skill = skill_enum.PHOENIX_FLAMES
	 elseif (skills.scorch.usable and
		    skills.scorch.execute_phase
	 ) then
	    skill = skill_enum.SCORCH
	 elseif (skills.fireball.usable) then
	    skill = skill_enum.FIREBALL
	 end
	 
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
mage.fire = fire:new()
