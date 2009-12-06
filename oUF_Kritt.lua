local objects = {}
local debuffList = {
	-- Koralon the Flame Watcher
	[GetSpellInfo(67332)] = true -- Flaming Cinder

	-- Beast of Northrend
	[GetSpellInfo(66331)] = true, -- Impale
	[GetSpellInfo(67475)] = true, -- Fire Bomb (Gormok)
	[GetSpellInfo(66406)] = true, -- Snobolled! (Gormok)
	[GetSpellInfo(67618)] = true, -- Paralytic Toxin (Jormungar)

	-- Lord Jaraxxus
	[GetSpellInfo(66237)] = true, -- Incinerate Flesh
	[GetSpellInfo(66197)] = true, -- Legion Flame

	-- Twin Val'kyr
	[GetSpellInfo(66075)] = true, -- Twin Spike

	-- Anub'arak
	[GetSpellInfo(67700)] = true, -- Penetrating Cold
	[GetSpellInfo(66012)] = true, -- Freezing Slash
}

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
	return UnitIsDead(unit) and '|cffff0000X|r' or not UnitIsConnected(unit) and '|cff333333#|r' or min / max < 0.8 and string.format('|cffff8080%.1f|r', (max - min) / 1e3)
end

local function updateHealth(self)
	local min, max = UnitHealth(self.unit), UnitHealthMax(self.unit)
	self.health:SetPoint('LEFT', 74 * (min / max), 0)
	self.health:SetVertexColor(self.ColorGradient(min / max, unpack(self.colors.smooth)))
end

local function postCreateAura(self, button, icons)
	button:EnableMouse(false)
	button:SetAlpha(0.75)
	button.cd:SetReverse()
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.overlay:SetTexture()
end

local function customAuraFilter(icons, unit, icon, name)
	return debuffList[name]
end

local function style(self, unit)
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetAttribute('initial-height', 23)
	self:SetAttribute('initial-width', 75)
	self:SetAttribute('toggleForVehicle', true)

	self:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=], edgeSize = 1})
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
	self:RegisterEvent('UNIT_HEALTH', updateHealth)
	self:RegisterEvent('UNIT_HEALTHMAX', updateHealth)
	self.health = health

	local missing = self:CreateFontString(nil, 'ARTWORK', 'pfont')
	missing:SetPoint('RIGHT', -2, 0)
	missing:SetJustifyH('RIGHT')
	missing.frequentUpdates = true
	self:Tag(missing, '[kritthp]')

	local name = self:CreateFontString(nil, 'ARTWORK', 'pfont')
	name:SetPoint('LEFT', 4, 0)
	name:SetPoint('RIGHT', missing, 'LEFT', -2, 0)
	name:SetJustifyH('LEFT')
	self:Tag(name, '[krittleader][raidcolor][name]')

	local shield = self:CreateFontString(nil, 'ARTWORK')
	shield:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	shield:SetPoint('TOPLEFT', -3, 16)
	self:Tag(shield, '[krittshield]')

	local riptide = self:CreateFontString(nil, 'ARTWORK')
	riptide:SetFont([=[Fonts\FRIZQT__.TTF]=], 25, 'OUTLINE')
	riptide:SetPoint('BOTTOMLEFT', -3, -2)
	self:Tag(riptide, '[krittriptide]')

	self.Debuffs = CreateFrame('Frame', nil, self)
	self.Debuffs:SetPoint('CENTER')
	self.Debuffs:SetHeight(16)
	self.Debuffs:SetWidth(16)
	self.Debuffs.num = 1
	self.Debuffs.size = 16
	self.PostCreateAuraIcon = postCreateAura
	self.CustomAuraFilter = customAuraFilter

	self.DebuffHighlightBackdropBorder = true
	self.DebuffHighlightFilter = true
	self.DebuffHighlightAlpha = 0.6

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

--[[ Range/condition fading ]]
local function InRange(unit)
	return UnitIsConnected(unit) and not UnitIsDead(unit) and IsSpellInRange('Healing Wave', unit) == 1
end

local dummy = CreateFrame('Frame')
dummy.elapsed = 0
dummy:SetScript('OnUpdate', function(self, elapsed)
	if(self.elapsed > 0.2) then
		for object in pairs(objects) do
			if(object:IsVisible()) then
				local range = not not InRange(object.unit)
				object:SetAlpha(range and 1 or 0.2)
			end
		end

		self.elapsed = 0
	else
		self.elapsed = self.elapsed + elapsed
	end
end)
