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
      SUBTERFUGE = 115192,
      
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
      subterfuge = prototype.talent:new(2, 2),
   }
)


----------------- skills ------------------
local skills = prototype.datalist:new(
   {
      ambush       = prototype.skill:new(rogue.skill_enum.AMBUSH),
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
      sliceanddice = prototype.pandemicbuff:new("player", buff_enum.SLICE_AND_DICE, rogue.skill_enum.SLICE_AND_DICE),
      subterfuge   = prototype.buff:new("player", buff_enum.SUBTERFUGE),
   }
)


----------------- garrote ------------------
local garrote = extends(prototype.pandemicbuff)

function garrote:new()
   local o = garrote.__super.new(self, "target", buff_enum.GARROTE, skill_enum.GARROTE)
   o.subterfuge = false
   o.database = {}
   setmetatable(o, self)
   return o
end

function garrote:clear(guid)
   self.database[guid] = nil
end
    
function garrote:record(guid, timestamp)

   --print(string.format("garrote: %f", timestamp))
   self.database[guid] = self.database[guid] or {}
   
   local entry = self.database[guid]
   entry.subterfuge = IsStealthed() or player_buffs.subterfuge.active
   entry.timestamp = timestamp
   
end
    
function garrote:update(now)
        
   garrote.__super.update(self, now)

   if (not talents.subterfuge.selected) then
      return
   end
   
   if (UnitExists("target")) then
      
      local targetGUID = UnitGUID("target")
      local entry = self.database[targetGUID]
      if (entry) then
	 self.subterfuge = entry.subterfuge
      end
      
   end

   self.subterfuge = self.subterfuge and self.active
   
end

function garrote:cleu(event, timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName)
   
   if ((sourceGUID == common.player.guid) and
      (spellID == buff_enum.GARROTE)) then
      
      if (subevent == "SPELL_AURA_APPLIED") then
	 --print("garrote applied")
	 self:record(destGUID, timestamp)
      elseif (subevent == "SPELL_AURA_REFRESH") then
	 --print("garrote refresh")
	 self:record(destGUID, timestamp)
      elseif (subevent == "SPELL_AURA_REMOVED") then
	 --print("garrote removed")
	 self:clear(destGUID)
      end
      
   elseif (subevent == "UNIT_DIED") then
      
      --print("garrote unit died")
      self:clear(destGUID)
      
   end
   
end


----------------- target debuffs ------------------
local target_debuffs = prototype.datalist:new(
   {
      -- normal
      --haunt                = prototype.buff:new("target", buff_enum.HAUNT),
      -- pandemic
      garrote = garrote:new(),
      rupture = prototype.pandemicbuff:new("target", buff_enum.RUPTURE, skill_enum.RUPTURE),
   }
)


----------------- assassination ------------------
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
   
   self:register(self.target_debuffs.garrote, "COMBAT_LOG_EVENT_UNFILTERED", self.target_debuffs.garrote.cleu)
   
end

function assassination:update(now)

   assassination.__super.update(self, now)
   
   local gcd = common.gcd.current
    
   ----- skill priority -----
   local skill = skill_enum.NIL
   
   if (InCombatLockdown()) then
      if (skills.sliceanddice.usable and
	     (
		(player_buffs.sliceanddice.pandemic.active) and
		   (rogue.combopoints.deficit <= 1)
	     )
      ) then
	 skill = rogue.skill_enum.SLICE_AND_DICE
      elseif (skills.rupture.usable and
		 (
		    target_debuffs.rupture.pandemic.active and
		       (rogue.combopoints.deficit <= 1)
		 )
      ) then
	 skill = skill_enum.RUPTURE
      elseif (skills.garrote.usable and
		 (
		    (
		       target_debuffs.garrote.pandemic.active and
			  (
			     -- don't override empowered garrote with unempowered
			     (not target_debuffs.garrote.subterfuge) or
				-- new garrote will be empowered
				(player_buffs.subterfuge.active)
			  )
		    ) and
		       (not rogue.combopoints.capped)
	     )
      ) then
	 skill = skill_enum.GARROTE
      elseif (skills.shiv.usable and
		 (not rogue.combopoints.capped)
      ) then
	 skill = rogue.skill_enum.SHIV
      elseif (skills.envenom.usable and
		 (rogue.combopoints.deficit <= 1)
      ) then
	 skill = skill_enum.ENVENOM
      elseif (skills.fanofknives.usable and
		 (
		    (common.enemies.melee >= 4) and
		       (not rogue.combopoints.capped)
		 )
	      
      ) then
	 skill = skill_enum.FAN_OF_KNIVES
      elseif (skills.ambush.usable and
		 (not rogue.combopoints.capped)
      ) then
	 skill = rogue.skill_enum.AMBUSH
      elseif (skills.mutilate.usable and
		 (not rogue.combopoints.capped)
      ) then
	 skill = skill_enum.MUTILATE
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
