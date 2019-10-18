local addonName, twc = ...
local ver = GetAddOnMetadata(addonName, "Version")
local label = string.format("%s v%s.",addonName, ver)
local L = twc.L
_G[addonName] = twc
------- Config & Setup -------

function twc.OnLoad(self) 
	print("|cffffff00"..label.."|r - Use /tankwarnings or /twc for more options.")
	--load default values if they don't exist
	TankWarningsClassicSV = TankWarningsClassicSV or {
		["firstTime"] = true,
		["showInRaids"] = true,
		["showInParties"] = true,
		["showExpirations"] = true,
		["raidOption"] = "Message",
		["warningFallback"] = "Do nothing",
		["abilities"] = {
			[L["Last Stand"]] = true,
			[L["Shield Wall"]] = true,
			[L["Challenging Shout"]] = true,
			[L["Taunt"]] = true,
			[L["Mocking Blow"]] = true,
			[L["Challenging Roar"]] = true,
			[L["Growl"]] = true,
		},
	}
	
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	if TankWarningsClassicSV.firstTime == true then 
		TankWarningsClassicConfigFrame:Show()
		TankWarningsClassicSV.firstTime = nil
	end

end

function TankWarningsClassic_OnConfigFrameLoaded(self)
	self.name = addonName
	self.okay = function(self)
		self:Show()
	end
	self.cancel = function(self)
		self:Hide()
	end
	--InterfaceOptions_AddCategory(self)
end
function TankWarningsClassic_OnConfigFrameShow(self)
	local configWidgets = {self:GetChildren()}
	-- refresh gui from sv
	for _, widget in pairs(configWidgets) do
		if widget._option then
			local value = (TankWarningsClassicSV[widget._option]~=nil and TankWarningsClassicSV[widget._option])
				or (TankWarningsClassicSV.abilities[widget._option]~=nil and TankWarningsClassicSV.abilities[widget._option])
				or nil
			if value ~= nil then
				if widget:IsObjectType("CheckButton") then
					widget:SetChecked(value)
				else
					UIDropDownMenu_SetSelectedValue(widget, value)
					_G[widget:GetName().."Text"]:SetText(value)					
				end
			end
		end
	end
end
function TankWarningsClassic_OnConfigFrameClose(self) 
	self:GetParent():Hide()
end

------- Checkmark options -------
function TankWarningsClassic_OnConfigCheckButtonClicked(self)
	if self._option then
		if TankWarningsClassicSV[self._option]~=nil then
			TankWarningsClassicSV[self._option] = not TankWarningsClassicSV[self._option]
		elseif TankWarningsClassicSV.abilities[self._option]~=nil then
			TankWarningsClassicSV.abilities[self._option] = not TankWarningsClassicSV.abilities[self._option]
		end
	end
end

------- Raid options panel -------
function TankWarningsClassic_RaidOptionSelected(self)
	TankWarningsClassicSV[self._option] = self.value
	UIDropDownMenu_SetSelectedValue(self, self.value)
	_G[self:GetName().."Text"]:SetText(self.value)
end
function TankWarningsClassic_LoadRaidOptions()
	local info
	info = UIDropDownMenu_CreateInfo()
	info.text = "Warning"
	info.value = "Warning"
	info.func = TankWarningsClassic_RaidOptionSelected
	UIDropDownMenu_AddButton(info)
	info = UIDropDownMenu_CreateInfo()
	info.text = "Message"
	info.value = "Message"
	info.func = TankWarningsClassic_RaidOptionSelected
	UIDropDownMenu_AddButton(info)
end

------- Warning options panel -------
function TankWarningsClassic_WarningFallbackSelected(self)
	TankWarningsClassicSV[self._option] = self.value
	UIDropDownMenu_SetSelectedValue(self, self.value)
	_G[self:GetName().."Text"]:SetText(self.value)
end
function TankWarningsClassic_LoadWarningFallbacks()
	local info
	info = UIDropDownMenu_CreateInfo()
	info.text = "Do nothing"
	info.value = "Do nothing"
	info.func = TankWarningsClassic_WarningFallbackSelected
	UIDropDownMenu_AddButton(info)
	info = UIDropDownMenu_CreateInfo()
	info.text = "Say"
	info.value = "Say"
	info.func = TankWarningsClassic_WarningFallbackSelected
	UIDropDownMenu_AddButton(info)
	info = UIDropDownMenu_CreateInfo()
	info.text = "Yell"
	info.value = "Yell"
	info.func = TankWarningsClassic_WarningFallbackSelected
	UIDropDownMenu_AddButton(info)
end

------- Main logic -------

local playerGUID = UnitGUID("player")
local language = GetLocale()

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self,event,...)
end)
f:RegisterEvent("ADDON_LOADED")

function f:ADDON_LOADED(event, ...)
	if event == "ADDON_LOADED" and ... == addonName then
		twc.OnLoad(self)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, spellType, hideCaster, sourceGUID, sourceName, sourceflags, sourceflags2, destGUID, destName, destFlags, destFlags2, spellId, spellName, spellSchool = CombatLogGetCurrentEventInfo()
	if sourceGUID == playerGUID then
		--Go out if ability is deactivated
		if not TankWarningsClassicSV.abilities[spellName] then
			return
		end
		
		if spellType == "SPELL_CAST_SUCCESS" then
			--Casts with critical expirations
			if spellName == L["Last Stand"] or spellName == L["Shield Wall"] then
				f:TWC_SendChatMessage(string.format(L["%s activated!"], spellName))
				if TankWarningsClassicSV.showExpirations == true then
					for i=1,40 do
						local name,icon,count,debuffType,duration,expirationTime = UnitBuff("player",i)
						if name == spellName then
							C_Timer.After(duration-3, function()
									if UnitIsDeadOrGhost("player") ~= true then
										f:TWC_SendChatMessage(string.format(L["%s will expire in 3 seconds!"], spellName))
									end
								end)
							break
						end
					end
				end
			--Casts without critical expirations
			elseif spellName == L["Challenging Shout"] or spellName == L["Challenging Roar"] then
				f:TWC_SendChatMessage(string.format(L["%s activated!"], spellName))
			end
		--Failures
		elseif spellType == "SPELL_MISSED" then
			--We COULD look for the 15th argument of ... here for the type, but we'll just declare any miss as "resisted"
			if spellName == L["Taunt"] or spellName == L["Mocking Blow"] or spellName == L["Growl"] then
				f:TWC_SendChatMessage(string.format(L["%s resisted!"], spellName))
			end
		end
	end
end

function f:TWC_SendChatMessage(message)
	if TankWarningsClassicSV.showInRaids == true and IsInRaid() == true then
		if TankWarningsClassicSV.raidOption == "Warning" then
			SendChatMessage(message, "RAID_WARNING", "Common")
		else
			SendChatMessage(message, "RAID", "Common")
		end
	elseif TankWarningsClassicSV.showInParties == true and IsInGroup() == true then
		SendChatMessage(message, "PARTY", "Common")
	elseif TankWarningsClassicSV.warningFallback == "Say" then
		SendChatMessage(message, "SAY", "Common")
	elseif TankWarningsClassicSV.warningFallback == "Yell" then
		SendChatMessage(message, "YELL", "Common")
	end
end

SLASH_TWC1 = "/twc"
SLASH_TWC2 = "/tankwarnings"
SLASH_TWC3 = "/tankwarningsclassic"

function SlashCmdList.TWC(msg,editbox)
	if not TankWarningsClassicConfigFrame:IsShown() then
    TankWarningsClassicConfigFrame:Show()
  else 
		TankWarningsClassicConfigFrame:Hide()
  end
end