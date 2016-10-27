local _, ns = ...
local buffWhitelist = ns.buffs

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
	local visibility = false

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

local function PostUpdatePower(element, unit, cur, max)
	if(unit == 'PLAYER_REGEN_ENABLED' or unit == 'PLAYER_REGEN_DISABLED' or event == 'UNIT_FLAGS') then
		unit = element.unit
		element = element.Power
		cur, max = UnitPower(unit), UnitPowerMax(unit)
	end

	element:GetParent():SetAlpha((max ~= 0 and UnitAffectingCombat(unit) or (cur ~= 0 and cur ~= max)) and 1 or 0)
end

local function PostUpdateTotem(element)
	local shown = {}
	for index = 1, MAX_TOTEMS do
		local Totem = element[index]
		if(Totem:IsShown()) then
			local prevShown = shown[#shown]

			Totem:ClearAllPoints()
			Totem:SetPoint('TOPLEFT', shown[#shown] or element.__owner, 'TOPRIGHT', 4, -1)
			table.insert(shown, Totem)
		end
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

local function PostCreateGroupAura(element, Button)
	Button.cd:SetReverse(true)
	Button.cd:SetHideCountdownNumbers(true)
	Button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Button.icon:SetDrawLayer('ARTWORK')
end

local function OnUpdateAura(self, elapsed)
	if(self.expiration) then
		self.expiration = math.max(self.expiration - elapsed, 0)

		if(self.expiration > 0 and self.expiration < 60) then
			self.Duration:SetFormattedText('%d', self.expiration)
		else
			self.Duration:SetText()
		end
	end
end

local function PostCreateAura(element, Button)
	Button.cd:SetReverse(true)
	Button.cd:SetHideCountdownNumbers(true)

	Button:SetBackdrop(BACKDROP)
	Button:SetBackdropBorderColor(0, 0, 0)

	Button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Button.icon:SetDrawLayer('ARTWORK')
	Button.icon:ClearAllPoints()
	Button.icon:SetPoint('TOPLEFT', 1, -1)
	Button.icon:SetPoint('BOTTOMRIGHT', -1, 1)

	Button.count:ClearAllPoints()
	Button.count:SetPoint('BOTTOMRIGHT', Button, 2, 1)
	Button.count:SetFont(FONT, 8, 'OUTLINEMONOCHROME')

	local Duration = Button:CreateFontString()
	Duration:SetPoint('TOPLEFT', 0, -1)
	Duration:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
	Button.Duration = Duration

	Button:HookScript('OnUpdate', OnUpdateAura)
end

local function PostUpdateAura(element, unit, Button, index)
	local _, _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, Button.filter)

	if(duration and duration > 0) then
		Button.expiration = expiration - GetTime()
	else
		Button.expiration = math.huge
	end

	if(unit == 'target' and canStealOrPurge) then
		Button:SetBackdropBorderColor(0, 1/2, 1/2)
	elseif(owner ~= 'player') then
		Button:SetBackdropBorderColor(0, 0, 0)
	end
end

local function PostUpdateCast(element, unit)
	local Spark = element.Spark
	if(not element.interrupt and UnitCanAttack('player', unit)) then
		Spark:SetColorTexture(1, 0, 0)
	else
		Spark:SetColorTexture(1, 1, 1)
	end
end

local function FilterTargetDebuffs(...)
	local _, unit, _, _, _, _, _, _, _, _, owner, _, _, id = ...
	return owner == 'player' or owner == 'vehicle' or UnitIsFriend('player', unit)
end

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

local function OnIndicatorShow(self)
	self.Background:Show()
end

local function OnIndicatorHide(self)
	self.Background:Hide()
end

local function CreateIndicator(self, size)
	local Indicator = self:CreateTexture(nil, 'OVERLAY')
	Indicator:SetSize(size, size)
	Indicator:SetTexture(TEXTURE)

	local Background = self:CreateTexture()
	Background:SetPoint('CENTER', Indicator)
	Background:SetSize(size + 2, size + 2)
	Background:SetColorTexture(0, 0, 0)
	Indicator.Background = Background

	hooksecurefunc(Indicator, 'Show', OnIndicatorShow)
	hooksecurefunc(Indicator, 'Hide', OnIndicatorHide)

	return Indicator
end

local UnitSpecific = {
	player = function(self, unit)
		local PowerPrediction = CreateFrame('StatusBar', nil, self.Power)
		PowerPrediction:SetPoint('RIGHT', self.Power:GetStatusBarTexture())
		PowerPrediction:SetPoint('BOTTOM')
		PowerPrediction:SetPoint('TOP')
		PowerPrediction:SetWidth(230)
		PowerPrediction:SetStatusBarTexture(TEXTURE)
		PowerPrediction:SetStatusBarColor(1, 0, 0)
		PowerPrediction:SetReverseFill(true)
		self.PowerPrediction = {
			mainBar = PowerPrediction
		}

		local PowerValue = self:CreateFontString()
		PowerValue:SetPoint('LEFT', 4, 0)
		PowerValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		PowerValue:SetJustifyH('LEFT')
		PowerValue:SetWordWrap(false)
		self:Tag(PowerValue, '[powercolor][kritt:curpp]|r[ |cff0090ff>kritt:addpp<%|r][ : >kritt:cast]')

		local Debuffs = CreateFrame('Frame', nil, self)
		Debuffs:SetPoint('TOPRIGHT', self, 'TOPLEFT', -3, 0)
		Debuffs.size = self:GetHeight()
		Debuffs:SetSize(self:GetWidth() / 2, Debuffs.size)
		Debuffs.spacing = 3
		Debuffs.initialAnchor = 'TOPRIGHT'
		Debuffs['growth-x'] = 'LEFT'
		Debuffs.PostCreateIcon = PostCreateAura
		Debuffs.PostUpdateIcon = PostUpdateAura
		self.Debuffs = Debuffs

		local Totems = {}
		Totems.PostUpdate = PostUpdateTotem

		for index = 1, MAX_TOTEMS do
			local Totem = CreateFrame('Button', nil, self)
			Totem:SetSize(20, 20)

			local Icon = Totem:CreateTexture(nil, 'OVERLAY')
			Icon:SetAllPoints()
			Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			Totem.Icon = Icon

			local Background = Totem:CreateTexture(nil, 'BORDER')
			Background:SetPoint('TOPLEFT', -1, 1)
			Background:SetPoint('BOTTOMRIGHT', 1, -1)
			Background:SetColorTexture(0, 0, 0)

			local Cooldown = CreateFrame('Cooldown', nil, Totem, 'CooldownFrameTemplate')
			Cooldown:SetAllPoints()
			Cooldown:SetReverse(true)
			Totem.Cooldown = Cooldown

			Totems[index] = Totem
		end
		self.Totems = Totems

		self:Tag(self.HealthValue, '[kritt:status][kritt:maxhp][|cffff8080->kritt:defhp<|r][ >kritt:perhp<|cff0090ff%|r]')
	end,
	target = function(self, unit)
		local Buffs = CreateFrame('Frame', nil, self)
		Buffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 3, 0)
		Buffs.size = self:GetHeight()
		Buffs:SetSize(self:GetWidth() / 2, Buffs.size)
		Buffs.num = 27
		Buffs.spacing = 3
		Buffs.initialAnchor = 'TOPLEFT'
		Buffs['growth-y'] = 'DOWN'
		Buffs.PostCreateIcon = PostCreateAura
		Buffs.PostUpdateIcon = PostUpdateAura
		self.Buffs = Buffs

		local Debuffs = CreateFrame('Frame', nil, self)
		Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 3)
		Debuffs.size = self:GetHeight()
		Debuffs:SetSize(self:GetWidth(), Debuffs.size)
		Debuffs.spacing = 3
		Debuffs.initialAnchor = 'BOTTOMLEFT'
		Debuffs['growth-y'] = 'UP'
		Debuffs.PostCreateIcon = PostCreateAura
		Debuffs.PostUpdateIcon = PostUpdateAura
		Debuffs.CustomFilter = FilterTargetDebuffs
		self.Debuffs = Debuffs

		self.Castbar.PostCastStart = PostUpdateCast
		self.Castbar.PostCastInterruptible = PostUpdateCast
		self.Castbar.PostCastNotInterruptible = PostUpdateCast
		self.Castbar.PostChannelStart = PostUpdateCast

		self:Tag(self.HealthValue, '[kritt:status][kritt:curhp][ >kritt:targethp]')
		self:Tag(self.Name, '[kritt:name]')
	end,
	targettarget = function(self, unit)
		self:SetSize(150, 18)
		self:Tag(self.Name, '[kritt:name]')
	end,
	party = function(self, unit)
		local Power = self.Power
		Power:SetPoint('BOTTOMLEFT', 1, 1)
		Power:SetPoint('BOTTOMRIGHT', -1, 1)
		Power:SetHeight(1)
		Power:SetStatusBarColor(unpack(self.colors.power.MANA))
		Power.Override = UpdatePower

		local HealthValue = self:CreateFontString()
		HealthValue:SetPoint('RIGHT', -2, 0)
		HealthValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		HealthValue:SetJustifyH('RIGHT')
		HealthValue:SetWordWrap(false)
		self:Tag(HealthValue, '[kritt:grouphp]')

		if(self:GetAttribute('healerLayout')) then
			local Buffs = CreateFrame('Frame', nil, self)
			Buffs:SetPoint('TOPLEFT', 2, -2)
			Buffs:SetSize(85, 10)
			Buffs.size = 10
			Buffs.num = 7
			Buffs.spacing = 3
			Buffs.PostCreateIcon = PostCreateGroupAura
			Buffs.CustomFilter = FilterBuffs
			self.Buffs = Buffs

			local Debuffs = CreateFrame('Frame', nil, self)
			Debuffs:SetPoint('BOTTOMLEFT', 2, 2)
			Debuffs:SetSize(85, 10)
			Debuffs.size = 10
			Debuffs.num = 7
			Debuffs.spacing = 3
			Debuffs.PostCreateIcon = PostCreateGroupAura
			Debuffs.CustomFilter = FilterDebuffs
			self.Debuffs = Debuffs
		end

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

		self.Name:SetPoint('RIGHT', HealthValue, 'LEFT', -2, 0)
		self:Tag(self.Name, '[kritt:leader][raidcolor][name<|r]')
	end
}
UnitSpecific.raid = UnitSpecific.party

oUF:RegisterStyle('Kritt', function(self, unit)
	unit = unit:match('(boss)%d?$') or unit:match('(arena)%d?$') or unit

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

	local Power = CreateFrame('StatusBar', nil, self)
	Power:SetStatusBarTexture(TEXTURE)
	self.Power = Power

	local RaidIcon = self:CreateTexture(nil, 'OVERLAY')
	RaidIcon:SetPoint('TOP', 0, 4)
	RaidIcon:SetSize(12, 12)
	self.RaidIcon = RaidIcon

	local Threat = CreateIndicator(self, 4)
	Threat:SetPoint('TOPRIGHT', -3, -3)
	self.Threat = Threat

	if(unit ~= 'player') then
		local Name = self:CreateFontString()
		Name:SetPoint('LEFT', 4, 0)
		Name:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		Name:SetJustifyH('LEFT')
		Name:SetWordWrap(false)
		self.Name = Name
	end

	if(unit == 'player' or unit == 'target') then
		self:SetSize(250, 22)

		local HealthValue = self:CreateFontString()
		HealthValue:SetPoint('RIGHT', -4, 0)
		HealthValue:SetFont(FONT, 8, 'OUTLINEMONOCHROME')
		HealthValue:SetJustifyH('RIGHT')
		self.HealthValue = HealthValue

		local PowerParent = CreateFrame('Frame', nil, self)
		PowerParent:SetPoint('TOP', self, 'BOTTOM', 0, -3)
		PowerParent:SetSize(self:GetWidth(), 4)
		PowerParent:SetBackdrop(BACKDROP)
		PowerParent:SetBackdropColor(0, 0, 0, 1/2)
		PowerParent:SetBackdropBorderColor(0, 0, 0)

		Power:SetParent(PowerParent)
		Power:SetPoint('TOPLEFT', PowerParent, 1, -1)
		Power:SetPoint('BOTTOMRIGHT', PowerParent, -1, 1)
		Power.PostUpdate = PostUpdatePower
		Power.frequentUpdates = true
		Power.colorClass = true
		Power.colorTapping = true
		Power.colorDisconnected = true
		Power.colorReaction = true

		self:RegisterEvent('UNIT_FLAGS', PostUpdatePower)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', PostUpdatePower)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', PostUpdatePower)

		local Castbar = CreateFrame('StatusBar', nil, self)
		Castbar:SetAllPoints()
		Castbar:SetStatusBarTexture(TEXTURE)
		Castbar:SetStatusBarColor(0, 0, 0, 0)
		Castbar:SetFrameStrata('HIGH')
		self.Castbar = Castbar

		local Spark = Castbar:CreateTexture(nil, 'OVERLAY')
		Spark:SetSize(2, self:GetHeight() - 2)
		Spark:SetColorTexture(1, 1, 1)
		Castbar.Spark = Spark
	end

	if(self:GetAttribute('healerLayout')) then
		-- Binds whatever dispel ability the class/spec provides to middle mouse button
		self:SetAttribute('type3', 'macro')
		self:SetAttribute('macrotext', clickMacro)
	end

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end)

oUF:SetActiveStyle('Kritt')

oUF:Spawn('player'):SetPoint('CENTER', -300, -250)
oUF:Spawn('target'):SetPoint('CENTER', 300, -250)
oUF:Spawn('targettarget'):SetPoint('TOPRIGHT', oUF_KrittTarget, 'BOTTOMRIGHT', 0, -5)

oUF:SpawnHeader('oUF_KrittHealerRaid', nil, nil,
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
	'healerLayout', true,
	'oUF-initialConfigFunction', [[
		self:SetWidth(90)
		self:SetHeight(35)
	]]
):SetPoint('RIGHT', UIParent, 'LEFT', 776, -100)

oUF:SpawnHeader(nil, nil, nil,
	'showPlayer', true,
	'showParty', true,
	'showRaid', true,
	'yOffset', -5,
	'groupBy', 'ASSIGNEDROLE',
	'groupingOrder', 'TANK,HEALER,DAMAGER',
	'oUF-initialConfigFunction', [[
		self:SetWidth(126)
		self:SetHeight(20)
	]]
):SetPoint('TOP', Minimap, 'BOTTOM', 0, -10)

local visibilityConditions = '[group:raid,nogroup:party] show; [group:party] show; hide'

local Handler = CreateFrame('Frame')
Handler:RegisterEvent('PLAYER_TALENT_UPDATE')
Handler:SetScript('OnEvent', function()
	if(InCombatLockdown()) then
		return
	end

	if(GetSpecializationRole(GetSpecialization() or 0) == 'HEALER') then
		RegisterAttributeDriver(oUF_KrittRaid, 'state-visibility', 'hide')
		RegisterAttributeDriver(oUF_KrittHealerRaid, 'state-visibility', visibilityConditions)
	else
		RegisterAttributeDriver(oUF_KrittRaid, 'state-visibility', visibilityConditions)
		RegisterAttributeDriver(oUF_KrittHealerRaid, 'state-visibility', 'hide')
	end
end)
