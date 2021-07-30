local extends = SkillBar.extends
local broadcast = SkillBar.broadcast
local prototype = SkillBar.prototype
local common = SkillBar.common
local warlock = SkillBar.warlock
local next = next


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
      HAND_OF_GULDAN_SPLASH = 86040,
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
      DEMONIC_POWER = 265273,
      NETHER_PORTAL = 267218,
      
      -- debuffs
      FROM_THE_SHADOWS = 270569,
      DOOM = 37, -- TODO: find real value
   }


----------------- soulshard ------------------
local soulshard = prototype.power:new(Enum.PowerType.SoulShards)


----------------- talents ------------------
local talents = prototype.talentlist:new(
   {
      demoniccalling = prototype.talent:new(2, 1),
      sacrificedsouls = prototype.talent:new(7, 1),
      summonvilefiend = prototype.talent:new(4, 3),
   }
)


----------------- pet ------------------
local pet = extends(prototype.data)

function pet:new(duration, now)
   local o = pet.__super.new(
      self,
      {
	 duration = duration or 0,
	 endtime = now + duration,
	 remaining = 0,
	 active = false,
      }
   )
   setmetatable(o, self)
   return o
end

--function pet:summon(now)
--   self.endtime = now + self.duration
--end

function pet:extend(amount)
   if (self.active) then
      self.endtime = self.endtime + amount
   end
end

function pet:update(now)

   --print("pet:update(%f)", now)

   pet.__super.update(self, now)
   
   self.remaining = self.endtime - now
   self.active = (self.remaining > 0)
   
end


----------------- demonictyrant ------------------
local demonictyrant = extends(pet)

function demonictyrant:new(now)
   local o = demonictyrant.__super.new(self, 15, now)
   setmetatable(o, self)
   return o
end


----------------- dreadstalker ------------------
local dreadstalker = extends(pet)

function dreadstalker:new(now)
   --print("dreadstalker:new()")
   local o = dreadstalker.__super.new(self, 12, now)
   setmetatable(o, self)
   return o
end


----------------- grimoirefelguard ------------------
local grimoirefelguard = extends(pet)

function grimoirefelguard:new(now)
   local o = grimoirefelguard.__super.new(self, 17, now)
   setmetatable(o, self)
   return o
end


----------------- vilefiend ------------------
local vilefiend = extends(pet)

function vilefiend:new(now)
   local o = vilefiend.__super.new(self, 15, now)
   setmetatable(o, self)
   return o
end


----------------- wild imp ------------------
local wildimp = extends(pet)

function wildimp:new(now)
   local o = wildimp.__super.new(self, 20, now)
   o.energy = 6, -- imps appear to get 6 casts now in shadowlands
   setmetatable(o, self)
   return o
end

function wildimp:cast()
   self.energy = self.energy - 1
end

function wildimp:update(now)
   
   wildimp.__super.update(self, now)
   
   self.active = (self.remaining > 0) and (self.energy > 0)
   
end


----------------- pet list ------------------
local petlist = extends(prototype.data)

function petlist:new()
   local o = petlist.__super.new(
      self,
      {
	 count = 0,
	 pets = {},
	 duration = 0,
	 endtime = 0,
	 remaining = 0,
	 active = false,
      }
   )
   setmetatable(o, self)
   return o
end

function petlist:add(guid, pet)
   self.pets[guid] = pet
end

function petlist:contains(guid)
   return self.pets[guid] ~= nil
end

function petlist:get(guid)
   return self.pets[guid]
end

function petlist:extend(amount)
   for _,pet in pairs(self.pets) do
      pet:extend(amount)
   end
end

function petlist:clear()
   -- Remove all pets
   for guid,_ in pairs(self.pets) do
      self.pets[guid] = nil
   end
end

function petlist:update(now)

   petlist.__super.update(self, now)
   
   self.count = 0
   self.duration = 0
   self.endtime = 0
   for guid,pet in pairs(self.pets) do
      
      pet:update(now)
      if (pet.active) then
	 
	 self.count = self.count + 1

	 if (pet.duration > self.duration) then
	    self.duration = pet.duration
	 end

	 if (pet.endtime > self.endtime) then
	    self.endtime = pet.endtime
	 end
	 
      else
	 self.pets[guid] = nil
      end
      
   end
   self.remaining = self.endtime - now

   self.active = self.count > 0
   
end

function display(now)
   return self.endtime - now
end


----------------- allpets ------------------
local allpets = prototype.datalist:new(
   {
      demonictyrant    = petlist:new(),
      dreadstalkers    = petlist:new(),
      grimoirefelguard = petlist:new(),
      vilefiend        = petlist:new(),
      wildimps         = petlist:new(),
   }
)

function allpets:tyrantextension()

   local amount = 15

   self.dreadstalkers:extend(amount)
   self.grimoirefelguard:extend(amount)
   self.vilefiend:extend(amount)
   self.wildimps:extend(amount)
   
end

function allpets:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)

   local now = GetTime()
   --print(string.format("allpets cleu: %s %d %s", subevent, spellID, spellName))

   -- TODO: deal with power siphon
   
   -- pet summoned
   -- use spell names, since some ids for spell summon don't match the spellid cast by the player
   if ((subevent == "SPELL_SUMMON") and
	 (sourceGUID == common.player.guid)
   ) then

      --print(string.format("summon pet: %s", spellName))
      
      if (spellName == "Summon Demonic Tyrant") then

	 self.demonictyrant:add(destGUID, demonictyrant:new(now))
	 self:tyrantextension()
	 
      elseif (spellName == "Call Dreadstalkers") then
	 self.dreadstalkers:add(destGUID, dreadstalker:new(now))
      elseif (spellName == "Grimoire: Felguard") then
	 self.grimoirefelguard:add(destGUID, grimoirefelguard:new(now))
      elseif (spellName == "Summon Vilefiend") then
	 self.vilefiend:add(destGUID, vilefiend:new(now))
      elseif (spellName == "Wild Imp") then
	 self.wildimps:add(destGUID, wildimp:new(now))
      end
      
   elseif (subevent == "SPELL_CAST_SUCCESS") then
      
      if (self.wildimps:contains(sourceGUID) and
	     (spellID == skill_enum.FEL_FIREBOLT)
      ) then
	 -- Imp casts a fel firebolt. Check if the imp belongs to the player

	 -- imp energy doesn't decrement while tyrant is active
	 if (not self.demonictyrant.active) then
	    local imp = self.wildimps:get(sourceGUID)
	    imp:cast()
	 end

      elseif ((sourceGUID == common.player.guid) and
	    (spellID == skill_enum.IMPLOSION)
      ) then
	 -- remove all imps on implosion
	 self.wildimps:clear()
      end        
      
   end

end


----------------- hand of gul'dan ------------------
local handofguldan = extends(prototype.skill)

function handofguldan:new()
   local o = handofguldan.__super.new(self, skill_enum.HAND_OF_GULDAN)
   o.units = {}
   o.castGUID = ""
   o.enemies = 1
   o.timeout = 30 -- s
   setmetatable(o, self)
   return o
end

function handofguldan:flush(now)
   
   for unitGUID,unit in pairs(self.units) do
      
      -- remove any splash units that haven't been hit in a while
      for splashGUID,timestamp in pairs(unit) do
	 if (now - timestamp > self.timeout) then
	    unit[splashGUID] = nil
	 end
      end
      
      -- remove empty units
      if (next(unit) == nil) then
	 self.units[unitGUID] = nil
      end
      
   end
   
end

function handofguldan:countnearby(targetGUID)

   local count = 1
   
   local target = self.units[targetGUID]
   if (type(target) == "table") then
      for k,v in pairs(target) do
	 count = count + 1
      end
   end

   return count
   
end

function handofguldan:update(now)
   
   handofguldan.__super.update(self, now)

   self:flush(now)
   self.enemies = 0
   if (UnitExists("target")) then
      self.enemies = self:countnearby(UnitGUID("target"))
   end
   
end

function handofguldan:cast(destGUID, now)

   --print(string.format("cast on %s", destGUID))

   --[[
   -- clear table to purge splash units that may have moved away
   self.units[destGUID] = self.units[destGUID] or {}
   local target = self.units[destGUID]
   for guid,_ in pairs(target) do
      target[guid] = nil
   end
   --]]
   
   self.castGUID = destGUID
   
end

function handofguldan:splash(destGUID, now)

   --print(string.format("splash on %s", destGUID))

   -- ignore self splash on target
   if (destGUID ~= self.castGUID) then
      
      -- add splashed unit to target's list
      self.units[self.castGUID] = self.units[self.castGUID] or {}
      local target = self.units[self.castGUID]
      target[destGUID] = now

      -- also add cast target to splashed unit's list
      self.units[destGUID] = self.units[destGUID] or {}
      local splash = self.units[destGUID]
      splash[self.castGUID] = now
      
   end
   
end

function handofguldan:unitdied(destGUID)

   -- delete destGUID's list if it exists
   self.units[destGUID] = nil

   -- remove destGUID from other lists
   for _,unit in pairs(self.units) do

      if (type(unit) == "table") then
	 unit[destGUID] = nil
      end
      
   end
   
end

function handofguldan:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)

   local now = GetTime()
   --print(string.format("hand of gul'dan cleu: %s %d %s", subevent, spellID, spellName))

   if ((subevent == "SPELL_CAST_SUCCESS") and
	 (sourceGUID == common.player.guid) and
	 (spellID == skill_enum.HAND_OF_GULDAN)
   ) then

      -- log handofguldan cast on destGUID
      self:cast(destGUID, now)

   elseif ((subevent == "SPELL_DAMAGE") and
	 (sourceGUID == common.player.guid) and
	 (spellID == skill_enum.HAND_OF_GULDAN_SPLASH)
   )then
      
      -- add splash guids to last hog cast target
      self:splash(destGUID, now)
      
   elseif (subevent == "UNIT_DIED") then
      
      -- delete destguid from all lists
      self:unitdied(destGUID)
      
   end
   
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
      handofguldan        = handofguldan:new(), --prototype.skill:new(skill_enum.HAND_OF_GULDAN),
      implosion           = prototype.skill:new(skill_enum.IMPLOSION),
      netherportal        = prototype.skill:new(skill_enum.NETHER_PORTAL),
      powersiphon         = prototype.skill:new(skill_enum.POWER_SIPHON),
      shadowbolt          = prototype.skill:new(warlock.skill_enum.SHADOW_BOLT),
      soulrot             = prototype.skill:new(warlock.skill_enum.SOUL_ROT),
      soulstrike          = prototype.skill:new(skill_enum.SOUL_STRIKE),
      summondemonictyrant = prototype.skill:new(skill_enum.SUMMON_DEMONIC_TYRANT),
      summonfelguard      = prototype.skill:new(skill_enum.SUMMON_FELGUARD),
      summonvilefiend     = prototype.skill:new(skill_enum.SUMMON_VILEFIEND),
   }
)


----------------- tyrant setup ------------------
local tyrantsetup = prototype.data:new(
   {
      calldreadstalkers   = false,
      grimoirefelguard    = false,
      netherportal        = false,
      soulrot             = false,
      summondemonictyrant = false,
      summonvilefiend     = false,
   }
)

function tyrantsetup:update(now)

   -- TODO: clean this up

   
   -- ideally setup goes like this @ 20% haste
   -- tyrant cd    cast          shards before    shards after
   -- 16.0         soul rot       5                5
   -- 14.8         grimoire       5                4
   -- 13.6         vilefiend      4                4
   -- 11.9         shadowbolt     3                4
   -- 10.2         shadowbolt     4                5
   --  8.5         dreadstalkers  5                3
   --  7.3         shadowbolt     3                4
   --  5.6         shadowbolt     4                5
   --  3.9         hand           5                2
   --  2.7         shadowbolt     2                3
   --  1.0         hand           3                0
   --  0.0         tyrant         0                0

   local boltcast = common.player:casttime(2.0)
   local handcast = common.player:casttime(1.5)

   -- 3 bolts + 2 hand + tyrant = 9.2
   self.calldreadstalkers = skills.calldreadstalkers.usable and
      (skills.summondemonictyrant.cd < 8) -- 12-(tyrant+sb) = 12-(2+2)

   -- 
   self.grimoirefelguard = skills.grimoirefelguard.usable and
      (skills.summondemonictyrant.cd < 13) and -- 17-(tyrant+sb) = 17-(2+2)
      (
	 (skills.calldreadstalkers.cd < 11) or -- 17-(tyrant+vf+sb) = 17-(2+2+2)
	    (allpets.dreadstalkers.remaining > skills.summondemonictyrant.cd + 2) -- add cast time
      )

   self.netherportal = skills.netherportal.usable and
      (skills.summondemonictyrant.cd < 15)

   self.soulrot = skills.soulrot.usable and
      (skills.summondemonictyrant.cd < 14) and -- 18 - (tyrant+gf+vf+sb) = 18-(2+2+2)
      (
	 (skills.calldreadstalkers.cd < 13) or -- 18 - (tyrant+gf+vf+sb+sr) = 18-(1+2+2+2)
	    (allpets.dreadstalkers.remaining > skills.summondemonictyrant.cd + 2) -- add cast time
      )
   
   -- replacing this with a warning to start pooling shards so tthat we're capped
   -- right in time to cast soul rot to be able to summon tyrant on cd
   self.summondemonictyrant = skills.summondemonictyrant.cd < 14 + soulshard.deficit * boltcast

   --[[
   self.summondemonictyrant = skills.summondemonictyrant.usable and
      (
	 -- summon tyrant when dreadstalkers and vilefiend (if talented) are up
	 allpets.dreadstalkers.active and (allpets.dreadstalkers.remaining > 2) and
	    (
	       (not talents.summonvilefiend.selected) or
		  (allpets.vilefiend.active)
	    ) and
	    (
	       (soulshard.current == 0) or
		  (
		     allpets.dreadstalkers.active and
			(allpets.dreadstalkers.remaining < 4) -- tyrant+sb = 2+2
		  ) or
		  (
		     allpets.vilefiend.active and
			(allpets.vilefiend.remaining < 4) -- tyrant+sb = 2+2
		  ) or
		  (
		     allpets.grimoirefelguard.active and
			(allpets.grimoirefelguard.remaining < 4) -- tyrant+sb = 2+2
		  )
	    )
      )
   --]]
   
   self.summonvilefiend = skills.summonvilefiend.usable and
      (
	 (skills.summondemonictyrant.cd < 13) and -- 15-tyrant = 15-2
	    (
	       (skills.calldreadstalkers.cd < 11) or -- 15-(tyrant+vf) = 15-(2+2)
		  (allpets.dreadstalkers.remaining > skills.summondemonictyrant.cd + 2) -- add cast time
	    )
      )

end


----------------- player buffs ------------------
local player_buffs = prototype.datalist:new(
   {
      demoniccore = prototype.buff:new("player", buff_enum.DEMONIC_CORE),
      demonicpower = prototype.buff:new("player", buff_enum.DEMONIC_POWER),
      netherportal = prototype.buff:new("player", buff_enum.NETHER_PORTAL),
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
	 allpets = allpets,
	 skills = skills,
	 tyrantsetup = tyrantsetup,
	 player_buffs = player_buffs,
	 target_debuffs = target_debuffs,
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
   self:register(self.allpets, "COMBAT_LOG_EVENT_UNFILTERED", self.allpets.cleu)
   self:register(self.skills.handofguldan, "COMBAT_LOG_EVENT_UNFILTERED", self.skills.handofguldan.cleu)
end

function demonology:update(now)

   --print(string.format("demonology update: %f", now))
   demonology.__super.update(self, now)

   local gcd = common.gcd.current
   local allpets = self.allpets

   -- assume always wearing wilfreds for now
   local wilfreds = true
   
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   --local enemies = common.enemies.target.near10
   local enemies = skills.handofguldan.enemies

   if (InCombatLockdown()) then
      if (skills.doom.usable and
	     target_debuffs.doom.pandemic.active
      ) then
	 skill = skill_enum.DOOM

	 -- elseif cast soul rot on cd if using niya or dreamweaver


      elseif (skills.summonvilefiend.usable and
		 (
		    (not wilfreds) and
		       (skills.summondemonictyrant.cd > 40)
		 )
      ) then
	 skill = skill_enum.SUMMON_VILEFIEND
      elseif (skills.calldreadstalkers.usable and
		 (skills.summondemonictyrant.cd < 8) -- 12-(tyrant+sb) = 12-(2+2)
      ) then
	 skill = skill_enum.CALL_DREADSTALKERS
      elseif (skills.demonicstrength.usable and
		 (
		    (
		       (not wilfreds) and
			  (skills.summondemonictyrant.cd > 9)
		    ) or
		       (
			  allpets.demonictyrant.active and
			     (allpets.demonictyrant.remaining < 6 * common.gcd.max)
		       )
		 )
      ) then
	 skill = skill_enum.DEMONIC_STRENGTH
      elseif (skills.calldreadstalkers.usable and
		 (skills.summondemonictyrant.cd > 20)
      ) then
	 skill = skill_enum.CALL_DREADSTALKERS
      elseif (skills.bilescourgebombers.usable and
		 (
		    -- don't cast bombers while tyrant is out or during setup for tyrant
		    -- maybe doesn't benefit from tyrant dmg buff or increase tyrant dmg?
		    (not player_buffs.demonicpower.active) and
		       (skills.summondemonictyrant.cd > 5)
		 )
      ) then
	 skill = skill_enum.BILESCOURGE_BOMBERS
      elseif (skills.implosion.usable and
		 (
		    (
		       -- don't implode imps while tyrant is out or during setup for tyrant
		       (not player_buffs.demonicpower.active) and
			  (skills.summondemonictyrant.cd > 5)
		    ) and
		       (
			  (
			     (
				-- without sacrificed souls, implode with more than one target
				(not talents.sacrificedsouls.selected) and
				   (enemies > 1)
			     ) or
				(
				   -- with sacrificed souls, save imps a bit for shadowbolt and demon bolt dmg
				   talents.sacrificedsouls.selected and
				      (enemies > 2)
				)
			  ) and
			     (allpets.wildimps.count >= 6)
		       )
		 )
	      -- apl has other conditions for implosive potential, but seems redundant?
      ) then
	 skill = skill_enum.IMPLOSION
      elseif (skills.handofguldan.usable and
		 (
		    -- pool 5 shards, so we can call dreadstalkers on cd
		    soulshard.capped or
		       (
			  -- if dreadstalkers are up, no need to save shards
			  (soulshard.current >= 3) and
			     (
				allpets.dreadstalkers.active or
				   allpets.demonictyrant.active
			     )
		       ) or
		       (
			  -- dump shards on hand if we can't cast dreadstalkers and
			  -- nether portal is active, more 1 shard hand casts are better
			  (soulshard.current >= 1) and
			     (
				player_buffs.netherportal.active and
				   (skills.calldreadstalkers.cd > 2 * common.gcd.max)
			     )
		       )
		    -- this doesn't work well if we're holding tyrant
		    --[[
		       or
		       (
			  -- squeeze out any imps we can right before tyrant
			  --(skills.summondemonictyrant.cd < common.gcd.max)
		       )
		    --]]
		 )
      ) then
	 skill = skill_enum.HAND_OF_GULDAN
      elseif (skills.soulstrike.usable and
		 -- without sacrificed souls buffing demonbolt, soulstrike does more damage
		 (not talents.sacrificedsouls.selected)
      ) then
	 skill = skill_enum.SOUL_STRIKE
      elseif (skills.demonbolt.usable and
		 (
		    (
		       -- only use procs and don't waste shards
		       (soulshard.deficit >= 2) and
			  (player_buffs.demoniccore.active)
		    ) and
		       (
			  -- the last 3 conditions only matter for a random 8 second window
			  -- maybe just use these procs as they occur?
			  (skills.summondemonictyrant.cd > 20) or
			     (skills.summondemonictyrant.cd < 12) or
			     (player_buffs.demoniccore.count > 2) or
			     talents.sacrificedsouls.selected or
			     (enemies > 1)
		       )
		 )
      ) then
	 skill = skill_enum.DEMONBOLT
      elseif (skills.soulstrike.usable) then
	 skill = skill_enum.SOUL_STRIKE
      elseif (skills.handofguldan.usable and
		 (
		    -- if we can get back to 5 shards before dreakstalkers is back up
		    (soulshard.current >= 3) and
		       (skills.summondemonictyrant.cd > 25) and
		       (
			  talents.demoniccalling.selected or
			     skills.calldreadstalkers.cd > soulshard.deficit * 2 -- time to cap shards with shadowbolt
		       )
		 )
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
