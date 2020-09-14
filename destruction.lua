local data = SkillBar.data
local common = SkillBar.common
local warlock = SkillBar.warlock

local specname = "destruction"


----------------- spec event ------------------
local specevent = {}
function specevent:register(obj, event, func)
   SkillBar.event:register(obj, event, func, specname)
end


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      BURNING_RUSH = 111400,
      CATACLYSM = 152108,
      CHANNEL_DEMONFIRE = 196447,
      CHAOS_BOLT = 116858,
      CONFLAGRATE = 17962,
      CORRUPTION = 172,      
      CURSE_OF_EXHAUSTION = 334275,
      CURSE_OF_TONGUES = 1714,
      CURSE_OF_WEAKNESS = 702,
      DARK_PACT = 108416,
      DARK_SOUL_INSTABILITY = 113858,
      DEMONIC_CIRCLE = 48018,
      DEMONIC_CIRCLE_TELEPORT = 48020,
      DRAIN_LIFE = 234153,
      FEAR = 5782,
      FEL_DOMINATION = 333889,
      HAVOC = 80240,
      HEALTH_FUNNEL = 755,
      HOWL_OF_TERROR = 5484,
      IMMOLATE = 348,
      INCINERATE = 29722,
      GRIMOIRE_OF_SACRIFICE = 108503,
      MORTAL_COIL = 6789,
      RAIN_OF_FIRE = 5740,
      SEDUCTION = 119909,
      SHADOW_BULWARK = 119907,
      SHADOWBURN = 17877,
      SHADOWFURY = 30283,
      SINGE_MAGIC = 119905,
      SOUL_FIRE = 6353,
      SPELL_LOCK = 119910,
      SUMMON_FELHUNTER = 691,
      SUMMON_IMP = 688,
      SUMMON_INFERNAL = 1122,
      SUMMON_SUCCUBUS = 712,
      SUMMON_VOIDWALKER = 697,
      UNENDING_RESOLVE = 104773,

      -- covenant
      IMPENDING_CATASTROPHE = 322170,

      -- spec dependent or fake versions?
      --SCOURING_TITHE = 312321,
      --IMPENDING_CATASTROPHE = 321792,
      --DECIMATING_BOLT = 325289,
      --SOUL_ROT = 325640,
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
local soulshard = common.power:new(Enum.PowerType.SoulShards, true)


----------------- talents ------------------
local talents =
   {
      darksoulinstability = { selected = false },
      eradication = { selected = false },
      flashover = { selected = false },
   }

function talents:update()
   self.darksoulinstability.selected = select(4, GetTalentInfo(7, 3, 1))
   self.eradication.selected = select(4, GetTalentInfo(1, 2, 1))
   self.flashover.selected = select(4, GetTalentInfo(1, 1, 1))
end
specevent:register(talents, "PLAYER_TALENT_UPDATE", talents.update)


----------------- skills ------------------
local skills =
   {
      cataclysm           = common.skill:new(skill_enum.CATACLYSM),
      chaosbolt           = common.skill:new(skill_enum.CHAOS_BOLT),
      darksoulinstability = common.skill:new(skill_enum.DARK_SOUL_INSTABILITY),
      havoc               = common.skill:new(skill_enum.HAVOC),
      immolate            = common.skill:new(skill_enum.IMMOLATE),
      incinerate          = common.skill:new(skill_enum.INCINERATE),
      conflagrate         = common.skill:new(skill_enum.CONFLAGRATE),
      rainoffire          = common.skill:new(skill_enum.RAIN_OF_FIRE),
      shadowburn          = common.skill:new(skill_enum.SHADOWBURN),
      soulfire            = common.skill:new(skill_enum.SOUL_FIRE),
      summoninfernal      = common.skill:new(skill_enum.SUMMON_INFERNAL),
   }
    
function skills:update(now)
   for _, v in pairs(self) do
      if (type(v) == "table") then
	 local skill = v
	 skill:update(now)
      end
   end
end


----------------- player buffs ------------------
local player_buffs =
   {
      backdraft           = common.buff:new("player", buff_enum.BACKDRAFT),
      darksoulinstability = common.buff:new("player", buff_enum.DARK_SOUL_INSTABILITY),
   }

function player_buffs:update()
   for _, v in pairs(self) do
      if (type(v) == "table") then
	 local buff = v
	 buff:update(now)
      end
   end
end


----------------- target debuffs ------------------
local target_debuffs =
   {
      -- normal
      conflagrate = common.buff:new("target", buff_enum.CONFLAGRATE),
      eradication = common.buff:new("target", buff_enum.ERADICATION),
      havoc = common.buff:new("target", buff_enum.HAVOC),
      --havoc = common.multitargetdebuff:new(buff_enum.HAVOC),
      shadowburn = common.buff:new("target", buff_enum.SHADOWBURN),
      -- pandemic
      immolate = common.pandemicbuff:new("target", buff_enum.IMMOLATE, skill_enum.IMMOLATE),
   }

function target_debuffs:update(now)
   for _,debuff in pairs(self) do
      if (type(debuff) == "table") then
	 debuff:update(now)
      end
   end
end
    
function target_debuffs:updatethreshold()
   for k,debuff in pairs(self) do
      if (type(debuff) == "table") then
	 local pandemic = debuff.pandemic
	 if (pandemic) then
	    --print(string.format("%s %s", k, tostring(pandemic)))
	    debuff:updatethreshold()
	 end
      end
   end
end
--specevent:register(target_debuffs, "PLAYER_REGEN_DISABLED", target_debuffs.updatethreshold)
specevent:register(target_debuffs, "PLAYER_TALENT_UPDATE", target_debuffs.updatethreshold)


----------------- destruction ------------------
local destruction = data:new(
   specname,
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

function destruction:update(now)

   local gcd = common.gcd.current
   
   ----- power -----
   soulshard:update()
   
   ----- buffs -----
   player_buffs:update(now)
   target_debuffs:update(now)
    
   ----- skills -----
   skills:update(now)
    
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
      common:broadcastskill(skill)
   end

end


----------------------- warlock --------------------------
warlock.destruction = destruction
