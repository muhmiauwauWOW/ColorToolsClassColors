if CUSTOM_CLASS_COLORS then return end

local addonName, ColorToolsClassColors =  ...
local _ = LibStub("LibLodash-1"):Get()


if not LocalizedClassList then
	LocalizedClassList = function() 
		local tbl = {}
		tbl = FillLocalizedClassList(tbl)
		return tbl
	end
end

local L = {};
local locale = GetLocale()

if locale == "enUS" then
    L["Desc"] = "Please note that not all addons support custom class colors. You may need to reload your UI for the changes to take effect."
elseif locale == "koKR" then
    L["Desc"] = "모든 애드온이 사용자 지정 직업 색상을 지원하는 것은 아닙니다. 변경 사항을 적용하려면 UI를 다시 로드해야 할 수 있습니다."
elseif locale == "frFR" then
    L["Desc"] = "Veuillez noter que tous les addons ne prennent pas en charge les couleurs de classe personnalisées. Vous devrez peut-être recharger votre interface utilisateur pour que les changements prennent effet."
elseif locale == "deDE" then
    L["Desc"] = "Bitte beachte, dass nicht alle Addons benutzerdefinierte Klassenfarben unterstützen. Möglicherweise musst du deine Benutzeroberfläche neu laden, damit die Änderungen wirksam werden."
elseif locale == "zhCN" then
    L["Desc"] = "请注意，并非所有插件都支持自定义职业颜色。您可能需要重新加载界面才能使更改生效。"
elseif locale == "esES" then
    L["Desc"] = "Ten en cuenta que no todos los addons admiten colores de clase personalizados. Es posible que tengas que recargar la interfaz de usuario para que los cambios surtan efecto."
elseif locale == "zhTW" then
    L["Desc"] = "請注意，並非所有插件都支援自訂職業顏色。您可能需要重新載入介面才能使變更生效。"
elseif locale == "esMX" then
    L["Desc"] = "Ten en cuenta que no todos los addons son compatibles con colores de clase personalizados. Es posible que tengas que reiniciar la interfaz de usuario para que los cambios surtan efecto."
elseif locale == "ruRU" then
    L["Desc"] = "Обратите внимание, что не все аддоны поддерживают пользовательские цвета классов. Возможно, потребуется перезагрузить интерфейс, чтобы изменения вступили в силу."
elseif locale == "ptBR" then
    L["Desc"] = "Observe que nem todos os addons suportam cores de classe personalizadas. Pode ser necessário recarregar sua interface do usuário para que as alterações entrem em vigor."
elseif locale == "itIT" then
    L["Desc"] = "Tieni presente che non tutti gli addon supportano i colori di classe personalizzati. Potrebbe essere necessario ricaricare l'interfaccia utente affinché le modifiche abbiano effetto."
end

CUSTOM_CLASS_COLORS = {}

local classNames = LocalizedClassList()
local sortedClasses = {}

_.forEach(classNames, function(v, k)
	if not RAID_CLASS_COLORS[k] then return end
	table.insert(sortedClasses, {key = k, value = v})
end)

sort(sortedClasses, function(a, b) return a.value < b.value end)



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
	for method, handler in pairs(callbacks) do
		local ok, err = pcall(method, handler ~= true and handler or nil)
		if not ok then
			print("ERROR:", err)
		end
	end
end

------------------------------------------------------------------------

function meta:NotifyChanges()
	local changed

	_.forEach(sortedClasses, function(entry, idx)
		local class = entry.key
		local color = CUSTOM_CLASS_COLORS[class]
		local cache = ColorToolsClassColors[class]

		if color:IsEqualTo(cache) then
			cache = color
			changed = true
		end
	end)

	if changed then
		DispatchCallbacks()
	end
end

setmetatable(CUSTOM_CLASS_COLORS, { __index = meta })




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




ColorToolsClassColors.Options = {}

function ColorToolsClassColors.Options:Init()
    local AddOnInfo = {C_AddOns.GetAddOnInfo(addonName)}
    local category, layout = Settings.RegisterVerticalLayoutCategory(AddOnInfo[2])
    ColorToolsClassColors.OptionsID = category:GetID()

	local data = { settings = {}, text = L["Desc"] }
	local initializer = Settings.CreatePanelInitializer("ColorToolsClassColorsDescTemplate", data);
	layout:AddInitializer(initializer);

    for idx, value in pairs(sortedClasses) do
		local ID = value.key
		local className = value.value
		if className ~= nil then
			local setting = Settings.RegisterAddOnSetting(category, className, ID, ColorToolsClassColorsDB, "table", className, defaultValue[ID])

			Settings.CreateColor(category, setting, nil)
			ColorToolsClassColors:SetColor(ID, ColorToolsClassColorsDB[ID])
		end
    end

    Settings.RegisterAddOnCategory(category)
end