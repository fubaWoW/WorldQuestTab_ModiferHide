-- Hide WorldQuestTab map pins while holding a configurable modifier (ALT, SHIFT or CTRL)

local eventFrame = CreateFrame("Frame")

WQTModHideDB = WQTModHideDB or {}
local DEFAULT_MOD = "ALT"

-- Modifier map
local MOD_CHECK = {
    ALT   = IsAltKeyDown,
    SHIFT = IsShiftKeyDown,
    CTRL  = IsControlKeyDown,
}

-- Helpers
local function GetConfiguredMod()
    local mod = (WQTModHideDB.mod or DEFAULT_MOD):upper()
    if MOD_CHECK[mod] then return mod end
    WQTModHideDB.mod = DEFAULT_MOD
    return DEFAULT_MOD
end

local function GetWQTPinPool()
    local core = _G.WQT_WorldQuestFrame
    if (not core) or (not core.pinDataProvider) then return nil end
    return core.pinDataProvider.pinPool
end

local function IsConfiguredModDown()
    return MOD_CHECK[GetConfiguredMod()]() and true or false
end

-- Visibility function: hide while key is down, show otherwise
local function ApplyVisibility()
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end

	local pool = GetWQTPinPool()
    if not pool then return end

    local modDown = IsConfiguredModDown()
	for pin in pool:EnumerateActive() do
		pin:SetShown(not modDown and ((pin.currentAlpha or 1) > 0.05))
	end
end

-- Expose for Global usage (eg. Settings UI)
_G.WQTModHide_ApplyVisibility = ApplyVisibility

-- Hook WQT pin
local function SetupHooks()
    if type(_G.WQT_PinMixin) == "table" and not _G.WQT_PinMixin.ModHideHooked then
        _G.WQT_PinMixin.ModHideHooked = true

        hooksecurefunc(_G.WQT_PinMixin, "UpdatePlacement", function(pin)
            if IsConfiguredModDown() then
                pin:Hide()
            end
        end)
    end

    local core = _G.WQT_WorldQuestFrame
    if type(core) == "table" and not core.ModHideHooked and type(core.GetPinTemplates) == "function" then
        core.ModHideHooked = true
        hooksecurefunc(core, "GetPinTemplates", function()
			ApplyVisibility()
        end)
    end
end

-- Slash commands
SLASH_WQTMODHIDE1 = "/wqthide"
SLASH_WQTMODHIDE2 = "/wqtmodhide"
SLASH_WQTMODHIDE3 = "/wqth"
SlashCmdList.WQTMODHIDE = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local arg = msg:lower()

    if arg == "" then
        print(string.format("|cff00e0ffWQT ModHide|r: current modifier: %s", GetConfiguredMod()))
        print("usage: /wqthide alt | shift | ctrl")
        return
    end

    local modUpper = arg:upper()
    if MOD_CHECK[modUpper] then
        WQTModHideDB.mod = modUpper
        print(string.format("|cff00e0ffWQT ModHide|r: modifier set to: %s", modUpper))
        C_Timer.After(0, ApplyVisibility)
    else
        print(string.format("|cff00e0ffWQT ModHide|r: invalid argument: %s", arg))
        print("usage: /wqthide alt | shift | ctrl")
    end
end

-- Events
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then

        GetConfiguredMod()
        C_Timer.After(0.1, function()
            SetupHooks()
            ApplyVisibility()
        end)

    elseif event == "MODIFIER_STATE_CHANGED" then

		local key = arg1
        local configured = GetConfiguredMod()
        local modKey =
            (configured == "ALT"   and (key == "LALT"   or key == "RALT")) or
            (configured == "SHIFT" and (key == "LSHIFT" or key == "RSHIFT")) or
            (configured == "CTRL"  and (key == "LCTRL"  or key == "RCTRL"))

        if modKey then
            ApplyVisibility()
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ApplyVisibility()

    elseif event == "CVAR_UPDATE" then

		local value = arg1
        if value == "questPOI" then
            C_Timer.After(0.1, ApplyVisibility)
        end
    end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CVAR_UPDATE")