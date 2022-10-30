local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warrior = SkillBar.warrior


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      CLEAVE = 845,
      COLOSSUS_SMASH = 167105,
      DIE_BY_THE_SWORD = 118038,
      MORTAL_STRIKE = 12294,
      OVERPOWER = 7384,
      REND = 772,
      SKULLSPLITTER = 260643,
      SWEEPING_STRIKES = 260708,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      SWEEPING_STRIKES = 260708,
      DIE_BY_THE_SWORD = 118038,
      OVERPOWER = 7384,
      
      -- debuffs      
      COLOSSUS_SMASH = 208086,
      REND = 388539,
      DEEP_WOUNDS = 262115,
   }


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      --absolutecorruption = prototype.talent:new(2, 2),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      colossussmash = prototype.skill:new(skill_enum.COLOSSUS_SMASH),
      execute       = prototype.skill:new(warrior.skill_enum.EXECUTE),
      mortalstrike  = prototype.skill:new(skill_enum.MORTAL_STRIKE),
      overpower     = prototype.skill:new(skill_enum.OVERPOWER),
      slam          = prototype.skill:new(warrior.skill_enum.SLAM),
      rend          = prototype.skill:new(skill_enum.REND),
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


---------------------- protection -----------------------
local protection = extends(prototype.spec)

function protection:new()
   local o = protection.__super.new(
      self,
      "protection",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 talents = talents,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

function protection:load()

   protection.__super.load(self)

   --self:register(self.talents, "PLAYER_TALENT_UPDATE", talents.playertalentupdate)
   --self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", target_debuffs.updatethreshold)
   --self:register(self.target_debuffs.shadowembrace, "COMBAT_LOG_EVENT_UNFILTERED", self.target_debuffs.shadowembrace.cleu)
   --self:register(self.target_debuffs.unstableaffliction, "PLAYER_REGEN_DISABLED", self.target_debuffs.unstableaffliction.checkpvp)
   
end

function protection:update(now)

   protection.__super.update(self, now)
   
   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.execute.usable) then
	 skill = warrio.skill_enum.EXECUTE
      elseif (skills.mortalstrike.usable) then
	 skill = skill_enum.MORTAL_STRIKE
      elseif (skills.overpower.usable) then
	 skill = skill_enum.OVERPOWER
      elseif (skills.rend.usable) then
	 skill = skill_enum.REND
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
warrior.protection = protection:new()
