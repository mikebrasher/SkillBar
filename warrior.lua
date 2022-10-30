local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      -- common skills
      NIL = 0,
      BATTLE_SHOUT = 6673,
      BATTLE_STANCE = 386164,
      BERSERKER_STANCE = 386196,
      BITTER_IMMUNITY = 383762,
      CHARGE = 100,
      DEFENSIVE_STANCE = 386208,
      EXECUTE = 163201, -- arms/prot
      HAMSTRING = 1715,
      HEROIC_LEAP = 6544,
      HEROIC_THROW = 57755,
      IMPENDING_VICTORY = 202168,
      INTERVENE = 3411,
      INTIMIDATING_SHOUT = 5246,
      PUMMEL = 6552,
      RALLYING_CRY = 97462,
      SHIELD_BLOCK = 2565,
      SHIELD_SLAM = 23922,
      SLAM = 1464,
      SPELL_REFLECTION = 23920,
      STORM_BOLT = 107570,
      TAUNT = 355,
      THUNDER_CLAP = 6343,
      TITANIC_THROW = 384090,
      WHIRLWIND = 1680, -- arms/prot
   }


----------------------- rage --------------------------
local rage = prototype.power:new(Enum.PowerType.Rage)


---------------------- warrior ------------------------
local name = "warrior"

local specs = 
   {
      "arms",
      "fury",
      "protection",
   }

local warrior = prototype.class:new(
   name,
   specs,
   {
      skill_enum = skill_enum,
      rage = rage,
   }
)

-- manually load/update here to avoid loading/updating specs once they've been inserted
function warrior:load()
   --print("warrior load")
   warrior.__super.load(self)
   rage:load()
end

function warrior:update(now)
   --print(string.format("warrior update: %f", now))
   warrior.__super.update(self, now)
   rage:update(now)
end


----------------------- Skill Bar --------------------------
SkillBar.warrior = warrior
