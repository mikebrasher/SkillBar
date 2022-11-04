----------------------- frame --------------------------
local frame = CreateFrame("Frame")


----------------------- callbacks --------------------------
local callback = {}
callback.__index = callback

function callback:match(func, spec)
   return ((self.id == tostring(func)) and (self.spec == spec))
end

function callback:new(obj, func, spec)
   local o =
      {
	 id = tostring(obj) .. tostring(func), -- multiple objects may use the same function
	 obj = obj,
	 func = func,
	 spec = spec,
	 active = spec == nil -- default on for common, off for spec
      }
   setmetatable(o, self)
   return o
end


----------------------- dispatch --------------------------
local dispatch =
   {
      event = "nil" ,
   }
dispatch.__index = dispatch

function dispatch:new(event)
   local o =
      {
	 event = event,
	 callbacks = {}, -- define here so dispatches have separate callback lists
      }
   setmetatable(o, self)
   return o
end

function dispatch:register(obj, func, spec)
   local cb = callback:new(obj, func, spec)
   self.callbacks[cb.id] = cb
end

function dispatch:unregister(func, spec)
   for id,cb in pairs(self.callbacks) do
      if (cb:match(func, spec)) then
	 self.callbacks[id] = nil
      end
   end
end

function dispatch:activate(spec)
   --print(string.format("dispatch:activate(%s)", spec))
   for id,cb in pairs(self.callbacks) do
      if (cb.spec == spec) then
	 cb.active = true
      end
   end
end

function dispatch:deactivate(spec)
   --print(string.format("dispatch:deactivate(%s)", spec))
   for id,cb in pairs(self.callbacks) do
      if (cb.spec == spec) then
	 cb.active = false
      end
   end
end

function dispatch:handler(event, ...)
   for _,cb in pairs(self.callbacks) do
      if (cb.active and cb.func) then
	 --print(string.format("dispatch.handler obj: %s", tostring(cb.obj)))
	 cb.func(cb.obj, event, ...)
      end
   end
end

function dispatch:print()
   print(string.format("dispatch[%s]:", self.event))
   for id,cb in pairs(self.callbacks) do
      print(string.format("  cb id: %s active: %s", id, tostring(cb.active)))
   end
end


----------------------- cleu --------------------------
local cleu = dispatch:new("COMBAT_LOG_EVENT_UNFILTERED")

function cleu:handler(event)
   dispatch.handler(self, event, CombatLogGetCurrentEventInfo())
end


----------------------- onevent --------------------------
local onevent =
   {
      dispatch = {},
      registered = {},
   }

function onevent:create(event, register, disp)
   self.dispatch[event] = disp or dispatch:new(event)
   if (register) then
      self.registered[event] = frame:RegisterEvent(event)
   end
end

-- WoW events to be registered
onevent:create("COMBAT_LOG_EVENT_UNFILTERED", true, cleu)
onevent:create("PLAYER_TALENT_UPDATE", true)
onevent:create("PLAYER_REGEN_DISABLED", true)
onevent:create("PLAYER_LOGIN", true)
onevent:create("PLAYER_SPECIALIZATION_CHANGED", true)
onevent:create("TRAIT_CONFIG_UPDATED", true)

-- custom events
onevent:create("INTERNAL_UPDATE")

function onevent:register(obj, event, func, spec)
   --print(string.format("register: %s %s %s", event, tostring(func), tostring(spec)))
   local dispatch = self.dispatch[event]
   if (dispatch) then
      dispatch:register(obj, func, spec)
   else
      print("error: unknown event")
   end
end

function onevent:activate(spec)
   for e,d in pairs(self.dispatch) do
      d:activate(spec)
   end
end

function onevent:deactivate(spec)
   for e,d in pairs(self.dispatch) do
      d:deactivate(spec)
   end
end

function onevent:handler(event, ...)
   
   --if ((event ~= "COMBAT_LOG_EVENT_UNFILTERED") and
   --	 (event ~= "INTERNAL_UPDATE"))
   --then
   --   print(string.format("event: %s", event))
   --end
   
   local dispatch = self.dispatch[event]
   if (dispatch) then
      
      --if ((event ~= "COMBAT_LOG_EVENT_UNFILTERED") and
      --   (event ~= "INTERNAL_UPDATE"))
      --then
      --	 for _,cb in pairs(dispatch.callbacks) do
      --	    print(string.format("%s: obj = %s, func = %s, spec = %s, active = %s", cb.id, tostring(cb.obj), tostring(cb.func), tostring(cb.spec), tostring(cb.active)))
      --	 end
      --end
      
      dispatch:handler(event, ...)
      
   end
   
end


function onevent:print(event)
   local dispatch = self.dispatch[event]
   if (dispatch) then
      dispatch:print()
   end
end

function onevent:printall()
   for e,d in pairs(self.dispatch) do
      d:print()
   end
end

frame:SetScript("OnEvent",
		function(self, event, ...)
		   onevent:handler(event, ...)
		end
)


----------------------- event --------------------------
local event = {}

-- registered events are default inactive for specs
-- and active if spec is not supplied
function event:register(obj, event, func, spec)
   --print(string.format("event:register(%s, %s, %s, %s)", tostring(obj), tostring(event), tostring(func), tostring(spec)))
   onevent:register(obj, event, func, spec)
end

function event:activate(spec)
   onevent:activate(spec)
end

function event:deactivate(spec)
   onevent:deactivate(spec)
end

function event:fire(event, ...)
   onevent:handler(event, ...)
end

function event:print(event)
   onevent:print(event)
end

function event:printall()
   onevent:printall()
end

----------------------- onupdate --------------------------
local onupdate =
   {
      interval = 0.1,
      elapsed = 0,
   }

function onupdate:handler(elapsed)
   self.elapsed = self.elapsed + elapsed
   while (self.elapsed > self.interval) do
      event:fire("INTERNAL_UPDATE", GetTime())
      self.elapsed = self.elapsed - self.interval
   end
end

frame:SetScript("OnUpdate",
		function(self, event, ...)
		   onupdate:handler(event, ...)
		end
)


----------------------- SkillBar --------------------------
SkillBar.event = event
