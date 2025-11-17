WQTModHideDB = WQTModHideDB or {}
if not WQTModHideDB.mod then WQTModHideDB.mod = "ALT" end

local function RegisterSettings()
    local settingsFrame = _G.WQT_SettingsFrame
    if not settingsFrame or not settingsFrame.dataContainer then return end

    local function CreateOption(id, label, tooltip)
        return { id = id, label = label, tooltip = tooltip }
    end

    local category = settingsFrame.dataContainer:AddCategory("WQT_MODHIDE", "Modifier Hide", false)

    local dropdown = category:AddDropdown(
        "MODIFIER_KEY",
        "Modifier key",
        "Choose which modifier hides WQT map pins.",
        {
            CreateOption("ALT", "ALT", "Hold ALT to hide pins."),
            CreateOption("SHIFT", "SHIFT", "Hold SHIFT to hide pins."),
            CreateOption("CTRL", "CTRL", "Hold CTRL to hide pins.")
        }
    )

    dropdown:SetGetValueFunction(function()
        return WQTModHideDB.mod
    end)

    dropdown:SetValueChangedFunction(function(value)
        WQTModHideDB.mod = value
        if _G.WQTModHide_ApplyVisibility then
            _G.WQTModHide_ApplyVisibility()
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		C_Timer.After(0.1, RegisterSettings)
	end
end)