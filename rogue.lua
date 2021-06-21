local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      -- common skills
      NIL = 0,
      AMBUSH = 8676,
      BLIND = 2094,
      CHEAP_SHOT = 1833,
      CRIMSON_VIAL = 185311,
      DISTRACT = 1725,
      EVASION = 5277,
      FEINT = 1966,
      KICK = 1766,
      KIDNEY_SHOT = 408,
      PICK_LOCK = 1804,
      PICK_POCKET = 921,
      DEADLY_POISON = 315584,
      CRIPPLING_POISON = 3408,
      WOUND_POISON = 8679,
      SAP = 6770,
      SHIV = 5938,
      SLICE_AND_DICE = 315496,
      SPRINT = 2983,
      STEALTH = 1784,
      VANISH = 1856,

      -- covenant
      DOOR_OF_SHADOWS = 300728, -- move to something non class dependant

      FLAGELLATION = 323654,
   }


----------------------- energy --------------------------
local energy = prototype.power:new(Enum.PowerType.Energy)


----------------- combopoints ------------------
local combopoints = prototype.power:new(Enum.PowerType.ComboPoints)


----------------------- warlock --------------------------
local name = "rogue"

local specs = 
   {
      "assassination",
      "outlaw",
      "subtlety",
   }

local rogue = prototype.class:new(
   name,
   specs,
   {
      skill_enum = skill_enum,
      energy = energy,
      combopoints = combopoints,
   }
)

-- manually load/update here to avoid loading/updating specs once they've been inserted
function rogue:load()
   --print("rogue load")
   rogue.__super.load(self)
   self.energy:load()
   self.combopoints:load()
end

function rogue:update(now)
   --print(string.format("rogue update: %f", now))
   rogue.__super.update(self, now)
   self.energy:update(now)
   self.combopoints:update(now)
end


----------------------- Skill Bar --------------------------
SkillBar.rogue = rogue
