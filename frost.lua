local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local mage = SkillBar.mage


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      --[[
      BLIZZARD = ,
      COLD_SNAP = ,
      COMET_STORM = ,
      CONE_OF_COLD = ,
      EBONBOLT = ,
      FLURRY = ,
      FROZEN_ORB = ,
      GLACIAL_SPIKE = ,
      ICE_BARRIER = ,
      ICE_FLOES = ,
      ICE_LANCE = ,
      ICE_NOVA = ,
      ICY_VEINS = ,
      RAY_OF_FROST = ,
      SUMMON_WATER_ELEMENTAL = ,
      --]]
   }


----------------- buff enum ------------------
local buff_enum =
   {
      --[[
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
      --]]
   }


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      --bobandweave = prototype.talent:new(5, 1)
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      --[[
      blackoutkick    = prototype.skill:new(monk.skill_enum.BLACKOUT_KICK),
      breathoffire    = prototype.skill:new(skill_enum.BREATH_OF_FIRE),
      celestialbrew   = prototype.skill:new(skill_enum.CELESTIAL_BREW),
      chiwave         = prototype.skill:new(monk.skill_enum.CHI_WAVE),
      chiburst        = prototype.skill:new(monk.skill_enum.CHI_BURST),
      explodingkeg    = prototype.skill:new(skill_enum.EXPLODING_KEG),
      kegsmash        = prototype.skill:new(skill_enum.KEG_SMASH),
      rushingjadewind = prototype.skill:new(monk.skill_enum.RUSHING_JADE_WIND),
      tigerpalm       = prototype.skill:new(monk.skill_enum.TIGER_PALM),
      --]]
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      --[[
      blackoutcombo   = prototype.buff:new("player", buff_enum.BLACKOUT_COMBO),
      celestialflames = prototype.buff:new("player", buff_enum.CELESTIAL_FLAMES),
      purifiedchi     = purifiedchi:new(),
      rushingjadewind = prototype.pandemicbuff:new("player", buff_enum.RUSHING_JADE_WIND, monk.skill_enum.RUSHING_JADE_WIND),
      shuffle         = prototype.buff:new("player", buff_enum.SHUFFLE),
      --]]
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      -- breathoffire = prototype.buff:new("target", buff_enum.BREATH_OF_FIRE), -- dot does not pandemic
   }
)


----------------- frost ------------------
local frost = extends(prototype.spec)

function frost:new()
   local o = frost.__super.new(
      self,
      "frost",
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

function frost:update(now)

   --print("frost update")

   frost.__super.update(self, now)

   local gcd = common.gcd.current
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.melee
   
   if (InCombatLockdown()) then
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end

end


----------------------- mage --------------------------
mage.frost = frost:new()
