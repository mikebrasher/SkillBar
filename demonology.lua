local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warlock = SkillBar.warlock


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
local soulshard = prototype.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents = prototype.data:new(
   {
      --darksoulinstability = { selected = false },
   }
)

function talents:playertalentupdate()
   --self.darksoulinstability.selected = select(4, GetTalentInfo(7, 3, 1))
end


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      bilescourgebombers  = prototype.skill:new(skill_enum.BILESCOURGE_BOMBERS),
      calldreadstalkers   = prototype.skill:new(skill_enum.CALL_DREADSTALKERS),
      demonbolt           = prototype.skill:new(skill_enum.DEMONBOLT),
      demonicstrength     = prototype.skill:new(skill_enum.DEMONIC_STRENGTH),
      doom                = prototype.skill:new(skill_enum.DOOM),
      grimoirefelguard    = prototype.skill:new(skill_enum.GRIMOIRE_FELGUARD),
      handofguldan        = prototype.skill:new(skill_enum.HAND_OF_GULDAN),
      implosion           = prototype.skill:new(skill_enum.IMPLOSION),
      netherportal        = prototype.skill:new(skill_enum.NETHER_PORTAL),
      powersiphon         = prototype.skill:new(skill_enum.POWER_SIPHON),
      shadowbolt          = prototype.skill:new(warlock.skill_enum.SHADOW_BOLT),
      soulstrike          = prototype.skill:new(skill_enum.SOUL_STRIKE),
      summondemonictyrant = prototype.skill:new(skill_enum.SUMMON_DEMONIC_TYRANT),
      summonfelguard      = prototype.skill:new(skill_enum.SUMMON_FELGUARD),
      summonvilefiend     = prototype.skill:new(skill_enum.SUMMON_VILEFIEND),
   }
)


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      demoniccore = prototype.buff:new("player", buff_enum.DEMONIC_CORE),
   }
)


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      fromtheshadows = prototype.buff:new("target", buff_enum.FROM_THE_SHADOWS),

      -- dots
      doom = prototype.pandemicbuff:new("target", buff_enum.DOOM, skill_enum.DOOM),
   }
)


----------------- imp ------------------
local imp = extends(prototype.data)
imp.duration = 20 -- static

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

   imp.__super.update(self, now)
   
   self.remaining = self.endtime - now
   self.active = (self.remaining > 0) and (self.energy > 0)
   
end


----------------- tyrant ------------------
local tyrant = extends(prototype.data)

function tyrant:new()
   local o = tyrant.__super.new(
      self,
      {
	 timeout = 15,
	 endtime = 0,
	 active = false,
      }
   )
   setmetatable(o, self)
   return o
end

function tyrant:update(now)
   tyrant.__super.update(self, now)
   --print(string.format("tyrant update: %s %s", tostring(now), tostring(self.endtime)))
   self.active = now < self.endtime
end

function tyrant:summon(now)
   self.endtime = now + self.timeout
end


----------------- wild imps ------------------
local wildimps = prototype.data:new(
   {
      count = 0,
      imps = {},
      tyrant = tyrant:new(),
   }
)

function wildimps:update(now)

   --print(string.format("wildimps update: %f count = %d", now, self.count))
   
   self.tyrant:update(now)

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
   --print(string.format("wildimps cleu: %s %d %s", subevent, spellID, spellName))

   -- TODO: deal with power siphon
   
   -- Imp summoned
   -- use name since different spellIDs for HoG and Inner Demons
   if ((subevent == "SPELL_SUMMON") and
	 (sourceGUID == common.player.guid) and
	 (spellName == "Wild Imp")
   ) then
      --print(string.format("wild imps spell summon: %s", destguid))
      self.imps[destGUID] = imp:new(now)
   elseif (subevent == "SPELL_CAST_SUCCESS") then
      
      -- Imp casts a fel firebolt. Check if the imp belongs to the player
      if ((self.imps[sourceGUID] ~= nil) and
	    (spellID == skill_enum.FEL_FIREBOLT)
      ) then

	 if (not self.tyrant.active) then
	    self.imps[sourceGUID]:cast()
	 end
	 
      elseif (sourceGUID == common.player.guid) then
	 
	 if (spellID == skill_enum.SUMMON_DEMONIC_TYRANT) then
	    
	    -- All current imps are extended
	    for _,imp in pairs(self.imps) do
	       imp:extend()
	    end
	    
	    self.tyrant:summon(now)
	    
	 elseif (spellID == skill_enum.IMPLOSION) then
	    -- Remove all imps
	    for guid,_ in pairs(self.imps) do
	       self.imps[guid] = nil
	    end
	 end
	 
      end        
      
   end

end


----------------- demonology ------------------
local demonology = extends(prototype.spec)

function demonology:new()
   local o = demonology.__super.new(
      self,
      "demonology",
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
   setmetatable(o, self)
   return o
end

function demonology:load()
   --print("demonology load")
   demonology.__super.load(self)
--   self:register(self.talents, "PLAYER_TALENT_UPDATE", self.talents.playertalentupdate)
--   self:register(self.target_debuffs, "PLAYER_TALENT_UPDATE", self.target_debuffs.updatethreshold)
   self:register(self.wildimps, "COMBAT_LOG_EVENT_UNFILTERED", self.wildimps.cleu)
end

function demonology:update(now)

   --print(string.format("demonology update: %f", now))
   demonology.__super.update(self, now)

   local gcd = common.gcd.current
   local wildimps = self.wildimps
   
   ----- power -----
   --soulshard:update()
   
   ----- buffs -----
   --player_buffs:update(now)
   --target_debuffs:update(now)

   ----- wild imps -----
   --wildimps:update(now)
    
   ----- skills -----
   --skills:update(now)
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   local enemies = common.enemies.target.near10

   if (InCombatLockdown()) then
      if (skills.doom.usable and
	     target_debuffs.doom.pandemic.active
      ) then
	 skill = skill_enum.DOOM
      elseif (skills.summonvilefiend.usable) then
	    skill = skill_enum.SUMMON_VILEFIEND
      elseif (skills.bilescourgebombers.usable) then
	 skill = skill_enum.BILESCOURGE_BOMBERS
      elseif (skills.calldreadstalkers.usable) then
	 skill = skill_enum.CALL_DREADSTALKERS
      elseif (skills.handofguldan.usable and
		 (soulshard.current >= 4)
      ) then
	 skill = skill_enum.HAND_OF_GULDAN
      elseif (skills.soulstrike.usable and
		 (soulshard.deficit >= 1)
      ) then
	 skill = skill_enum.SOUL_STRIKE
      elseif (skills.demonbolt.usable and
		 (
		    (soulshard.deficit >= 2) and
		       (
			  (player_buffs.demoniccore.count >= 2) or
			     (
				(player_buffs.demoniccore.count >= 1) and
				   (player_buffs.demoniccore.remaining < 5)
			     )
		       )

		 )
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
      broadcast:skill(skill)
   end

end


----------------------- warlock --------------------------
warlock.demonology = demonology:new()
