local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      -- common skills
      NIL = 0,
      BANISH = 710,
      COMMAND_DEMON = 119898,
      CORRUPTION = 172,
      CREATE_HEALTHSTONE = 6201,
      CREATE_SOULWELL = 29893,
      CURSE_OF_EXHAUSTION = 334275,
      CURSE_OF_TONGUES = 1714,
      CURSE_OF_WEAKNESS = 702,
      DEMONIC_CIRCLE = 48018,
      DEMONIC_CIRCLE_TELEPORT = 48020,
      DEMONIC_GATEWAY = 111771,
      DRAIN_LIFE = 234153,
      EYE_OF_KILROGG = 126,
      FEAR = 5782,
      FEL_DOMINATION = 333889,
      HEALTH_FUNNEL = 755,
      RITUAL_OF_DOOM = 342601,
      SHADOW_BOLT = 686,
      SHADOWFURY = 30283,
      SOULSTONE = 20707,
      SUBJUGATE_DEMON = 1098,
      SUMMON_FELHUNTER = 691,
      SUMMON_IMP = 688,
      SUMMON_SUCCUBUS = 712,
      SUMMON_VOIDWALKER = 697,
      UNENDING_BREATH = 5697,
      UNENDING_RESOLVE = 104773,
      
      -- demon skills
      SEDUCTION = 119909,
      SHADOW_BULWARK = 119907,
      SINGE_MAGIC = 119905,
      SPELL_LOCK = 119910,

      -- common talents
      BURNING_RUSH = 111400,
      DARK_PACT = 108416,
      GRIMOIRE_OF_SACRIFICE = 108503,
      HOWL_OF_TERROR = 5484,
      MORTAL_COIL = 6789,

      -- covenant
      DOOR_OF_SHADOWS = 300728, -- move to something non class dependant

      SCOURING_TITHE = 312321,
      IMPENDING_CATASTROPHE = 321792,
      DECIMATING_BOLT = 325289,
      SOUL_ROT = 325640,
   }


----------------------- mana --------------------------
local mana = prototype.power:new(Enum.PowerType.Mana)


----------------------- warlock --------------------------
local name = "warlock"

local specs = 
   {
      "affliction",
      "demonology",
      "destruction",
   }

local warlock = prototype.class:new(
   name,
   specs,
   {
      skill_enum = skill_enum,
      mana = mana,
   }
)

-- manually load/update here to avoid loading/updating specs once they've been inserted
function warlock:load()
   --print("warlock load")
   warlock.__super.load(self)
   self.mana:load()
end

function warlock:update(now)
   --print(string.format("warlock update: %f", now))
   warlock.__super.update(self, now)
   self.mana:update(now)
end


----------------------- Skill Bar --------------------------
SkillBar.warlock = warlock
