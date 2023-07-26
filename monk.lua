local event = SkillBar.event
local prototype = SkillBar.prototype
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      -- common skills
      NIL = 0,
      -- BLACKOUT_KICK = 100784, not brewmaster version
      CRACKLING_JADE_LIGHTNING = 117952,
      DETOX = 115450,
      EXPEL_HARM = 115072,
      FORTIFYING_BREW = 115203,
      LEG_SWEEP = 119381,
      PARALYSIS = 115078,
      PROVOKE = 115546,
      RESUSCITATE = 115178,
      RISING_SUN_KICK = 107428,
      ROLL = 109132,
      SPEAR_HAND_STRIKE = 116705,
      SPINNING_CRANE_KICK = 101546,
      TIGER_PALM = 100780,
      TOUCH_OF_DEATH = 115080,
      TRANSCENDENCE = 101643,
      TRANSCENDENCE_TRANSFER = 119996,
      VIVIFY = 116670,
      ZEN_FLIGHT = 125883,
      ZEN_PILGRIMAGE = 126892,

      -- common talents
      CHI_WAVE = 115098,
      CHI_BURST = 123986,
      CHI_TORPEDO = 115008,
      TIGERS_LUST = 116841,
      RING_OF_PEACE = 116844,
      HEALING_ELIXIR = 122280,
      DIFFUSE_MAGIC = 122783,
      DAMPEN_HARM = 122278,
      RUSHING_JADE_WIND = 116847,

      -- covenant
      DOOR_OF_SHADOWS = 300728, -- move to something non class dependant

      WEAPONS_OF_ORDER = 310454,
      FALLEN_ORDER = 326860,
      BONEDUST_BREW = 325216,
      FAELINE_STOMP = 327104,
   }


----------------------- mana --------------------------
local mana = prototype.power:new(Enum.PowerType.Mana)


----------------------- energy --------------------------
local energy = prototype.power:new(Enum.PowerType.Energy)


----------------------- monk --------------------------
local name = "monk"

local specs = 
   {
      "brewmaster",
      "windwalker",
      "mistweaver",
   }

local monk = prototype.class:new(
   name,
   specs,
   {
      skill_enum = skill_enum,
      mana = mana,
      energy = energy,
   }
)

-- manually load/update here to avoid loading/updating specs once they've been inserted
function monk:load()
   --print("monk load")
   monk.__super.load(self)
   mana:load()
   energy:load()
end

function monk:update(now)
   --print(string.format("monk update: %f", now))
   monk.__super.update(self, now)
   mana:update(now)
   energy:update(now)
end


----------------------- Skill Bar --------------------------
SkillBar.monk = monk
