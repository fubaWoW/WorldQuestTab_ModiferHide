-- Inject a dropdown into WorldQuestTab's Settings panel, very easy because of the damn good API!

WQTModHideDB = WQTModHideDB or {}
if not WQTModHideDB.mod then WQTModHideDB.mod = "ALT" end

local CATEGORY_ID = "MAPPINS"           -- put settings under WQT's existing "Map Pins"
local SUBCATEGORY_ID = "WQT_MODHIDE"    -- our own subcategory under Map Pins
local SUBCATEGORY_LABEL = "Modifier Hide"

-- Local mapping helpers for the dropdown
local MOD_ORDER = { "ALT", "SHIFT", "CTRL" }
local function ModToIndex(mod)
    mod = (mod or "ALT"):upper()
    for i, v in ipairs(MOD_ORDER) do
        if v == mod then return i end
    end
    return 1
end

-- Build the dropdown options in WQT's expected format:
-- options must be an array, selection check compares the ARRAY INDEX, but valueChangedFunc receives the "arg1" we pass (we pass the string, e.g. "ALT").
local function BuildOptions()
    return {
	  { label = "ALT",   tooltip = "Hold ALT to hide pins.",   arg1 = "ALT"   },
	  { label = "SHIFT", tooltip = "Hold SHIFT to hide pins.", arg1 = "SHIFT" },
	  { label = "CTRL",  tooltip = "Hold CTRL to hide pins.",  arg1 = "CTRL"  },
	}
end

-- Add category + settings to the WQT settings frame
local function RegisterIntoWQT()
    local frame = _G.WQT_SettingsFrame
    if not frame then return end

    -- Ensure parent category exists, so we can add a subcategory under "Map Pins"
    frame:RegisterCategory({
        id = SUBCATEGORY_ID,
        parentCategory = CATEGORY_ID,
        label = SUBCATEGORY_LABEL,
        expanded = true,
    })

    -- Dropdown for modifier key
    frame:AddSetting({
        template        = "WQT_SettingDropDownTemplate",
        categoryID      = SUBCATEGORY_ID,
        label           = "Modifier key",
        tooltip         = "Choose which modifier controls WQT pin visibility.",
        options         = BuildOptions,
        valueChangedFunc = function(value)           -- value is "ALT", "SHIFT" or "CTRL"
            WQTModHideDB.mod = (value or "ALT"):upper()
            if _G.WQTModHide_ApplyVisibility then
                _G.WQTModHide_ApplyVisibility()
            end
        end,
        getValueFunc    = function()                 -- must return the ARRAY INDEX
            return ModToIndex(WQTModHideDB.mod)
        end,
    })
	
end

-- We can call this anytime after WQT loads; WQT buffers settings if not initialized yet.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		C_Timer.After(0.1, RegisterIntoWQT)
	end
end)
