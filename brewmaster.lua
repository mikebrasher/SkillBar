local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local monk = SkillBar.monk


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BLACK_OX_BREW = 115399,      
      BREATH_OF_FIRE = 115181,
      CELESTIAL_BREW = 322507,
      EXPLODING_KEG = 214326,
      INVOKE_NIUZAO_THE_BLACK_OX = 132578,
      KEG_SMASH = 121253,
      PURIFYING_BREW = 119582,
      SUMMON_BLACK_OX_STATUE = 115315,
      ZEN_MEDITATION = 115176,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      BLACKOUT_COMBO = 228563,
      CELESTIAL_FLAMES = 325190,
      PURIFIED_CHI = 325092,
      RUSHING_JADE_WIND = 116847,
      SHUFFLE = 215479,

      -- player debuffs
      LIGHT_STAGGER = 124275,
      MODERATE_STAGGER = 124274,
      HEAVY_STAGGER = 124273,
      
      -- debuffs
      BREATH_OF_FIRE = 123725,
      KEG_SMASH = 121253,
      MYSTIC_TOUCH = 113746,
   }


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      bobandweave = prototype.talent:new(5, 1)
   }
)


----------------- stagger ------------------
local stagger = prototype.data:new(
   {
      current = 0,
      tick = 0,
      light = false,
      moderate = false,
      heavy = false,
   }
)

function stagger:update(now)

   self.current = UnitStagger("player")

   local tickcount = 20
   if (talents.bobandweave.selected) then
      tickcount = 26
   end

   self.tick = self.current / tickcount

   self.light = false
   self.moderate = false
   self.heavy = false
   for ibuff = 1, 40 do
      
      local name, _, count, _, duration, expirationTime, source, _, _, spellID, _, _, castByPlayer
	 = UnitAura("player", ibuff, "HARMFUL|PLAYER")

      if (spellID == buff_enum.LIGHT_STAGGER) then
	 self.light = true
      elseif (spellID == buff_enum.MODERATE_STAGGER) then
	 self.moderate = true
      elseif (spellID == buff_enum.HEAVY_STAGGER) then
	 self.heavy = true
      end
      
   end
   
end


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      blackoutkick    = prototype.skill:new(monk.skill_enum.BLACKOUT_KICK),
      breathoffire    = prototype.skill:new(skill_enum.BREATH_OF_FIRE),
      celestialbrew   = prototype.skill:new(skill_enum.CELESTIAL_BREW),
      chiwave         = prototype.skill:new(monk.skill_enum.CHI_WAVE),
      chiburst        = prototype.skill:new(monk.skill_enum.CHI_BURST),
      explodingkeg    = prototype.skill:new(skill_enum.EXPLODING_KEG),
      kegsmash        = prototype.skill:new(skill_enum.KEG_SMASH),
      rushingjadewind = prototype.skill:new(monk.skill_enum.RUSHING_JADE_WIND),
      tigerpalm       = prototype.skill:new(monk.skill_enum.TIGER_PALM),
   }
)


----------------- purified chi ------------------
local purifiedchi = extends(prototype.buff)

function purifiedchi:new()
   local o = purifiedchi.__super.new(self, "player", buff_enum.PURIFIED_CHI)
   o.current = 0
   o.multiplier = 1
   setmetatable(o, self)
   return o
end

function purifiedchi:update(now)
   purifiedchi.__super.update(self, now)

   self.current = 0
   if (self.extra) then
      self.current = self.extra[3]
   end

   self.multiplier = 1 + self.current / 100

end

----------------- player buffs ------------------
local player_buffs = prototype.bufflist:new(
   {
      blackoutcombo   = prototype.buff:new("player", buff_enum.BLACKOUT_COMBO),
      celestialflames = prototype.buff:new("player", buff_enum.CELESTIAL_FLAMES),
      purifiedchi     = purifiedchi:new(),
      rushingjadewind = prototype.pandemicbuff:new("player", buff_enum.RUSHING_JADE_WIND, monk.skill_enum.RUSHING_JADE_WIND),
      shuffle         = prototype.buff:new("player", buff_enum.SHUFFLE),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.bufflist:new(
   {
      -- normal
      breathoffire = prototype.buff:new("target", buff_enum.BREATH_OF_FIRE), -- dot does not pandemic
      kegsmash     = prototype.buff:new("target", buff_enum.KEG_SMASH),
   }
)


----------------- brewmaster ------------------
local brewmaster = extends(prototype.spec)

function brewmaster:new()
   local o = brewmaster.__super.new(
      self,
      "brewmaster",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 soulshard = soulshard,
	 talents = talents,
	 stagger = stagger,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

function brewmaster:update(now)

   --print("brewmaster update")

   brewmaster.__super.update(self, now)

   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.melee
   
   if (InCombatLockdown()) then
      if (skills.kegsmash.usable) then
	 skill = skill_enum.KEG_SMASH
      elseif (skills.blackoutkick.usable) then
	 skill = monk.skill_enum.BLACKOUT_KICK
      elseif (skills.breathoffire.usable) then
	 skill = skill_enum.BREATH_OF_FIRE
      elseif (skills.rushingjadewind.usable and
		 player_buffs.rushingjadewind.pandemic.active
      ) then
	 skill = monk.skill_enum.RUSHING_JADE_WIND
      elseif (skills.tigerpalm.usable and
		 (monk.energy.current > 65)
      ) then
	 skill = monk.skill_enum.TIGER_PALM
      end
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end

end


----------------------- monk --------------------------
monk.brewmaster = brewmaster:new()
