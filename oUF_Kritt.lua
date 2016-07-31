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
	if(UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
		element:SetPoint('LEFT', width, 0)

		self.IncomingHeal:Hide()
		self.Absorbs:Hide()
		self.AbsorbsBorder:Hide()

		return
	else
		element:SetPoint('LEFT', (width - 1) * percentage, 0)
	end

	local incoming = UnitGetIncomingHeals(unit) or 0
	if(incoming > 0) then
		local offset = (width - 2) * math.min(1 - percentage, incoming / max)
		self.IncomingHeal:SetPoint('RIGHT', element, 'LEFT', offset, 0)
		self.IncomingHeal:Show()
	else
		self.IncomingHeal:Hide()
	end

	local absorb = UnitGetTotalAbsorbs(unit) or 0
	if(absorb > 0) then
		local offset = math.max(2, (width * math.min(1 - percentage, absorb / max)))
		self.Absorbs:SetPoint('RIGHT', element, 'LEFT', offset, 0)
		self.Absorbs:Show()
		self.AbsorbsBorder:Show()
	else
		self.Absorbs:Hide()
		self.AbsorbsBorder:Hide()
	end
end

local function CreateIndicator(self, size)
	local Indicator = self:CreateTexture(nil, 'OVERLAY')
	Indicator:SetSize(size, size)
	Indicator:SetTexture(TEXTURE)

	local Background = self:CreateTexture()
	Background:SetPoint('CENTER', Indicator)
	Background:SetSize(size + 2, size + 2)
	Background:SetColorTexture(0, 0, 0)

	hooksecurefunc(Indicator, 'Show', function()
		Background:Show()
	end)

	hooksecurefunc(Indicator, 'Hide', function()
		Background:Hide()
	end)

	return Indicator
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

	self:RegisterEvent('UNIT_HEAL_PREDICTION', UpdateHealth)
	self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', UpdateHealth)
	self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', UpdateHealth)

	local IncomingHeal = self:CreateTexture(nil, 'ARTWORK', nil, 1)
	IncomingHeal:SetPoint('TOPLEFT', Health, 1, -1)
	IncomingHeal:SetPoint('BOTTOMLEFT', Health, 1, 1)
	IncomingHeal:SetPoint('RIGHT', Health, 'LEFT')
	IncomingHeal:SetColorTexture(0, 0, 0, 3/5)
	self.IncomingHeal = IncomingHeal

	local Absorbs = self:CreateTexture()
	Absorbs:SetPoint('TOPLEFT', Health)
	Absorbs:SetPoint('BOTTOMLEFT', Health)
	Absorbs:SetPoint('RIGHT', Health, 'LEFT')
	Absorbs:SetColorTexture(0, 3/5, 4/5, 1)
	self.Absorbs = Absorbs

	local AbsorbBorder = self:CreateTexture(nil, 'ARTWORK', nil, 1)
	AbsorbBorder:SetPoint('TOPRIGHT', Absorbs)
	AbsorbBorder:SetPoint('BOTTOMRIGHT', Absorbs)
	AbsorbBorder:SetWidth(1)
	AbsorbBorder:SetColorTexture(1, 1, 1)
	self.AbsorbsBorder = AbsorbBorder

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

	local RaidIcon = self:CreateTexture(nil, 'OVERLAY')
	RaidIcon:SetPoint('TOP', 0, 4)
	RaidIcon:SetSize(12, 12)
	self.RaidIcon = RaidIcon

	local Threat = CreateIndicator(self, 4)
	Threat:SetPoint('TOPRIGHT', -3, -3)
	self.Threat = Threat

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 1/5
	}
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
