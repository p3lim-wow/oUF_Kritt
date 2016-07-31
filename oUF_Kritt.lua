local _, ns = ...
local oUF = ns.oUF

local FONT = [[Interface\AddOns\oUF_Kritt\semplice.ttf]]
local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {
	bgFile = TEXTURE, edgeFile = TEXTURE, edgeSize = 1
}

local function UpdateHealth(self, event, unit)
	if(self.unit ~= unit) then
		return
	end

	local cur = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	local percentage = cur / max

	local element = self.Health
	element:SetVertexColor(self.ColorGradient(cur, max, unpack(self.colors.smooth)))

	local width = self:GetWidth()
	element:SetPoint('LEFT', (width - 1) * percentage, 0)
end

local function style(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetBackdrop(BACKDROP)
	self:SetBackdropColor(0, 0, 0, 1/2)
	self:SetBackdropBorderColor(0, 0, 0)

	local Health = self:CreateTexture(nil, 'BORDER')
	Health:SetPoint('TOPRIGHT', -1, -1)
	Health:SetPoint('BOTTOMRIGHT', -1, 1)
	Health:SetPoint('LEFT', self:GetWidth(), 0)
	Health:SetColorTexture(2/3, 2/3, 2/3)
	Health.Override = UpdateHealth
	self.Health = Health

	local HealthValue = self:CreateFontString()
	HealthValue:SetPoint('RIGHT', -2, 0)
	HealthValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	HealthValue:SetJustifyH('RIGHT')
	HealthValue:SetWordWrap(false)
	self:Tag(HealthValue, '[kritt:health]')

	local Name = self:CreateFontString()
	Name:SetPoint('LEFT', 4, 0)
	Name:SetPoint('RIGHT', HealthValue, 'LEFT', -2, 0)
	Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	Name:SetJustifyH('LEFT')
	Name:SetWordWrap(false)
	self:Tag(Name, '[kritt:leader][raidcolor][name<|r]')
end

oUF:RegisterStyle('Kritt', style)
oUF:Factory(function(self)
	self:SetActiveStyle('Kritt')
	self:SpawnHeader(nil, nil, 'raid,party',
		'showPlayer', true,
		'showParty', true,
		'showRaid', true,
		'yOffset', -5,
		'point', 'TOP',
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'TANK,HEALER,DAMAGER',
		'maxColumns', 5,
		'unitsPerColumn', 5,
		'columnSpacing', 5,
		'columnAnchorPoint', 'RIGHT',
		'oUF-initialConfigFunction', [[
			self:SetWidth(90)
			self:SetHeight(35)
		]]
	):SetPoint('RIGHT', UIParent, 'LEFT', 776, -100)
end)
