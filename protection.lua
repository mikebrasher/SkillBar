local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warrior = SkillBar.warrior


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      AVATAR = 401150,
      CHALLENGING_SHOUT = 1161,
      DEFENSIVE_STANCE = 386208,
      DEMORALIZING_SHOUT = 1160,
      IGNORE_PAIN = 190456,
      LAST_STAND = 12975,
      RAVAGER = 228920,
      REND = 394062,
      REVENGE = 6572,
      SHIELD_CHARGE = 385952,
      SHIELD_WALL = 871,
      THUNDER_CLAP = 6343,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      AVATAR = 401150,
      BRACE_FOR_IMPACT = 386029,
      IGNORE_PAIN = 190456,
      REVENGE = 5302,
      SUDDEN_DEATH = 52437,
      SEEING_RED = 386486,
      SHIELD_BLOCK = 132404,
      VIOLENT_OUTBURST = 386478,
      
      -- debuffs      
      COLOSSUS_SMASH = 208086,
      REND = 388539,
      DEEP_WOUNDS = 262115,
   }


----------------- traits ------------------
-- check SkillBar.common.traits in game using virag dev tool
local traits = prototype.traitlist:new(
   {
      -- annihilator      = prototype.trait:new(90419),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      execute           = prototype.executeskill:new(warrior.skill_enum.EXECUTE, 0.2),
      demoralizingshout = prototype.skill:new(skill_enum.DEMORALIZING_SHOUT),
      ignorepain        = prototype.skill:new(skill_enum.IGNORE_PAIN),
      revenge           = prototype.skill:new(skill_enum.REVENGE),
      shieldblock       = prototype.skill:new(warrior.skill_enum.SHIELD_BLOCK),
      shieldslam        = prototype.skill:new(warrior.skill_enum.SHIELD_SLAM),
      taunt             = prototype.skill:new(warrior.skill_enum.TAUNT),
      thunderclap       = prototype.skill:new(skill_enum.THUNDER_CLAP),
   }
)


--------------- ignore pain ---------------
local ignorepain = extends(prototype.buff)

function ignorepain:new()
   local o = ignorepain.__super.new(self, "player", buff_enum.IGNORE_PAIN)
   o.current = 0
   o.cast = 0
   o.cap = 0
   o.rage_cost = 35
   setmetatable(o, self)
   return o
end

function ignorepain:update(now)
   
   ignorepain.__super.update(self, now)
   
   -- Currently, there are 4 cost tables for IP one for each spec aura (and base warrior)
   -- The table where hasRequiredAura is true has the correct cost
   local costTables = GetSpellPowerCost(skill_enum.IGNORE_PAIN)
   for _, costTable in pairs(costTables) do
      if costTable.hasRequiredAura then
	 self.rage_cost = costTable.cost
	 break
      end
   end

   self.current = self.extra[3] or 0
   
   -- ip absorb appears to be
   --local maxIP = (strength + dps * 6) * 3.5 * mastery * versatility
   -- to within a few damage, but can't figure out a good way to query weapon dps
   -- so, for now, just scrape the tooltip to get the cast size
   self.cast = 0
   local description = GetSpellDescription(skill_enum.IGNORE_PAIN)
   if (description) then
      local match = description:match("%d+%S+%d");
      if (match) then
	 local gsub = match:gsub("%D","")
	 if (gsub) then
	    self.cast = tonumber(gsub)
	 end
      end
   end
   
   self.cap = 0.3 * common.player.healthmax
   
   local diff = self.cap - self.current
   local actual = math.min(diff, self.cast)
   
end


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      avatar         = prototype.buff:new("player", buff_enum.AVATAR),
      braceforimpact = prototype.buff:new("player", buff_enum.BRACE_FOR_IMPACT),
      ignorepain     = ignorepain:new(),
      revenge        = prototype.buff:new("player", buff_enum.REVENGE),
      suddendeath    = prototype.buff:new("player", buff_enum.SUDDEN_DEATH),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      --colossussmash = prototype.buff:new("target", buff_enum.COLOSSUS_SMASH),
      -- pandemic
      --deepwounds    = prototype.pandemicbuff:new("target", buff_enum.DEEP_WOUNDS, skill_enum.CLEAVE),
      --rend          = prototype.pandemicbuff:new("target", buff_enum.REND, skill_enum.REND),
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
	 traits = traits,
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
      if (skills.thunderclap.usable and
	  (
	     player_buffs.avatar.active
	  )
      ) then
	 skill = skill_enum.THUNDER_CLAP
      elseif (skills.shieldslam.usable) then
	 skill = warrior.skill_enum.SHIELD_SLAM
      elseif (skills.thunderclap.usable) then
	 skill = skill_enum.THUNDER_CLAP
      elseif (skills.execute.usable) then
	 skill = warrior.skill_enum.EXECUTE
      elseif (skills.revenge.usable and
	      (
		 player_buffs.revenge.active or
		 (warrior.rage.current >= 60)
	      )
      ) then
	 skill = skill_enum.REVENGE
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
