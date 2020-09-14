local data = SkillBar.data
local event = SkillBar.event
local common = SkillBar.common


----------------------- skill_enum --------------------------
local skill_enum =
   {
      NIL = 0,
      BURNING_RUSH = 111400,
      CORRUPTION = 172,      
      CURSE_OF_EXHAUSTION = 334275,
      CURSE_OF_TONGUES = 1714,
      CURSE_OF_WEAKNESS = 702,
      DARK_PACT = 108416,
      DEMONIC_CIRCLE = 48018,
      DEMONIC_CIRCLE_TELEPORT = 48020,
      DRAIN_LIFE = 234153,
      FEAR = 5782,
      FEL_DOMINATION = 333889,
      HEALTH_FUNNEL = 755,
      HOWL_OF_TERROR = 5484,
      IMMOLATE = 348,
      INCINERATE = 29722,
      GRIMOIRE_OF_SACRIFICE = 108503,
      MORTAL_COIL = 6789,
      SEDUCTION = 119909,
      SHADOW_BULWARK = 119907,
      SHADOWFURY = 30283,
      SINGE_MAGIC = 119905,
      SPELL_LOCK = 119910,
      SUMMON_FELHUNTER = 691,
      SUMMON_IMP = 688,
      SUMMON_SUCCUBUS = 712,
      SUMMON_VOIDWALKER = 697,
      UNENDING_RESOLVE = 104773,

      -- covenant
      IMPENDING_CATASTROPHE = 322170,

      -- spec dependent or fake versions?
      --SCOURING_TITHE = 312321,
      --IMPENDING_CATASTROPHE = 321792,
      --DECIMATING_BOLT = 325289,
      --SOUL_ROT = 325640,
   }


----------------------- mana --------------------------
local mana = common.power:new(Enum.PowerType.Mana)


----------------------- warlock --------------------------
local warlock = data:new(
   "warlock",
   {
      specs =
	 {
	    "affliction",
	    "demonology",
	    "destruction",
	 },
      skill_enum = skill_enum,
      mana = mana,
   }
)

function warlock:update(now)
   mana:update()
end


----------------------- Skill Bar --------------------------
SkillBar.warlock = warlock
