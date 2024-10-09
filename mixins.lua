

ColorToolsClassColorsDescMixin = {}

function ColorToolsClassColorsDescMixin:OnLoad()
	C_Timer.After(3, function()
		local d = self:GetData()
		self.text = d.data.text
	end)
end
function ColorToolsClassColorsDescMixin:OnShow()
	self.Text:SetText(self.text)
	self:SetHeight(self.Text:GetStringHeight())
end




SettingsColorControlMixin = CreateFromMixins(SettingsControlMixin);

function SettingsColorControlMixin:OnLoad()
	SettingsControlMixin.OnLoad(self);
    

	self.Colorswatch = CreateFrame("Button", nil, self);
    self.Colorswatch:SetPoint("LEFT", self, "CENTER", -80, 0);
    self.Colorswatch:SetSize(20, 20);
    self.Colorswatch.Texture = self.Colorswatch:CreateTexture()
	self.Colorswatch.Texture:SetAllPoints()


    self.Colorswatch:SetScript("OnClick", function()
        local currentValue = self:GetSetting():GetValue()
		local options = {
			swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB();
                self:GetSetting():SetValue({r, g, b}) 
            end,
			cancelFunc = function()
                self.Colorswatch.Texture:SetColorTexture(currentValue[1],currentValue[2],currentValue[3])
            end,
			hasOpacity = false,
			r = currentValue[1],
			g = currentValue[2],
			b = currentValue[3],
		};
		
	    ColorPickerFrame:SetupColorPickerAndShow(options);
	end);


	self.Tooltip:SetScript("OnMouseUp", function()
		if self.Colorswatch:IsEnabled() then
			self.Colorswatch:Click();
		end
	end);
end

function SettingsColorControlMixin:Init(initializer)
	SettingsControlMixin.Init(self, initializer);
    local currentValue = self:GetSetting():GetValue()
    self.Colorswatch.Texture:SetColorTexture(table.unpack(currentValue))
end

function SettingsColorControlMixin:OnSettingValueChanged(setting, value)
	SettingsControlMixin.OnSettingValueChanged(self, setting, value);
    self.Colorswatch.Texture:SetColorTexture(value[1], value[2], value[3])
end

function SettingsColorControlMixin:Release()
	SettingsControlMixin.Release(self);
end



function Settings.CreateColor(category, setting, tooltip)
    local initializer = Settings.CreateControlInitializer("SettingsColorControlTemplate", setting, nil, tooltip);
    local layout = SettingsPanel:GetLayout(category);
	layout:AddInitializer(initializer);

    return initializer;
end