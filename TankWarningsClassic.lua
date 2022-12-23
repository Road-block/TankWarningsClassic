local addonName, twc = ...
local ver = GetAddOnMetadata(addonName, "Version")
local label = string.format("%s v%s",addonName, ver)
local L = twc.L
_G[addonName] = twc
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
------- Config & Setup -------

local last_stand = (GetSpellInfo(12975))
local shield_wall = (GetSpellInfo(871))
local taunt = (GetSpellInfo(355))
local mocking_blow = (GetSpellInfo(694))
local challenging_shout = (GetSpellInfo(1161))
local growl = (GetSpellInfo(6795))
local challenging_roar = (GetSpellInfo(5209))
local frenzied_regeneration = (GetSpellInfo(22842))
local barkskin = (GetSpellInfo(22812))
local survival_instincts = (GetSpellInfo(61336))
local righteous_defense = (GetSpellInfo(31789))
local righteous_fury = (GetSpellInfo(25780))
local divine_protection = (GetSpellInfo(498))
local frost_presence = (GetSpellInfo(48263))
local dark_command = (GetSpellInfo(56222))
local death_grip = (GetSpellInfo(49576))
local army_of_dead = (GetSpellInfo(42650))
local icebound_fort = (GetSpellInfo(48792))
local anti_magic_shell = (GetSpellInfo(48707))
twc._opt = {}
twc._opt.last_stand = last_stand
twc._opt.shield_wall = shield_wall
twc._opt.taunt = taunt
twc._opt.mocking_blow = mocking_blow
twc._opt.challenging_shout = challenging_shout
twc._opt.growl = growl
twc._opt.challenging_roar = challenging_roar
twc._opt.frenzied_regeneration = frenzied_regeneration
twc._opt.barkskin = barkskin
twc._opt.survival_instincts = survival_instincts
twc._opt.righteous_defense = righteous_defense
twc._opt.divine_protection = divine_protection
twc._opt.dark_command = dark_command
twc._opt.death_grip = death_grip
twc._opt.army_of_dead = army_of_dead
twc._opt.icebound_fort = icebound_fort
twc._opt.anti_magic_shell = anti_magic_shell
local TWC_Print = function(text)
	local prefix = DIM_RED_FONT_COLOR:WrapTextInColorCode("TWC:")
	local text = tostring(text)
	local chatFrame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
	chatFrame:AddMessage(string.format("%s %s",prefix, text))
end

local tanks = {["DRUID"]=true, ["PALADIN"]=true, ["WARRIOR"]=true, ["DEATHKNIGHT"]=true,}
local _, playerClass = UnitClass("player")
local TWC_isTanking = function()
	if not tanks[playerClass] then return false end
	if playerClass == "DRUID" then
		local form = GetShapeshiftForm(true)
		if form == 1 then
			return true
		end
	end
	if playerClass == "WARRIOR" then
		local stance = GetShapeshiftForm(true)
		if stance == 2 and IsEquippedItemType("Shields") then
			return true
		end
	end
	if playerClass == "PALADIN" then
		if IsEquippedItemType("Shields") then
			local hasRF = AuraUtil.FindAuraByName(righteous_fury,"player","HELPFUL")
			if hasRF then
				return true
			end
		end
	end
	if playerClass == "DEATHKNIGHT" then
		local hasFP = AuraUtil.FindAuraByName(frost_presence,"player","HELPFUL")
		if hasFP then
			return true
		end
	end
	return false
end

function twc.OnLoad(self)
	print("|cffffff00"..label.." - Use /tankwarnings or /twc for more options.")
	--load default values if they don't exist
	TankWarningsClassicSV = TankWarningsClassicSV or {
--	TankWarningsClassicSV = {
		["firstTime"] = true,
		["raidDoNothing"] = true,
		["raidWarning"] = true,
		["raidChat"] = true,
		["raidYell"] = true,
		["raidSay"] = true,
		["partyDoNothing"] = true,
		["partyChat"] = true,
		["partyYell"] = true,
		["partySay"] = true,
		["noGrpDoNothing"] = true,
		["noGrpYell"] = true,
		["noGrpSay"] = true,
		["showExpirations"] = true,
		["earlyCombat"] = 15,
		["spellMisses"] = true,
		["abilities"] = {
			[last_stand] = true,
			[shield_wall] = true,
			[taunt] = true,
			[mocking_blow] = true,
			[challenging_shout] = true,
			[growl] = true,
			[challenging_roar] = true,
			[frenzied_regeneration] = true,
			[barkskin] = true,
			[survival_instincts] = true,
			[righteous_defense] = true,
			[divine_protection] = true,
			[dark_command] = true,
			[death_grip] = true,
			[army_of_dead] = true,
			[icebound_fort] = true,
			[anti_magic_shell] = true,
		},
	}

	--Custom messages were introduced in version 1.1.2 - make sure we load them properly
	if TankWarningsClassicSV.messages == nil then
		TankWarningsClassicSV.messages = {}
		TankWarningsClassicSV.messages["%s activated!"] = L["%s activated!"]
		TankWarningsClassicSV.messages["%s will expire in 3 seconds!"] = L["%s will expire in 3 seconds!"]
		TankWarningsClassicSV.messages["%s resisted!"] = L["%s resisted!"]
	end

	if TankWarningsClassicSV.earlyCombat == nil then
		TankWarningsClassicSV.earlyCombat = 15
		TankWarningsClassicSV.spellMisses = true
	end

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	if UnitAffectingCombat("player") then
		self._combatStart = GetTime()
	end

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
	self:SetBackdrop(BACKDROP_DARK_DIALOG_32_32)
	tinsert(UISpecialFrames, self:GetName())
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
				if widget.SetChecked then
					widget:SetChecked(value)
				elseif widget.SetValue then
					widget:SetValue(value)
				end
			end
		elseif widget._content then
			_G[widget:GetName()]:SetText(TankWarningsClassicSV.messages[widget._content])
		end
	end
	if TankWarningsClassicSV["raidDoNothing"] == false then
		TankWarningsClassicConfigFrameShowRaidWarningButton:Disable()
		TankWarningsClassicConfigFrameShowRaidChatButton:Disable()
		TankWarningsClassicConfigFrameShowRaidYellButton:Disable()
		TankWarningsClassicConfigFrameShowRaidSayButton:Disable()
	end
	if TankWarningsClassicSV["partyDoNothing"] == false then
		TankWarningsClassicConfigFrameShowPartyChatButton:Disable()
		TankWarningsClassicConfigFrameShowPartyYellButton:Disable()
		TankWarningsClassicConfigFrameShowPartySayButton:Disable()
	end
	if TankWarningsClassicSV["noGrpDoNothing"] == false then
		TankWarningsClassicConfigFrameShowNoGrpYellButton:Disable()
		TankWarningsClassicConfigFrameShowNoGrpSayButton:Disable()
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
		if self._option == "raidDoNothing" then
			if TankWarningsClassicSV["raidDoNothing"] == false then
				TankWarningsClassicConfigFrameShowRaidWarningButton:Disable()
				TankWarningsClassicConfigFrameShowRaidChatButton:Disable()
				TankWarningsClassicConfigFrameShowRaidYellButton:Disable()
				TankWarningsClassicConfigFrameShowRaidSayButton:Disable()
			elseif TankWarningsClassicSV["raidDoNothing"] == true then
				TankWarningsClassicConfigFrameShowRaidWarningButton:Enable()
				TankWarningsClassicConfigFrameShowRaidChatButton:Enable()
				TankWarningsClassicConfigFrameShowRaidYellButton:Enable()
				TankWarningsClassicConfigFrameShowRaidSayButton:Enable()
			end
		end
		if self._option == "partyDoNothing" then
			if TankWarningsClassicSV["partyDoNothing"] == false then
				TankWarningsClassicConfigFrameShowPartyChatButton:Disable()
				TankWarningsClassicConfigFrameShowPartyYellButton:Disable()
				TankWarningsClassicConfigFrameShowPartySayButton:Disable()
			elseif TankWarningsClassicSV["partyDoNothing"] == true then
				TankWarningsClassicConfigFrameShowPartyChatButton:Enable()
				TankWarningsClassicConfigFrameShowPartyYellButton:Enable()
				TankWarningsClassicConfigFrameShowPartySayButton:Enable()
			end
		end
		if self._option == "noGrpDoNothing" then
			if TankWarningsClassicSV["noGrpDoNothing"] == false then
				TankWarningsClassicConfigFrameShowNoGrpYellButton:Disable()
				TankWarningsClassicConfigFrameShowNoGrpSayButton:Disable()
			elseif TankWarningsClassicSV["noGrpDoNothing"] == true then
				TankWarningsClassicConfigFrameShowNoGrpYellButton:Enable()
				TankWarningsClassicConfigFrameShowNoGrpSayButton:Enable()
			end
		end

	end
end

function TankWarningsClassic_OnConfigEarlyCombatSlider(self, value, userInput)
	if self._option then
		if self._option == "earlyCombat" then
			TankWarningsClassicSV["earlyCombat"] = tonumber(value)
			local valuetext = tonumber(value) <= 0 and "|cffff0000Disabled|r" or string.format("%d sec",value)
			_G[self:GetName().."Text"]:SetText(valuetext)
		end
	end
end

------- Messages panel -------
function TankWarningsClassic_EditBoxEventHandler(self, event, ...)
	TankWarningsClassicSV.messages[self._content] = self:GetText()
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

function f:PLAYER_REGEN_DISABLED(event, ...)
	self._combatStart = GetTime()
end

local subevents = {["SPELL_CAST_SUCCESS"] = true, ["SPELL_MISSED"] = true}
function f:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, spellType, hideCaster, sourceGUID, sourceName, sourceflags, sourceflags2, destGUID, destName, destFlags, destFlags2, spellId, spellName, spellSchool, missType = CombatLogGetCurrentEventInfo()
	if not subevents[spellType] then return end
	if sourceGUID == playerGUID then
		if spellType == "SPELL_CAST_SUCCESS" then
			--Casts with critical expirations
			if spellName == last_stand or spellName == shield_wall
				or spellName == barkskin or spellName == survival_instincts
				or spellName == divine_protection
				or spellName == icebound_fort then
				f:TWC_SendChatMessage(string.format(TankWarningsClassicSV.messages["%s activated!"], spellName))
				if TankWarningsClassicSV.showExpirations == true then
					for i=1,40 do
						local name,icon,count,debuffType,duration,expirationTime = UnitBuff("player",i)
						if name == spellName then
							C_Timer.After(duration-3, function()
									if UnitIsDeadOrGhost("player") ~= true then
										f:TWC_SendChatMessage(string.format(TankWarningsClassicSV.messages["%s will expire in 3 seconds!"], spellName))
									end
								end)
							break
						end
					end
				end
			--Casts without critical expirations
			elseif spellName == challenging_shout
				or spellName == challenging_roar
				or spellName == army_of_dead
				or spellName == anti_magic_shell
				or spellName == frenzied_regeneration then
				f:TWC_SendChatMessage(string.format(TankWarningsClassicSV.messages["%s activated!"], spellName))
			end
		--Failures
		elseif spellType == "SPELL_MISSED" then
			--We COULD look for the 15th argument of ... here for the type, but we'll just declare any miss as "resisted"
			if spellName == taunt or spellName == mocking_blow
				or spellName == growl
				or spellName == dark_command or spellName == death_grip
				or spellName == righteous_defense then
				if missType == "IMMUNE" then
					f:TWC_SendChatMessage(string.format(_G.SPELLIMMUNESELFOTHER,spellName,destName))
				else
					f:TWC_SendChatMessage(string.format(TankWarningsClassicSV.messages["%s resisted!"], spellName))
				end
			else
				if missType == "DODGE" or missType == "PARRY" or missType == "MISS" then
					if TankWarningsClassicSV.earlyCombat > 0 then
						local since_combat = GetTime() - self._combatStart
						if TWC_isTanking() and (since_combat <= tonumber(TankWarningsClassicSV.earlyCombat)) then
							f:TWC_SendChatMessage(string.format("%s %s!",spellName,_G["ACTION_SPELL_MISSED_"..missType]))
						end
					end
				end
			end
		end
	end
end

function f:TWC_SendChatMessage(message)
	local SendChatMessage
	if IsInInstance() then
		SendChatMessage = _G.SendChatMessage
	else
		SendChatMessage = TWC_Print
	end
	if IsInGroup() then
		if IsInRaid() then -- raid
			if TankWarningsClassicSV.raidDoNothing == true then
				if TankWarningsClassicSV.raidWarning == true then
					SendChatMessage(message, "RAID_WARNING", "Common")
				end
				if TankWarningsClassicSV.raidChat == true then
					SendChatMessage(message, "RAID", "Common")
				end
				if TankWarningsClassicSV.raidYell == true then
					SendChatMessage(message, "YELL", "Common")
				end
				if TankWarningsClassicSV.raidSay == true then
					SendChatMessage(message, "SAY", "Common")
				end
			end
		else -- party
			if TankWarningsClassicSV.partyDoNothing == true then
				if TankWarningsClassicSV.partyChat == true then
					SendChatMessage(message, "PARTY", "Common")
				end
				if TankWarningsClassicSV.partyYell == true then
					SendChatMessage(message, "YELL", "Common")
				end
				if TankWarningsClassicSV.partySay == true then
					SendChatMessage(message, "SAY", "Common")
				end
			end
		end
	else -- solo
		if TankWarningsClassicSV.noGrpDoNothing == true then
			if TankWarningsClassicSV.noGrpYell == true then
				SendChatMessage(message, "YELL", "Common")
			end
			if TankWarningsClassicSV.noGrpSay == true then
				SendChatMessage(message, "SAY", "Common")
			end
		end
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
