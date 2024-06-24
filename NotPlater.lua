NotPlater = LibStub("AceAddon-3.0"):NewAddon("NotPlater", "AceEvent-3.0", "AceHook-3.0")
NotPlater.revision = "v2.0.5"

local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitHealth = UnitHealth
local UnitGUID = UnitGUID
local UnitExists = UnitExists
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local frames = {}

NotPlater.frame = CreateFrame("Frame")
function NotPlater:OnInitialize()
	self:LoadDefaultConfig() 
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NotPlaterDB", self.defaults) 
	self:PARTY_MEMBERS_CHANGED()
	self:RAID_ROSTER_UPDATE() 
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:Reload()

	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
end

function NotPlater:IsTarget(frame)
    local targetExists = UnitExists('target')
    if (not targetExists) then
        return false
    end

	local nameText  = select(5,frame:GetRegions())
    local targetName = UnitName('target')

	return nameText and targetName == nameText:GetText() and frame:GetAlpha() >= 0.99
end


 



function NotPlater:PrepareFrame(frame)
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
	local health, cast = frame:GetChildren()

	-- Hooks and creation (only once that way settings can be applied while frame is visible)
	if not frame.npHooked then
		frame.npHooked = true

		frame.highlightTexture, frame.nameText, frame.levelText, frame.bossIcon, frame.raidIcon = highlightTexture, nameText, levelText, bossIcon, raidIcon

 

		-- Hide default border
		healthBorder:Hide()

		-- Construct everything
		self:ConstructHealthBar(frame, health)
		self:ConstructThreatComponents(frame.healthBar)
		self:ConstructCastBar(frame)
		self:ConstructTarget(frame)

		-- Hide old healthbar
		health:Hide()



    
		self:HookScript(frame, "OnShow", function(self)
			self.unitClass = nil
			NotPlater:CastBarOnShow(self)
			NotPlater:HealthBarOnShow(health)
			NotPlater:StackingCheck(self)
			NotPlater:ThreatComponentsOnShow(self)
			NotPlater:TargetCheck(self)
			self.targetChanged = true
		end)

		self:HookScript(frame, 'OnUpdate', function(self, elapsed)
			if not self.targetCheckElapsed then self.targetCheckElapsed = 0 end
			self.targetCheckElapsed = self.targetCheckElapsed + elapsed
			if self.targetCheckElapsed >= 0.1 then
				if self.targetChanged then
					NotPlater:TargetCheck(self)
					self.targetChanged = nil
				end
				if NotPlater.db.profile.threat.nameplateColors.general.useClassColors then
					if not self.unitClass then
						NotPlater:ClassCheck(self)
					end
					if self.unitClass then
						frame.healthBar:SetStatusBarColor(self.unitClass.r, self.unitClass.g, self.unitClass.b, 1)
					end
				end
				NotPlater:SetTargetTargetText(self)
				self.targetCheckElapsed = 0
			end

			      --Свои цвета--
				local r, g, b = self.healthBar:GetStatusBarColor()
				if g + b == 0 then
					--цвет враждебного инита 
					frame.healthBar:SetStatusBarColor(0.78, 0.306, 0.604, 1)
				elseif r + b == 0 then
					--цвет дружественного юнита
					frame.healthBar:SetStatusBarColor(0.294, 0.686, 0.298, 1) 
				elseif r + g == 0 then
					--цвет дружественного игрока
					frame.healthBar:SetStatusBarColor(0.522, 0.522, 0.851, 1)

				 	--Найти фрейм юнита, к которому принадлежит healthBar

					--Doto: add class color

				elseif 2 - (r + g) < 0.05 and b == 0 then
					--цвет нейтрального юнита 
					frame.healthBar:SetStatusBarColor(0.855, 0.773, 0.361, 1)
				else
					-- self.r, self.g, self.b = r, g, b
					--цвет непонятно кого 
				end	




			if NotPlater:IsTarget(self) then
				self:SetAlpha(1)
			else
				if NotPlater.db.profile.target.general.nonTargetAlpha.enable then
					self:SetAlpha(NotPlater.db.profile.target.general.nonTargetAlpha.opacity)
				end
			end
			if NotPlater.db.profile.levelText.general.enable then
				levelText:Show()
				levelText:SetAlpha(NotPlater.db.profile.levelText.general.opacity)
			else
				levelText:Hide()
			end
		end)
	end


	local iconboss = frame.bossIcon
	iconboss:SetTexture("Interface\\AddOns\\NotPlater\\images\\targetBorders\\boss")
	iconboss:SetTexCoord(0, 0.15, 0.35, 0.63)
	-- iconboss:SetSize(64, 64)
	-- iconboss:SetVertexColor(1, 1, 1, 1) 
	-- if   frame.bossIcon and  frame.bossIcon:GetObjectType() == "Texture" then
	-- 	-- Заменяем иконку на свою
	  
	-- 	-- Если требуется, можете изменить другие свойства иконки, такие как размер, цвет и т.д.
	-- 	-- Пример:
	-- 	frame.bossIcon:SetSize(64, 64) -- Устанавливаем размер иконки
	-- 	-- frame.bossIcon:SetVertexColor(1, 1, 1, 1) -- Устанавливаем цвет (белый, непрозрачный)

	-- 	print("установили")
	--   else
	-- 	print("bossIcon не является объектом Texture")
	--   end 
	
	-- Configure everything
	self:ConfigureThreatComponents(frame)
	self:ConfigureHealthBar(frame, health)
	self:ConfigureCastBar(frame)
	self:ConfigureStacking(frame)
	self:ConfigureGeneralisedIcon(iconboss, frame.healthBar, self.db.profile.bossIcon)
	-- self:ConfigureGeneralisedIcon(bossIcon, frame.healthBar, self.db.profile.bossIcon)
	self:ConfigureGeneralisedIcon(raidIcon, frame.healthBar, self.db.profile.raidIcon)
	self:ConfigureLevelText(levelText, frame.healthBar)
	self:ConfigureNameText(nameText, frame.healthBar)
	self:ConfigureTarget(frame)
	self:TargetCheck(frame)
end

function NotPlater:HookFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if( not frames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			frames[frame] = true
			self:PrepareFrame(frame)
		end
	end
end

function NotPlater:Reload()
	if self.db.profile.castBar.statusBar.general.enable then
		self:RegisterCastBarEvents(NotPlater.frame)
	else
		self:UnregisterCastBarEvents(NotPlater.frame)
	end

	if self.db.profile.threat.general.enableMouseoverUpdate then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	else
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end

	for frame in pairs(frames) do
		self:PrepareFrame(frame)
	end
end

function NotPlater:PLAYER_TARGET_CHANGED()
	for frame in pairs(frames) do
		frame.targetChanged = true
	end
end

function NotPlater:ClassCheck(frame)
	if frame.unitClass then return end

	if self:IsTarget(frame) then
		frame.unitClass = select(2, UnitClass("target"))
		if frame.unitClass then frame.unitClass = RAID_CLASS_COLORS[frame.unitClass] end
		return
	end

	local _, _, _, _, nameText, levelText = frame:GetRegions()
	local name = nameText:GetText()
	local level = levelText:GetText()
	--local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
	local healthValue = frame.healthBar:GetValue()
	local group = self.raid or self.party
	if group then
		for gMember,unitID in pairs(group) do
			local targetString = unitID .. "-target"
			if name == UnitName(targetString) and level == tostring(UnitLevel(targetString)) and healthValue == UnitHealth(targetString) then
				frame.unitClass = select(2, UnitClass("target"))
				if frame.unitClass then frame.unitClass = RAID_CLASS_COLORS[frame.unitClass] end
				return
			end
		end
	end
	if name == UnitName("mouseover") and level == tostring(UnitLevel("mouseover")) and healthValue == UnitHealth("mouseover") then
		frame.unitClass = select(2, UnitClass("mouseover"))
		if frame.unitClass then frame.unitClass = RAID_CLASS_COLORS[frame.unitClass] end
		return
	end
	if name == UnitName("focus") and level == tostring(UnitLevel("focus")) and healthValue == UnitHealth("focus") then
		frame.unitClass = select(2, UnitClass("focus"))
		if frame.unitClass then frame.unitClass = RAID_CLASS_COLORS[frame.unitClass] end
	end
end

function NotPlater:UPDATE_MOUSEOVER_UNIT()
	if UnitCanAttack("player", "mouseover") and not UnitIsDeadOrGhost("mouseover") and UnitAffectingCombat("mouseover") then
		local mouseOverGuid = UnitGUID("mouseover")
		local targetGuid = UnitGUID("target")
		for frame in pairs(frames) do
			if frame:IsShown() then
				if mouseOverGuid == targetGuid then
					if self:IsTarget(frame) then
						self:MouseoverThreatCheck(frame.healthBar, targetGuid)
					end
				else
					local _, _, _, _, nameText, levelText = frame:GetRegions()
					local name = nameText:GetText()
					local level = levelText:GetText()
					local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
					local healthValue = frame.healthBar:GetValue()
					if name == UnitName("mouseover") and level == tostring(UnitLevel("mouseover")) and healthValue == UnitHealth("mouseover") and healthValue ~= healthMaxValue then
						self:MouseoverThreatCheck(frame.healthBar, mouseOverGuid)
					end
				end
			end
		end
	end
end

local numChildren = -1
NotPlater.frame:SetScript("OnUpdate", function(self, elapsed)
	if(WorldFrame:GetNumChildren() ~= numChildren) then
		numChildren = WorldFrame:GetNumChildren()
		NotPlater:HookFrames(WorldFrame:GetChildren())
	end
end)

NotPlater.frame:SetScript("OnEvent", function(self, event, unit)
	for frame in pairs(frames) do
		if frame:IsShown() then
			if unit == "target" then
				if NotPlater:IsTarget(frame) then
					frame.healthBar.lastUnitMatch = UnitGUID(unit)
					NotPlater:CastBarOnCast(frame, event, unit)
				end
			else
				local _, _, _, _, nameText, levelText = frame:GetRegions()
				local name = nameText:GetText()
				local level = levelText:GetText()
				local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
				local healthValue = frame.healthBar:GetValue()
				if name == UnitName(unit) and level == tostring(UnitLevel(unit)) and healthValue == UnitHealth(unit) and healthValue ~= healthMaxValue then
					frame.healthBar.lastUnitMatch = UnitGUID(unit)
					NotPlater:CastBarOnCast(frame, event, unit)
				end
			end
		end
	end
end)