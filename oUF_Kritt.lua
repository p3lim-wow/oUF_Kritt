local objects = {}
do
	local function InRange(unit)
		return UnitIsConnected(unit) and not UnitIsDead(unit) and IsSpellInRange('Healing Wave', unit) == 1
	end

	local ELAPSED = 0
	CreateFrame('Frame'):SetScript('OnUpdate', function(self, elapsed)
		if(ELAPSED > 0.2) then
			for object in pairs(objects) do
				if(object:IsVisible()) then
					local range = not not InRange(object.unit)
					object:SetAlpha(range and 1 or 0.2)
				end
			end

			ELAPSED = 0
		else
			ELAPSED = ELAPSED + elapsed
		end
	end)
end

oUF.TagEvents['[krittshield]'] = 'UNIT_AURA'
oUF.Tags['[krittshield]'] = function(unit)
	local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Earth Shield')
	return caster == 'player' and '|cff00ff00.|r'
end

oUF.TagEvents['[krittriptide]'] = 'UNIT_AURA'
oUF.Tags['[krittriptide]'] = function(unit)
	local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Riptide')
	return caster == 'player' and '|cff0090ff.|r'
end

oUF.TagEvents['[krittleader]'] = 'PARTY_LEADER_CHANGED'
oUF.Tags['[krittleader]'] = function(unit)
	return UnitIsPartyLeader(unit) and '|cffffff00!|r'
end

oUF.Tags['[kritthp]'] = function(unit)
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	return UnitIsDead(unit) and '|cffff0000X|r' or min / max < 0.8 and string.format('|cffff8080%.1f|r', (max - min) / 1e3)
end

local function updateHealth(self, event, unit, bar, min, max)
	bar.bg:SetPoint('LEFT', 75 * (min / max), 0)
	bar.bg:SetVertexColor(self.ColorGradient(min / max, unpack(self.colors.smooth)))
end

local function style(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetAttribute('initial-height', 23)
	self:SetAttribute('initial-width', 75)
	self:SetAttribute('toggleForVehicle', true)

	self:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = {top = -1, bottom = -1, left = -1, right = -1}})
	self:SetBackdropColor(0, 0, 0, 0.5)

	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetAllPoints(self)
	self.Health:SetStatusBarTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
	self.Health:SetStatusBarColor(1, 1, 1, 0.05)

	self.Health.bg = self.Health:CreateTexture(nil, 'BACKGROUND')
	self.Health.bg:SetTexture(0.6, 0.6, 0.6)
	self.Health.bg:SetPoint('TOPRIGHT')
	self.Health.bg:SetPoint('BOTTOMRIGHT')
	self.Health.bg:SetPoint('LEFT')

	local health = self.Health:CreateFontString(nil, 'ARTWORK', 'pfont')
	health:SetPoint('RIGHT', -2, 0)
	health:SetJustifyH('RIGHT')
	health.frequentUpdates = true
	self:Tag(health, '[kritthp]')

	local name = self.Health:CreateFontString(nil, 'ARTWORK', 'pfont')
	name:SetPoint('LEFT', 3, 0)
	name:SetPoint('RIGHT', health, 'LEFT', -2, 0)
	name:SetJustifyH('LEFT')
	self:Tag(name, '[krittleader][raidcolor][name]')

	local shield = self.Health:CreateFontString(nil, 'ARTWORK')
	shield:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	shield:SetPoint('TOPLEFT', -3, 16)
	self:Tag(shield, '[krittshield]')

	local riptide = self.Health:CreateFontString(nil, 'ARTWORK')
	riptide:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	riptide:SetPoint('BOTTOMLEFT', -3, -2)
	self:Tag(riptide, '[krittriptide]')

	self.OverrideUpdateHealth = updateHealth

	objects[self] = true
end

oUF:RegisterStyle('Kritt', style)
oUF:SetActiveStyle('Kritt')

local group = oUF:Spawn('header', 'oUF_Kritt')
group:SetPoint('RIGHT', UIParent, 'CENTER', -200, -100)
group:SetManyAttributes(
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
group:Show()
