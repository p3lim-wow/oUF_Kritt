local FONT = [=[Interface\AddOns\oUF_Kritt\semplice.ttf]=]
local TEXTURE = [=[Interface\ChatFrame\ChatFrameBackground]=]

oUF.TagEvents['kritt:shield'] = 'UNIT_AURA'
oUF.Tags['kritt:shield'] = function(unit)
	local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Earth Shield')
	return caster == 'player' and '|cff00ff00.|r'
end

oUF.TagEvents['kritt:riptide'] = 'UNIT_AURA'
oUF.Tags['kritt:riptide'] = function(unit)
	local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Riptide')
	return caster == 'player' and '|cff0090ff.|r'
end

oUF.TagEvents['kritt:leader'] = 'PARTY_LEADER_CHANGED'
oUF.Tags['kritt:leader'] = function(unit)
	return UnitIsPartyLeader(unit) and '|cffffff00!|r'
end

oUF.Tags['kritt:health'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(UnitIsDeadOrGhost(unit)) then
		return '|cffff0000X|r'
	elseif(not UnitIsConnected(unit)) then
		return '|cff333333#|r'
	elseif(min / max < 0.8) then
		return ('|cffff8080%.1f|r'):format((max - min) / 1e3)
	end
end

oUF.TagEvents['kritt:name'] = 'UNIT_NAME_UPDATE'
oUF.Tags['kritt:name'] = function(unit, realUnit)
	local _, class = UnitClass(realUnit or unit)
	local colors = _COLORS.class
	return ('%s%s|r%s'):format(Hex(colors[class] or colors['WARRIOR']), UnitName(realUnit or unit), realUnit and '*' or '')
end

local function InRange(unit)
	return UnitIsConnected(unit) and not UnitIsDead(unit) and IsSpellInRange('Healing Wave', unit) == 1
end

local function RangeUpdate(self, elapsed)
	if((self.elapsed or 0) > 0.2) then
		local frame = self:GetParent()
		if(frame:IsVisible()) then
			local range = not not InRange(frame.unit)
			frame:SetAlpha(range and 1 or 0.2)
		end

		self.elapsed = 0
	else
		self.elapsed = (self.elapsed or 0) + elapsed
	end
end

local function UpdateHealth(self, event, unit)
	if(self.unit ~= unit) then return end
	local health = self.health

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	health:SetPoint('LEFT', 74 * (min / max), 0)
	health:SetVertexColor(self.ColorGradient(min / max, unpack(self.colors.smooth)))
end

local function style(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetAttribute('initial-height', 23)
	self:SetAttribute('initial-width', 75)

	self:SetBackdrop({bgFile =	TEXTURE, edgeFile = TEXTURE, edgeSize = 1})
	self:SetBackdropColor(0, 0, 0, 0.5)
	self:SetBackdropBorderColor(0, 0, 0, 0.6)

	local bg = self:CreateTexture(nil, 'BACKGROUND')
	bg:SetPoint('TOPLEFT', 1, -1)
	bg:SetPoint('BOTTOMRIGHT', -1, 1)
	bg:SetTexture(1, 1, 1, 0.05)

	local health = self:CreateTexture(nil, 'BORDER')
	health:SetTexture(0.6, 0.6, 0.6)
	health:SetPoint('TOPRIGHT', -1, -1)
	health:SetPoint('BOTTOMRIGHT', -1, 1)
	health:SetPoint('LEFT', 75, 0)

	self:RegisterEvent('UNIT_HEALTH', UpdateHealth)
	self:RegisterEvent('UNIT_HEALTHMAX', UpdateHealth)
	self.health = health

	local healcomm = self:CreateTexture(nil, 'ARTWORK')
	healcomm:SetTexture(0, 0, 0, 0.6)
	healcomm:SetPoint('TOPLEFT', health, 1, -1)
	healcomm:SetPoint('BOTTOMLEFT', health, 1, 1)
	healcomm:SetPoint('RIGHT', health, 'LEFT')
	self.HealComm = healcomm

	local missing = self:CreateFontString(nil, 'ARTWORK')
	missing:SetPoint('RIGHT', -2, 0)
	missing:SetFont(FONT, 8, 'OUTLINE')
	missing:SetJustifyH('RIGHT')
	missing.frequentUpdates = true
	self:Tag(missing, '[kritt:health]')

	local name = self:CreateFontString(nil, 'ARTWORK')
	name:SetPoint('LEFT', 4, 0)
	name:SetPoint('RIGHT', missing, 'LEFT', -2, 0)
	name:SetFont(FONT, 8, 'OUTLINE')
	name:SetJustifyH('LEFT')
	self:Tag(name, '[kritt:leader][kritt:name]')

	local shield = self:CreateFontString(nil, 'ARTWORK')
	shield:SetPoint('TOPLEFT', -3, 16)
	shield:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	self:Tag(shield, '[kritt:shield]')

	local riptide = self:CreateFontString(nil, 'ARTWORK')
	riptide:SetPoint('BOTTOMLEFT', -3, -2)
	riptide:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	self:Tag(riptide, '[kritt:riptide]')

	CreateFrame('Frame', nil, self):SetScript('OnUpdate', RangeUpdate)
end

oUF:RegisterStyle('Kritt', style)
oUF:SetActiveStyle('Kritt')

local group = oUF:SpawnHeader(nil, nil, 'raid,party',
	'showPlayer', true,
	'showParty', true,
	'showRaid', true,
	'yOffset', -5,
	'point', 'TOP',
	'groupingOrder', '1,2,3,4,5',
	'groupBy', 'GROUP',
	'maxColumns', 5,
	'unitsPerColumn', 5,
	'columnSpacing', 5,
	'columnAnchorPoint', 'RIGHT'
)
group:SetPoint('RIGHT', UIParent, 'CENTER', -200, -100)
