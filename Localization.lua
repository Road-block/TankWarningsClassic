local addonName, twc = ...

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

twc.L = L
_G[addonName.."_L"] = L
local LOCALE = GetLocale()

if LOCALE == "enUS" then
	-- The EU English game client also
	-- uses the US English locale code.
return end

-- German translations
if LOCALE == "deDE" then
	-- Ability translations need to fit the game's descriptions 1:1
	
	--Warrior
	L["Last Stand"] = "Letztes Gefecht"
	L["Shield Wall"] = "Schildwall"
	L["Challenging Shout"] = "Herausforderungsruf"
	L["Taunt"] = "Spott"
	L["Mocking Blow"] = "Spöttischer Schlag"
	
	--Druid
	L["Challenging Roar"] = "Herausforderndes Gebrüll"
	L["Growl"] = "Knurren"
	
	-- Free text for messages
	L["%s activated!"] = "%s aktiviert!"
	L["%s will expire in 3 seconds!"] = "%s wird in 3 Sekunden auslaufen!"
	L["%s resisted!"] = "%s widerstanden!"
return end

-- Russian translations (thanks Hubbotu!)
if LOCALE == "ruRU" then
L["%s activated!"] = "%s активированный!"
L["%s resisted!"] = "%s сопротивление!"
L["%s will expire in 3 seconds!"] = "%s истекает через 3 секунды!"
L["Challenging Roar"] = "Вызывающий рев"
L["Challenging Shout"] = "Вызывающий крик"
L["Growl"] = "Рык"
L["Last Stand"] = "Ни шагу назад"
L["Mocking Blow"] = "Дразнящий удар"
L["Shield Wall"] = "Глухая оборона"
L["Taunt"] = "Провокация"
return end