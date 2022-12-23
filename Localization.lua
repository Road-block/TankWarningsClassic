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

return end

-- Simplified Chinese translations (thanks wellcat!)
if LOCALE == "zhCN" then
	L["%s activated!"] = "%s 已使用!"
	L["%s resisted!"] = "%s 被抵抗了!"
	L["%s will expire in 3 seconds!"] = "%s 将在3秒内过期！"
return end
