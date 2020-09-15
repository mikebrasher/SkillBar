local data = SkillBar.data
local common = SkillBar.common
local warlock = SkillBar.warlock

local specname = "demonology"


----------------- spec event ------------------
local specevent = {}
function specevent:register(obj, event, func)
   SkillBar.event:register(obj, event, func, specname)
end


----------------- skill enum ------------------
local skill_enum =
   {
      NIL = 0,
      CALL_DREADSTALKERS = 104316,
      DEMONBOLT = 157695,
      HAND_OF_GULDAN = 105174,
      IMPLOSION = 196277,
      SUMMON_DEMONIC_TYRANT = 265187,
      SUMMON_FELGUARD = 30146,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      DEMONIC_CORE = 264173,
      
      -- debuffs
      FROM_THE_SHADOWS = 270569,
   }


----------------- soulshard ------------------
local soulshard = common.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents =
   {
      --darksoulinstability = { selected = false },
   }

function talents:update()
   --self.darksoulinstability.selected = select(4, GetTalentInfo(7, 3, 1))
end
specevent:register(talents, "PLAYER_TALENT_UPDATE", talents.update)


----------------- skills ------------------
local skills =
   {
      calldreadstalkers   = common.skill:new(skill_enum.CALL_DREADSTALKERS),
      demonbolt           = common.skill:new(skill_enum.DEMONBOLT),
      handofguldan        = common.skill:new(skill_enum.HAND_OF_GULDAN),
      implosion           = common.skill:new(skill_enum.IMPLOSION),
      shadowbolt          = common.skill:new(warlock.skill_enum.SHADOWBOLT),
      summondemonictyrant = common.skill:new(skill_enum.SUMMON_DEMONIC_TYRANT),
      summonfelguard      = common.skill:new(skill_enum.SUMMON_FELGUARD),
   }

--TODO: move these functions to a common class
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
      demoniccore = common.buff:new("player", buff_enum.DEMONIC_CORE),
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
      fromtheshadows = common.buff:new("target", buff_enum.FROM_THE_SHADOWS),
   }

--TODO: move these functions to a common class
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


----------------- wild imps ------------------
local wildimps = { count = 0 }


----------------- demonology ------------------
local demonology = data:new(
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
      wildimps = wildimps,
   }
)

function demonology:update(now)

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


   -- TODO: seems to not work after first two conditions
   if (InCombatLockdown()) then
      if (skills.calldreadstalkers.usable) then
	 skill = skill_enum.CALL_DREADSTALKERS
      elseif (skills.handofguldan.usable) then
	 skill = skill_enum.HAND_OF_GULDAN
      elseif (skills.demonbolt.usable and
		 (player_buffs.demoniccore.count > 0)
      ) then
	 skill = skill_enum.DEMONBOLT
      elseif (skills.implosion.usable and
		 (wildimps.count > 6)
      ) then
	 skill = skill_enum.IMPLOSION
      elseif (skills.shadowbolt.usable) then
	 skill = warlock.skill_enum.SHADOW_BOLT
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
warlock.demonology = demonology
