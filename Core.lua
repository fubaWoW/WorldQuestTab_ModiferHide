-- Hide WorldQuestTab map pins while holding a configurable modifier (ALT, SHIFT or CTRL)

local eventFrame = CreateFrame("Frame")

WQTModHideDB = WQTModHideDB or {}
local DEFAULT_MOD = "ALT"

local MOD_CHECK = {
    ALT   = IsAltKeyDown,
    SHIFT = IsShiftKeyDown,
    CTRL  = IsControlKeyDown,
}

local function GetConfiguredMod()
    local mod = (WQTModHideDB.mod or DEFAULT_MOD):upper()

    if MOD_CHECK[mod] then
        return mod
    end

    WQTModHideDB.mod = DEFAULT_MOD
    return DEFAULT_MOD
end

local function IsConfiguredModDown()
    return MOD_CHECK[GetConfiguredMod()]() and true or false
end


--------------------------------------------------
-- Pin tracking
--------------------------------------------------
-- WQT no longer exposes its pin data provider (or its pin pool) through the
-- public "WQT_WorldQuestFrame" frame - that object is just the quest list
-- content frame. The actual provider lives inside WQT's private addon
-- namespace and can't be reached from another addon anymore.
--
-- Instead, WQT fires a public callback every time it sets up a pin for
-- display ("WQT.MapPinProvider.PinInitialized", see MapPinProvider.lua,
-- WQT_PinMixin:Setup). We use that to build our own registry of pin frames.
--
-- A pin only has a questID while WQT considers it "active"; when WQT
-- releases a pin back to its pool it clears pin.questID to nil (and hides
-- it itself), so checking pin.questID is a safe, always-available way to
-- tell active pins from pooled/inactive ones without needing the pool.

local knownPins = setmetatable({}, { __mode = "k" })
local pendingApply = false

local function ApplyVisibility()
    pendingApply = false

    if not (WorldMapFrame and WorldMapFrame:IsShown()) then
        return
    end

    local modDown = IsConfiguredModDown()

    for pin in pairs(knownPins) do
        if pin.questID then
            if modDown then
                pin:Hide()
            else
                pin:SetShown((pin.currentAlpha or 1) > 0.05)
            end
        end
    end
end

_G.WQTModHide_ApplyVisibility = ApplyVisibility

-- Debounced version for use from callbacks that can fire many times in a row
-- (once per pin per placement pass). C_Timer.After(0, ...) runs on the next
-- frame tick, i.e. after WQT has fully finished placing/showing its pins.
local function RequestApplyVisibility()
    if pendingApply then
        return
    end

    pendingApply = true
    C_Timer.After(0, ApplyVisibility)
end


--------------------------------------------------
-- Hook into WQT via its callback registry
--------------------------------------------------

local hooked = false

local function SetupHooks()
    if hooked then
        return true
    end

    local registry = _G.WQT_CallbackRegistry

    if not registry then
        return false
    end

    registry:RegisterCallback("WQT.MapPinProvider.PinInitialized", function(_, pin)
        knownPins[pin] = true
        RequestApplyVisibility()
    end, eventFrame)

    hooked = true
    return true
end


--------------------------------------------------
-- Slash commands
--------------------------------------------------

SLASH_WQTMODHIDE1 = "/wqthide"
SLASH_WQTMODHIDE2 = "/wqtmodhide"
SLASH_WQTMODHIDE3 = "/wqth"

SlashCmdList.WQTMODHIDE = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local arg = msg:lower()

    if arg == "" then
        print(string.format(
            "|cff00e0ffWQT ModHide|r: current modifier: %s",
            GetConfiguredMod()
        ))
        print(string.format(
            "|cff00e0ffWQT ModHide|r: hook active: %s, tracked pins: %d",
            tostring(hooked), (function() local n = 0 for _ in pairs(knownPins) do n = n + 1 end return n end)()
        ))
        print("usage: /wqthide alt | shift | ctrl")
        return
    end

    local modUpper = arg:upper()

    if MOD_CHECK[modUpper] then
        WQTModHideDB.mod = modUpper

        print(string.format(
            "|cff00e0ffWQT ModHide|r: modifier set to: %s",
            modUpper
        ))

        ApplyVisibility()
    else
        print(string.format(
            "|cff00e0ffWQT ModHide|r: invalid argument: %s",
            arg
        ))
        print("usage: /wqthide alt | shift | ctrl")
    end
end


--------------------------------------------------
-- Events
--------------------------------------------------

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then

        GetConfiguredMod()

        -- WQT creates its callback registry very early (Data.lua), but we
        -- retry a couple of times regardless in case load order ever changes.
        C_Timer.After(0, function()
            SetupHooks()
            ApplyVisibility()
        end)

        C_Timer.After(0.5, function()
            SetupHooks()
            ApplyVisibility()
        end)

    elseif event == "ADDON_LOADED" then

        local addonName = ...

        if addonName == "WorldQuestTab" then
            C_Timer.After(0, function()
                SetupHooks()
                ApplyVisibility()
            end)
        end

    elseif event == "MODIFIER_STATE_CHANGED" then

        local key = ...
        local configured = GetConfiguredMod()

        local modKey =
            (configured == "ALT"   and (key == "LALT"   or key == "RALT")) or
            (configured == "SHIFT" and (key == "LSHIFT" or key == "RSHIFT")) or
            (configured == "CTRL"  and (key == "LCTRL"  or key == "RCTRL"))

        if modKey then
            ApplyVisibility()
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then

        C_Timer.After(0.1, ApplyVisibility)

    elseif event == "CVAR_UPDATE" then

        local value = ...

        if value == "questPOIWQ" then
            C_Timer.After(0.1, ApplyVisibility)
        end
    end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CVAR_UPDATE")