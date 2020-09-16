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
      BILESCOURGE_BOMBERS = 267211,
      CALL_DREADSTALKERS = 104316,      
      DEMONBOLT = 157695,
      DEMONIC_STRENGTH = 267171,
      DOOM = 603,
      GRIMOIRE_FELGUARD = 111898,
      HAND_OF_GULDAN = 105174,
      IMPLOSION = 196277,
      INNER_DEMONS = 279910, -- spell name is wild imp, but imp summon is due to this talent
      NETHER_PORTAL = 267217,
      POWER_SIPHON = 264130,
      SOUL_STRIKE = 264057,
      SUMMON_DEMONIC_TYRANT = 265187,
      SUMMON_FELGUARD = 30146,
      SUMMON_VILEFIEND = 264119,
      WILD_IMP = 104317,
      FEL_FIREBOLT = 104318,
   }


----------------- buff enum ------------------
local buff_enum =
   {
      -- buffs
      DEMONIC_CALLING = 205146,
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
      shadowbolt          = common.skill:new(warlock.skill_enum.SHADOW_BOLT),
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

function player_buffs:update(now)
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


----------------- imp ------------------
local imp =
   {
      duration = 20,
   }
imp.__index = imp

function imp:new(now)
   local o =
      {
	 energy = 6, -- imps appear to get 6 casts now in shadowlands
	 endtime = now + self.duration,
	 remaining = self.duration,
	 active = true,
      }
   setmetatable(o, self)
   return o
end

function imp:cast()
   self.energy = self.energy - 1
end

function imp:extend()
   self.endtime = self.endtime + 15
end

function imp:update(now)
   self.remaining = self.endtime - now
   self.active = (self.remaining > 0) and (self.energy > 0)  
end


----------------- tyrant ------------------
local tyrant =
   {
      timeout = 15,
      endtime = 0,
      active = false,
   }

function tyrant:update(now)
   self.active = now < self.endtime
end

function tyrant:summon(now)
   self.endtime = now + self.timeout
end


----------------- wild imps ------------------
local wildimps =
   {
      count = 0,
      imps = {},
      tyrant = tyrant,
   }

function wildimps:update(now)
   
   tyrant:update(now)

   self.count = 0
   for guid,imp in pairs(self.imps) do
      imp:update(now)
      if (imp.active) then
	 self.count = self.count + 1
      else
	 self.imps[guid] = nil
      end
   end
   
end

function wildimps:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)
   
   local now = GetTime()
   
   -- Imp summoned
   if ((subevent == "SPELL_SUMMON") and
	 (sourceGUID == common.playerGUID) and
	 (
	    (spellID == skill_enum.WILD_IMP) or
	       (spellID == skill_enum.INNER_DEMONS)
	 )
   ) then
      self.imps[destGUID] = imp:new(now)
   elseif (subevent == "SPELL_CAST_SUCCESS") then
      
      -- Imp casts a fel firebolt. Check if the imp belongs to the player
      if ((self.imps[sourceGUID] ~= nil) and
	    (spellID == skill_enum.FEL_FIREBOLT)
      ) then

	 if (not tyrant.active) then
	    self.imps[sourceGUID]:cast()
	 end
	 
      elseif (sourceGUID == common.playerGUID) then
	 
	 if (spellID == skill_enum.SUMMON_DEMONIC_TYRANT) then
	    
	    -- All current imps are extended
	    for _,imp in pairs(self.imps) do
	       imp:extend()
	    end
	    
	    tyrant:summon(now)
	    
	 elseif (spellID == skill_enum.IMPLOSION) then
	    -- Remove all imps
	    for guid,_ in pairs(self.imps) do
	       self.imps[guid] = nil
	    end
	 end
	 
      end        
      
   end

end
specevent:register(wildimps, "COMBAT_LOG_EVENT_UNFILTERED", wildimps.cleu)


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

   ----- wild imps -----
   wildimps:update(now)
    
   ----- skills -----
   skills:update(now)
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.target.near10

   if (InCombatLockdown()) then
      if (skills.calldreadstalkers.usable) then
	 skill = skill_enum.CALL_DREADSTALKERS
      elseif (skills.handofguldan.usable and
		 (soulshard.current >= 4)
      ) then
	 skill = skill_enum.HAND_OF_GULDAN
      elseif (skills.demonbolt.usable and
		 (player_buffs.demoniccore.count >= 2)
      ) then
	 skill = skill_enum.DEMONBOLT
      elseif (skills.implosion.usable and
		 (wildimps.count > 6) and
		 (enemies > 1)
      ) then
	 skill = skill_enum.IMPLOSION
      elseif (skills.handofguldan.usable and
		 (soulshard.current >= 3)
      ) then
	 skill = skill_enum.HAND_OF_GULDAN
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
