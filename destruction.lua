local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warlock = SkillBar.warlock


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      CATACLYSM = 152108,
      CHANNEL_DEMONFIRE = 196447,
      CHAOS_BOLT = 116858,
      CONFLAGRATE = 17962,
      DARK_SOUL_INSTABILITY = 113858,
      HAVOC = 80240,
      IMMOLATE = 348,
      INCINERATE = 29722,
      MORTAL_COIL = 6789,
      RAIN_OF_FIRE = 5740,
      SHADOWBURN = 17877,
      SHADOWFURY = 30283,
      SOUL_FIRE = 6353,
      SUMMON_INFERNAL = 1122,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      BACKDRAFT = 117828,
      DARK_SOUL_INSTABILITY = 113858,
      
      -- debuffs
      CONFLAGRATE = 265931,
      ERADICATION = 196414,
      HAVOC = 80240,
      IMMOLATE = 157736,
      SHADOWBURN = 17877,
   }


----------------- soulshard ------------------
local soulshard = prototype.power:new(Enum.PowerType.SoulShards, true)


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      darksoulinstability = prototype.talent:new(7, 3),
      eradication         = prototype.talent:new(1, 2),
      flashover           = prototype.talent:new(1, 1),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      cataclysm           = prototype.skill:new(skill_enum.CATACLYSM),
      channeldemonfire    = prototype.skill:new(skill_enum.CHANNEL_DEMONFIRE),
      chaosbolt           = prototype.skill:new(skill_enum.CHAOS_BOLT),
      darksoulinstability = prototype.skill:new(skill_enum.DARK_SOUL_INSTABILITY),
      havoc               = prototype.skill:new(skill_enum.HAVOC),
      immolate            = prototype.skill:new(skill_enum.IMMOLATE),
      incinerate          = prototype.skill:new(skill_enum.INCINERATE),
      conflagrate         = prototype.skill:new(skill_enum.CONFLAGRATE),
      rainoffire          = prototype.skill:new(skill_enum.RAIN_OF_FIRE),
      shadowburn          = prototype.skill:new(skill_enum.SHADOWBURN),
      soulfire            = prototype.skill:new(skill_enum.SOUL_FIRE),
      summoninfernal      = prototype.skill:new(skill_enum.SUMMON_INFERNAL),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      backdraft           = prototype.buff:new("player", buff_enum.BACKDRAFT),
      darksoulinstability = prototype.buff:new("player", buff_enum.DARK_SOUL_INSTABILITY),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      conflagrate = prototype.buff:new("target", buff_enum.CONFLAGRATE),
      eradication = prototype.buff:new("target", buff_enum.ERADICATION),
      havoc = prototype.buff:new("target", buff_enum.HAVOC),
      --havoc = prototype.multitargetdebuff:new(buff_enum.HAVOC),
      shadowburn = prototype.buff:new("target", buff_enum.SHADOWBURN),
      -- pandemic
      immolate = prototype.pandemicbuff:new("target", buff_enum.IMMOLATE, skill_enum.IMMOLATE),
   }
)


----------------- destruction ------------------
local destruction = extends(prototype.spec)

function destruction:new()
   local o = destruction.__super.new(
      self,
      "destruction",
      {
	 skill = skill_enum.NIL,
	 skill_enum = skill_enum,
	 buff_enum = buff_enum,
	 soulshard = soulshard,
	 talents = talents,
	 skills = skills,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
      }
   )
   setmetatable(o, self)
   return o
end

--function destruction:load()
--
--   destruction.__super.load(self)
--
--   self:register(self.talents, "PLAYER_TALENT_UPDATE", self.talents.playertalentupdate)
--   self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", self.target_debuffs.updatethreshold)
--   
--end

function destruction:update(now)

   --print("destruction update")

   destruction.__super.update(self, now)

   local gcd = common.gcd.current
   
   ----- power -----
   --soulshard:update(now)
   
   ----- buffs -----
   --player_buffs:update(now)
   --target_debuffs:update(now)
    
   ----- skills -----
   --skills:update(now)
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.target.near10
   local pool_soulshard =
      ((enemies > 1) and (skills.havoc.cd <= 10)) or
      (
	 talents.darksoulinstability.selected and
	    (skills.darksoulinstability.cd < 15)
      )
   
   if (InCombatLockdown()) then
      if (skills.immolate.usable and
	     target_debuffs.immolate.pandemic.active
      ) then
	 skill = skill_enum.IMMOLATE
      elseif (skills.chaosbolt.usable and
		 (soulshard.deficit < 5)
      ) then
	 skill = skill_enum.CHAOS_BOLT
      elseif (skills.cataclysm.usable) then
	 skill = skill_enum.CATACLYSM
      elseif (skills.conflagrate.usable and
		 skills.conflagrate.charges.capped
      ) then
	 skill = skill_enum.CONFLAGRATE
      elseif (skills.chaosbolt.usable and
		 (
		    (player_buffs.darksoulinstability.active) or
		       (
			     not pool_soulshard and
			     (
				player_buffs.backdraft.active or
				   (
				      (not talents.eradication.selected) or
					 (
					    talents.eradication.selected and
					       (target_debuffs.eradication.remaining < 3)
					 )
				      
				   )
			     )
		       )
		 )
      ) then
	 skill = skill_enum.CHAOS_BOLT
      elseif (skills.conflagrate.usable and
		 (
		    (not pool_soulshard) and
		       (not player_buffs.backdraft.active) and
		       (soulshard.current >= 15)
		 )
      ) then
	 skill = skill_enum.CONFLAGRATE
      elseif (skills.shadowburn.usable) then
	 skill = skill_enum.SHADOWBURN
      elseif (skills.incinerate.usable) then
	 skill = skill_enum.INCINERATE
      end
   else
      skill = skill_enum.NIL
   end
   
   if (skill ~= self.skill) then
      self.skill = skill
      broadcast:skill(skill)
   end

end


----------------------- warlock --------------------------
warlock.destruction = destruction:new()
