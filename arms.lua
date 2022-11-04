local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warrior = SkillBar.warrior


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BLADESTORM = 227847,
      CLEAVE = 845,
      COLOSSUS_SMASH = 167105,
      DIE_BY_THE_SWORD = 118038,
      MORTAL_STRIKE = 12294,
      OVERPOWER = 7384,
      REND = 772,
      SKULLSPLITTER = 260643,
      SWEEPING_STRIKES = 260708,
      WARBREAKER = 262161,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      SWEEPING_STRIKES = 260708,
      DIE_BY_THE_SWORD = 118038,
      OVERPOWER = 7384,
      TEST_OF_MIGHT = 385013,
      
      -- debuffs      
      COLOSSUS_SMASH = 208086,
      REND = 388539,
      DEEP_WOUNDS = 262115,
   }


----------------- traits ------------------
local traits = prototype.traitlist:new(
   {
      -- danceofdeath = prototype.trait:new(90263),
      fervorofbattle = prototype.trait:new(90272),
      rend = prototype.trait:new(90284),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      bladestorm    = prototype.skill:new(skill_enum.BLADESTORM),
      colossussmash = prototype.skill:new(skill_enum.COLOSSUS_SMASH),
      execute       = prototype.skill:new(warrior.skill_enum.EXECUTE),
      mortalstrike  = prototype.skill:new(skill_enum.MORTAL_STRIKE),
      overpower     = prototype.skill:new(skill_enum.OVERPOWER),
      slam          = prototype.skill:new(warrior.skill_enum.SLAM),
      rend          = prototype.skill:new(skill_enum.REND),
      warbreaker    = prototype.skill:new(skill_enum.WARBREAKER),
      whirlwind     = prototype.skill:new(warrior.skill_enum.WHIRLWIND),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      overpower       = prototype.buff:new("player", buff_enum.OVERPOWER),
      sweepingstrikes = prototype.buff:new("player", buff_enum.SWEEPING_STRIKES),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      colossussmash = prototype.buff:new("target", buff_enum.COLOSSUS_SMASH),
      -- pandemic
      deepwounds    = prototype.pandemicbuff:new("target", buff_enum.DEEP_WOUNDS, skill_enum.CLEAVE),
      rend          = prototype.pandemicbuff:new("target", buff_enum.REND, skill_enum.REND),
   }
)


---------------------- arms -----------------------
local arms = extends(prototype.spec)

function arms:new()
   local o = arms.__super.new(
      self,
      "arms",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 traits = traits,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

function arms:load()
   arms.__super.load(self)
   -- self:register(self.traits, "TRAIT_CONFIG_UPDATED", traits.traitconfigupdated)
end

function arms:update(now)

   arms.__super.update(self, now)
   
   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.rend.usable and
	  target_debuffs.rend.pandemic.active
      ) then
	 skill = skill_enum.REND
      --elseif (skills.colossussmash.usable) then
      --   skill = skill_enum.COLOSSUS_SMASH
      elseif (skills.mortalstrike.usable and
	      (
		 (target_debuffs.deepwounds.pandemic.active) or
		 (player_buffs.overpower.count == 2)
	      )
      ) then
	 skill = skill_enum.MORTAL_STRIKE
      elseif (skills.execute.usable) then
	 skill = warrior.skill_enum.EXECUTE
      elseif (skills.mortalstrike.usable) then
	 skill = skill_enum.MORTAL_STRIKE
      elseif (skills.overpower.usable and
	      (warrior.rage.current <= 70)
      ) then
	 skill = skill_enum.OVERPOWER
      elseif (skills.whirlwind.usable and
	      traits.fervorofbattle.selected
      ) then
	 skill = warrior.skill_enum.WHIRLWIND
      elseif (skills.slam.usable) then
	 skill = warrior.skill_enum.SLAM
      end
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end
   
end


----------------------- warrior --------------------------
warrior.arms = arms:new()
