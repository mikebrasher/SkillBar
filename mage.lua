local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      -- common skills
      NIL = 0,
      ARCANE_EXPLOSION = 1449,
      ARCANE_INTELLECT = 1459,
      BLINK = 1953,
      CONJURE_REFRESHMENT = 42955,
      COUNTERSPELL = 2139,
      FIRE_BLAST = 108853,
      FROST_NOVA = 65792,
      FROSTBOLT = 116,
      ICE_BLOCK = 45438,
      INVISIBILITY = 66,
      MIRROR_IMAGE = 55342,
      POLYMORPH = 118,
      REMOVE_CURSE = 475,
      SLOW_FALL = 130,
      SPELLSTEAL = 30449,
      TIME_WARP = 80353,

      -- common talents
      SHIMMER = 191738,
      FOCUS_MAGIC = 321358,
      RUNE_OF_POWER = 116011,
      RING_OF_FROST = 113724,

      -- covenant
      DOOR_OF_SHADOWS = 300728, -- move to something non class dependant

      RADIANT_SPARK = 307443,
      MIRRORS_OF_TORMENT = 314793,
      DEATHBORNE = 324220,
      SHIFTING_POWER = 314791,
   }


----------------------- mana --------------------------
local mana = prototype.power:new(Enum.PowerType.Mana)


----------------------- mage --------------------------
local name = "mage"

local specs = 
   {
      "arcane",
      "fire",
      "frost",
   }

local mage = prototype.class:new(
   name,
   specs,
   {
      skill_enum = skill_enum,
      mana = mana,
   }
)

-- manually load/update here to avoid loading/updating specs once they've been inserted
function mage:load()
   --print("mage load")
   mage.__super.load(self)
   mana:load()
end

function mage:update(now)
   --print(string.format("mage update: %f", now))
   mage.__super.update(self, now)
   mana:update(now)
end


----------------------- Skill Bar --------------------------
SkillBar.mage = mage
