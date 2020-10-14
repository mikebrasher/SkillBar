local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local mage = SkillBar.mage


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BLIZZARD = 190356,
      COLD_SNAP = 235219,
      COMET_STORM = 153595,
      CONE_OF_COLD = 120,
      EBONBOLT = 214634,
      FLURRY = 228354,
      FROZEN_ORB = 84714,
      GLACIAL_SPIKE = 199786,
      ICE_BARRIER = 198094,
      ICE_FLOES = 108839,
      ICE_LANCE = 30455,
      ICE_NOVA = 157997,
      ICY_VEINS = 12472,
      RAY_OF_FROST = 205021,
      SUMMON_WATER_ELEMENTAL = 31687,
   }
        

----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      BRAIN_FREEZE = 190446,
      FINGERS_OF_FROST = 44544,
      ICICLES = 205473,

      -- debuffs
      WINTERS_CHILL = 228358,
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
      blizzard     = prototype.skill:new(skill_enum.BLIZZARD),
      ebonbolt     = prototype.skill:new(skill_enum.EBONBOLT),
      flurry       = prototype.skill:new(skill_enum.FLURRY),
      frostbolt    = prototype.skill:new(mage.skill_enum.FROSTBOLT),
      frozenorb    = prototype.skill:new(skill_enum.FROZEN_ORB),
      glacialspike = prototype.skill:new(skill_enum.GLACIAL_SPIKE),
      icelance     = prototype.skill:new(skill_enum.ICE_LANCE),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      brainfreeze    = prototype.buff:new("player", buff_enum.BRAIN_FREEZE),
      fingersoffrost = prototype.buff:new("player", buff_enum.FINGERS_OF_FROST),
      icicles        = prototype.buff:new("player", buff_enum.ICICLES),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      winterschill = prototype.buff:new("target", buff_enum.WINTERS_CHILL),
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
	 talents = talents,
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
   local lastcast = common.lastcast.spellID
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.melee
   
   if (InCombatLockdown()) then
      if (skills.icelance.usable and
	     (target_debuffs.winterschill.active)
      ) then
	 skill = skill_enum.ICE_LANCE
      elseif (skills.flurry.usable and
		 (
		    player_buffs.brainfreeze.active and
		       (
			  (
			     (
				(lastcast == skill_enum.EBONBOLT) or
				   (lastcast == mage.skill_enum.FROSTBOLT)
			     ) and
				(player_buffs.icicles.count <= 3)
			  ) or
			     (lastcast == skill_enum.GLACIAL_SPIKE)
		       )
		 )
      ) then
	 skill = skill_enum.FLURRY
      elseif (skills.frozenorb.usable) then
	 skill = skill_enum.FROZEN_ORB
      elseif (skills.icelance.usable and
		 player_buffs.fingersoffrost.active
      ) then
	 skill = skill_enum.ICE_LANCE
      elseif (skills.ebonbolt.usable and
		 (not player_buffs.brainfreeze.active)
      ) then
	 skill = skill_enum.EBONBOLT
      elseif (skills.glacialspike.usable and
		 player_buffs.brainfreeze.active
      ) then
	 skill = skill_enum.GLACIAL_SPIKE
      elseif (skills.frostbolt.usable) then
	 skill = mage.skill_enum.FROSTBOLT
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
mage.frost = frost:new()
