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
      
      -- debuffs
      GARROTE = 703,
      RUPTURE = 1943,

      -- covenant debuffs
      --IMPENDING_CATASTROPHE = 322170,
      --SOUL_ROT = 325640,
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
      garrote      = prototype.skill:new(skill_enum.GARROTE),
      mutilate     = prototype.skill:new(skill_enum.MUTILATE),
      envenom      = prototype.skill:new(skill_enum.ENVENOM),
      rupture      = prototype.skill:new(skill_enum.RUPTURE),
      fanofknives  = prototype.skill:new(skill_enum.FAN_OF_KNIVES),
      shadowstep   = prototype.skill:new(skill_enum.SHADOWSTEP),
      shiv         = prototype.skill:new(rogue.skill_enum.SHIV),
      sliceanddice = prototype.skill:new(rogue.skill_enum.SLICE_AND_DICE),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      envenom      = prototype.buff:new("player", buff_enum.ENVENOM),
      sliceanddice = prototype.buff:new("player", buff_enum.SLICE_AND_DICE),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      --haunt                = prototype.buff:new("target", buff_enum.HAUNT),
      -- pandemic
      garrote = prototype.pandemicbuff:new("target", buff_enum.GARROTE, skill_enum.GARROTE),
      rupture = prototype.pandemicbuff:new("target", buff_enum.RUPTURE, skill_enum.RUPTURE),
   }
)


----------------- affliction ------------------
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
end

function assassination:update(now)

   assassination.__super.update(self, now)
   
   local gcd = common.gcd.current
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.garrote.usable and
	     (
		target_debuffs.garrote.pandemic.active and
		   (rogue.combopoints.deficit >= 1)
	     )
      ) then
	 skill = skill_enum.GARROET
      elseif (skills.fanofknives.usable and
		 (
		    (common.enemies.melee >= 3) and
		       (rogue.combopoints.deficit >= 1)
		 )
	      
      ) then
	 skill = skill_enum.MUTILATE
      elseif (skills.mutilate.usable and
		 (rogue.combopoints.deficit >= 2)
      ) then
	 skill = skill_enum.MUTILATE
      elseif (skills.shiv.usable and
		 (rogue.combopoints.deficit == 1)
      ) then
	 skill = rogue.skill_enum.SHIV
      elseif (skills.rupture.usable and
		 (
		    target_debuffs.rupture.pandemic.active and
		       (rogue.combopoints.current >= 4)
		 )
      ) then
	 skill = skill_enum.RUPTURE
      elseif (skills.sliceanddice.usable and
		 (
		    (player_buffs.sliceanddice.remaining < 5) and
		       (rogue.combopoints.current >= 4)
		 )
      ) then
	 skill = rogue.skill_enum.SLICE_AND_DICE
      elseif (skills.envenom.usable and
		 (
		    (rogue.combopoints.current >= 4)
		 )
      ) then
	 skill = skill_enum.ENVENOM
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
