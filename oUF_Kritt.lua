local _, ns = ...
local oUF = ns.oUF

local FONT = [[Interface\AddOns\oUF_Kritt\assets\semplice.ttf]]
local TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BACKDROP = {
	bgFile = TEXTURE, edgeFile = TEXTURE, edgeSize = 1
}

local dispelAbilities = {
	PRIEST = 527, -- Discipline/Holy Priest - Purify
	PALADIN = 4987, -- Holy Paladin - Cleanse
	SHAMAN = 77130, -- Restoration Shaman - Purify Spirit
	DRUID = 88423, -- Restoration Druid - Nature's Cure
	MONK = 115450, -- Mistweaver Monk - Detox
}

local resurrectAbilities = {
	DRUID = 20484, -- Rebirth
	WARLOCK = 20707, -- Soulstone
	DEATH_KNIGHT = 46584, -- Raise Dead
}

local playerClass, clickMacro = (select(2, UnitClass('player')))
local resurrectAbility = resurrectAbilities[playerClass]
if(resurrectAbility) then
	clickMacro = string.format('/cast [@mouseover,dead] %s', GetSpellInfo(resurrectAbility))
end

local dispelAbility = dispelAbilities[playerClass]
if(dispelAbility) then
	local macro = string.format('/cast [@mouseover] %s', GetSpellInfo(dispelAbility))
	clickMacro = clickMacro and clickMacro .. '\n' .. macro or macro
end

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

local function UpdatePower(self, event, unit)
	if(unit ~= self.unit) then
		return
	end

	local element = self.Power
	local visibility

	if(UnitIsConnected(unit) and not UnitHasVehicleUI(unit)) then
		local role = UnitGroupRolesAssigned(unit)
		visibility = role == 'HEALER'
	end

	if(visibility) then
		element:SetMinMaxValues(0, UnitPowerMax(unit, SPELL_POWER_MANA))
		element:SetValue(UnitPower(unit, SPELL_POWER_MANA))
	end

	if(element.visibility ~= visibility) then
		element:SetShown(visibility)
		element:GetParent().Health:SetPoint('BOTTOMRIGHT', -1, visibility and 3 or 1)

		element.visibility = visibility
	end
end

local function UpdateRoleIcon(self)
	local element = self.LFDRole

	local role = UnitGroupRolesAssigned(self.unit)
	if(role == 'DAMAGER' or role == 'HEALER' or role == 'TANK') then
		element:SetTexCoord(GetTexCoordsForRoleSmall(role))
		element:Show()
	else
		element:Hide()
	end
end

local function UpdateRoleIconVisibility(self)
	self.LFDRole:SetAlpha(IsAltKeyDown() and not UnitAffectingCombat('player') and  1 or 0)
end

local function PostCreateAura(element, Button)
	Button.cd:SetReverse(true)
	Button.cd:SetHideCountdownNumbers(true)
	Button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Button.icon:SetDrawLayer('ARTWORK')
end

local buffWhitelist = {
	-- Paladin, Holy
	[1022] = true, -- Blessing of Protection
	[1044] = true, -- Blessing of Freedom
	[6940] = true, -- Blessing of Sacrifice
	[31821] = true, -- Aura Mastery
	[53563] = true, -- Beacon of Light
	[200025] = true, -- Talent: Beacon of Virtue
	[156910] = true, -- Talent: Beacon of Faith
	[223306] = true, -- Talent: Bestow Faith
	[200652] = true, -- Artifact: Tyr's Deliverance (HoT)
	[200654] = true, -- Artifact: Tyr's Deliverance (Healing Increase)
	[211210] = true, -- Artifact Trait: Protection of Tyr

	-- Priest, Holy
	[139] = true, -- Renew
	[41635] = true, -- Prayer of Mending
	[47788] = true, -- Guardian Spirit
	[64844] = true, -- Divine Hymn
	[77489] = true, -- Mastery: Echo of Light
	[214121] = true, -- Talent: Body and Mind
	[196816] = true, -- Artifact: Tranquil Light
	[196356] = true, -- Artifact Trait: Trust in the Light
	[208065] = true, -- Artifact Trait: Light of T'uure

	-- Priest, Discipline
	[17] = true, -- Power Word: Shield
	[33206] = true, --Pain Suppression
	[81782] = true, -- Power Word: Barrier
	[194384] = true, -- Atonement
	[152118] = true, -- Talent: Clarity of Will

	-- Shaman, Resto
	[61295] = true, -- Riptide
	[98007] = true, -- Spirit Link
	[208899] = true, -- Artifact Trait: Queen's Decree

	-- Druid, Resto
	[774] = true, -- Rejuvenation
	[8936] = true, -- Regrowth
	[33763] = true, -- Lifebloom
	[48438] = true, -- Wild Growth
	[48504] = true, -- Living Seed
	[102342] = true, -- Ironbark
	[102351] = true, -- Talent: Cenarion Ward (Trigger)
	[102352] = true, -- Talent: Cenarion Ward (HoT)
	[200389] = true, -- Talent: Cultivation
	[207386] = true, -- Talent: Spring Blossoms
	[155777] = true, -- Talent: Germination

	-- Monk, Mistweaver
	[119611] = true, -- Renewing Mist
	[115175] = true, -- Soothing Mist
	[191840] = true, -- Essence Font
	[124682] = true, -- Enveloping Mist
	[116849] = true, -- Life Cocoon
}

local function FilterBuffs(...)
	local _, _, _, _, _, _, _, _, _, _, caster, _, _, spellID = ...
	return caster == 'player' and buffWhitelist[spellID]
end

local debuffWhitelist = {
	[25771] = true, -- Forbearance (Paladin)
	[219521] = true, -- Shadow Covenant (Priest, Discipline)
}

local function FilterDebuffs(...)
	local _, _, _, _, _, _, _, _, _, _, caster, _, _, spellID = ...
	return not UnitIsPlayer(caster) or debuffWhitelist[spellID]
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

oUF:RegisterStyle('Kritt', function(self, unit)
	self.colors.power.MANA = {0, 144/255, 1}

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

	local Power = CreateFrame('StatusBar', nil, self)
	Power:SetPoint('BOTTOMLEFT', 1, 1)
	Power:SetPoint('BOTTOMRIGHT', -1, 1)
	Power:SetHeight(1)
	Power:SetStatusBarTexture(TEXTURE)
	Power:SetStatusBarColor(unpack(self.colors.power.MANA))
	Power.Override = UpdatePower
	self.Power = Power

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

	local Buffs = CreateFrame('Frame', nil, self)
	Buffs:SetPoint('TOPLEFT', 2, -2)
	Buffs:SetSize(85, 10)
	Buffs.size = 10
	Buffs.num = 7
	Buffs.spacing = 3
	Buffs.PostCreateIcon = PostCreateAura
	Buffs.CustomFilter = FilterBuffs
	self.Buffs = Buffs

	local Debuffs = CreateFrame('Frame', nil, self)
	Debuffs:SetPoint('BOTTOMLEFT', 2, 2)
	Debuffs:SetSize(85, 10)
	Debuffs.size = 10
	Debuffs.num = 7
	Debuffs.spacing = 3
	Debuffs.PostCreateIcon = PostCreateAura
	Debuffs.CustomFilter = FilterDebuffs
	self.Debuffs = Debuffs

	local Threat = CreateIndicator(self, 4)
	Threat:SetPoint('TOPRIGHT', -3, -3)
	self.Threat = Threat

	local RoleIcon = self:CreateTexture(nil, 'OVERLAY')
	RoleIcon:SetPoint('CENTER')
	RoleIcon:SetSize(20, 20)
	RoleIcon:SetTexture([[Interface\LFGFrame\LFGRole]])
	RoleIcon:SetAlpha(0)
	RoleIcon.Override = UpdateRoleIcon
	self.LFDRole = RoleIcon
	self:RegisterEvent('MODIFIER_STATE_CHANGED', UpdateRoleIconVisibility)

	local ReadyCheck = self:CreateTexture()
	ReadyCheck:SetPoint('TOPRIGHT', -1, -1)
	ReadyCheck:SetSize(12, 12)
	self.ReadyCheck = ReadyCheck

	local Resurrect = self:CreateTexture(nil, 'OVERLAY')
	Resurrect:SetPoint('RIGHT', -5, -1)
	Resurrect:SetSize(20, 20)
	self.Resurrect = Resurrect

	self.DispelHighlightBorder = true
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 1/5
	}

	-- Binds whatever dispel ability the class/spec provides to middle mouse button
	self:SetAttribute('type3', 'macro')
	self:SetAttribute('macrotext', clickMacro)
end)

oUF:SetActiveStyle('Kritt')
oUF:SpawnHeader(nil, nil, nil,
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

local visibilityConditions = '[group:raid,nogroup:party] show; [group:party] show; hide'

local Handler = CreateFrame('Frame')
Handler:RegisterEvent('PLAYER_TALENT_UPDATE')
Handler:SetScript('OnEvent', function()
	if(InCombatLockdown()) then
		return
	end

	if(GetSpecializationRole(GetSpecialization() or 0) == 'HEALER') then
		RegisterAttributeDriver(oUF_KrittRaid, 'state-visibility', visibilityConditions)
	else
		RegisterAttributeDriver(oUF_KrittRaid, 'state-visibility', 'hide')
	end
end)
