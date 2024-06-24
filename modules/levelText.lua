if( not NotPlater ) then return end

function NotPlater:ScaleLevelText(levelText, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.levelText then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedText(levelText, scalingFactor, self.db.profile.levelText)
	end
end

function NotPlater:LevelTextOnShow(levelText, anchorFrame)
	local levelTextConfig = self.db.profile.levelText
	levelText:ClearAllPoints()
	levelText:SetPoint(levelTextConfig.position.anchor, anchorFrame, levelTextConfig.position.anchor, levelTextConfig.position.xOffset, levelTextConfig.position.yOffset)
	levelText:SetAlpha(levelTextConfig.general.opacity)

 
end

function NotPlater:ConfigureLevelText(levelText, anchorFrame)
	local levelTextConfig = self.db.profile.levelText 
	self:ConfigureGeneralisedText(levelText, anchorFrame, levelTextConfig)
	levelText:SetAlpha(levelTextConfig.general.opacity)     
	-- local h = CreateFrame("Frame", nil, anchorFrame) -- or self.Health 
	-- h:SetFrameLevel(15) -- or w/e number you need
	-- self.name = h:CreateFontString(nil, "OVERLAY") 
	-- anchorFrame:SetFrameStrata("HIGH") 
	anchorFrame:SetFrameLevel(1)  
	-- levelText:SetText("textLabel") -- Устанавливаем текст
	-- levelText:SetTextColor(1, 1, 0, 1) -- Устанавливаем цвет текста
	-- levelText:SetFont("Fonts\\FRIZQT__.TTF", "15", "OUTLINE") -- Устанавливаем размер текста 
end
 