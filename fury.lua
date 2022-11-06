local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warrior = SkillBar.warrior


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BLOODTHIRST = 23881,
      ENRANGED_REGENERATION = 184364,
      EXECUTE = 280735, -- fury only
      ODYNS_FURY = 385059,
      RAGING_BLOW = 85288,
      RAMPAGE = 184367,
      WHIRLWIND = 190411, -- fury only
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      BLOODCRAZE = 393951,
      ENRAGE = 184362,
      ENRAGED_REGENERATION = 184364,
      SUDDEN_DEATH = 280776,
      WHIRLWIND = 85739,
      
      -- debuffs      
      GUSHING_WOUND = 385042,
   }


----------------- traits ------------------
local traits = prototype.traitlist:new(
   {
      annihilator = prototype.trait:new(90419),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      bloodthirst = prototype.skill:new(skill_enum.BLOODTHIRST),
      execute     = prototype.skill:new(skill_enum.EXECUTE),
      odynsfury   = prototype.skill:new(skill_enum.ODYNS_FURY),
      ragingblow  = prototype.skill:new(skill_enum.RAGING_BLOW),
      rampage     = prototype.skill:new(skill_enum.RAMPAGE),
      slam        = prototype.skill:new(warrior.skill_enum.SLAM),
      whirlwind   = prototype.skill:new(skill_enum.WHIRLWIND),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      bloodcraze  = prototype.buff:new("player", buff_enum.BLOODCRAZE),
      enrage      = prototype.buff:new("player", buff_enum.ENRAGE),
      suddendeath = prototype.buff:new("player", buff_enum.SUDDEN_DEATH),
      whirlwind   = prototype.buff:new("player", buff_enum.whirlwind),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      -- gushing wound can actually pandemic, but since it's a passive, just make a normal buff
      gushingwound = prototype.buff:new("target", buff_enum.GUSHING_WOUND),
      -- pandemic
      -- agony              = prototype.pandemicbuff:new("target", buff_enum.AGONY, skill_enum.AGONY),
   }
)


---------------------- fury -----------------------
local fury = extends(prototype.spec)

function fury:new()
   local o = fury.__super.new(
      self,
      "fury",
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

function fury:load()
   fury.__super.load(self)
   -- self:register(self.traits, "TRAIT_CONFIG_UPDATED", traits.traitconfigupdated)
end

function fury:update(now)

   fury.__super.update(self, now)
   
   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.rampage.usable) then
	 skill = skill_enum.RAMPAGE
      elseif (skills.execute.usable) then
	 skill = skill_enum.EXECUTE
      elseif (skills.ragingblow.usable and
	      (not traits.annihilator.selected)
      ) then
	 skill = skill_enum.RAGING_BLOW
      elseif (skills.bloodthirst.usable) then
	 skill = skill_enum.BLOODTHIRST
      elseif (skills.slam.usable and
	      traits.annihilator.selected
      ) then
	 skill = warrior.skill_enum.SLAM
      elseif (skills.whirlwind.usable) then
	 skill = skill_enum.WHIRLWIND
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
warrior.fury = fury:new()
