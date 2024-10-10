if CUSTOM_CLASS_COLORS then return end

local addonName, ColorToolsClassColors =  ...
local L = LibStub("AceLocale-3.0"):GetLocale("ColorToolsClassColors")
local _ = LibStub("LibLodash-1"):Get()



CUSTOM_CLASS_COLORS = {}


local meta = {}
local callbacks = {}
local numCallbacks = 0

function meta:RegisterCallback(method, handler)
	assert(type(method) == "string" or type(method) == "function", "Bad argument #1 to :RegisterCallback (string or function expected)")
	if type(method) == "string" then
		assert(type(handler) == "table", "Bad argument #2 to :RegisterCallback (table expected)")
		assert(type(handler[method]) == "function", "Bad argument #1 to :RegisterCallback (method \"" .. method .. "\" not found)")
		method = handler[method]
	end
	-- assert(not callbacks[method] "Callback already registered!")
	callbacks[method] = handler or true
	numCallbacks = numCallbacks + 1
end

function meta:UnregisterCallback(method, handler)
	assert(type(method) == "string" or type(method) == "function", "Bad argument #1 to :UnregisterCallback (string or function expected)")
	if type(method) == "string" then
		assert(type(handler) == "table", "Bad argument #2 to :UnregisterCallback (table expected)")
		assert(type(handler[method]) == "function", "Bad argument #1 to :UnregisterCallback (method \"" .. method .. "\" not found)")
		method = handler[method]
	end
	-- assert(callbacks[method], "Callback not registered!")
	callbacks[method] = nil
	numCallbacks = numCallbacks - 1
end

local function DispatchCallbacks()
	if numCallbacks < 1 then return end
	-- print("CUSTOM_CLASS_COLORS: DispatchCallbacks")
	for method, handler in pairs(callbacks) do
		local ok, err = pcall(method, handler ~= true and handler or nil)
		if not ok then
			print("ERROR:", err)
		end
	end
end

------------------------------------------------------------------------

local classes = {}
for class in pairs(RAID_CLASS_COLORS) do
	tinsert(classes, class)
end
sort(classes)

local classTokens = {}
for token, class in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	classTokens[class] = token
end
for token, class in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	classTokens[class] = token
end

function meta:GetClassToken(className)
	return className and classTokens[className]
end

------------------------------------------------------------------------

function meta:NotifyChanges()
	-- print("CUSTOM_CLASS_COLORS: NotifyChanges")
	local changed

	for i = 1, #classes do
		local class = classes[i]
		local color = CUSTOM_CLASS_COLORS[class]
		local cache = ColorToolsClassColors[class]

		if cache.r ~= color.r or cache.g ~= color.g or cache.b ~= color.b then
			print("Change found in", class)
			cache = {color:GetRGB()}

			changed = true
		end
	end

	if changed then
		DispatchCallbacks()
	end
end

------------------------------------------------------------------------

setmetatable(CUSTOM_CLASS_COLORS, { __index = meta })



------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------





local defaultValue = {}

_.forEach(RAID_CLASS_COLORS, function(entry, key)
	local r,g,b = entry:GetRGB()
	defaultValue[key] = {r,g,b}
end)



ColorToolsClassColors.init = CreateFrame("Frame")
ColorToolsClassColors.init:RegisterEvent("ADDON_LOADED")
ColorToolsClassColors.init:SetScript("OnEvent", function(self, event, addon)
	if addon ~= "!ColorToolsClassColors" then return end
	ColorToolsClassColorsDB = ColorToolsClassColorsDB or defaultValue
	ColorToolsClassColors.Options.Init()
end)


function ColorToolsClassColors:SetColor(key, value)
	local color = CreateColor(value[1], value[2], value[3])
	color.colorStr = color:GenerateHexColor()
	CUSTOM_CLASS_COLORS[key] = color
	ColorToolsClassColorsDB[key] = {value[1], value[2], value[3]}
end


if not LocalizedClassList then
	LocalizedClassList = function() 
		local tbl = {}
		tbl = FillLocalizedClassList(tbl)
		return tbl
	end
end


ColorToolsClassColors.Options = {}

function  ColorToolsClassColors.Options:Init()
    local AddOnInfo = {C_AddOns.GetAddOnInfo(addonName)}
    local category, layout = Settings.RegisterVerticalLayoutCategory(AddOnInfo[2])
    ColorToolsClassColors.OptionsID = category:GetID()

   	-- local initializer = Settings.CreatePanelInitializer("ColorToolsClassColorsDescTemplate", { text = L["Desc"] });
	-- layout:AddInitializer(initializer);

	local classNames = LocalizedClassList()

    for key, entry in pairs(ColorToolsClassColorsDB) do
		if classNames[key] ~= nil then
			local setting = Settings.RegisterAddOnSetting(category, classNames[key], key, ColorToolsClassColorsDB, "table", classNames[key], defaultValue[key])

			-- why? 
			if select(4, GetBuildInfo()) < 110000 and select(4, GetBuildInfo()) > 40000 then
				setting = Settings.RegisterAddOnSetting(category, classNames[key], key, ColorToolsClassColorsDB, ColorToolsClassColorsDB[key], "table", classNames[key], defaultValue[key])
			end

			Settings.CreateColor(category, setting, nil)
			ColorToolsClassColors:SetColor(key, ColorToolsClassColorsDB[key])
		end
    end

    Settings.RegisterAddOnCategory(category)
end
