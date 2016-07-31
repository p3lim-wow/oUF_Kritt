local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF DebuffHighlight was unable to locate oUF install')

local playerClass = select(2, UnitClass('player'))
local dispelTypes = {}

-- Use something more vibrant than DebuffTypeColor
oUF.colors.debuffType = {
	Curse = {0.8, 0, 1},
	Disease = {0.8, 0.6, 0},
	Magic = {0, 0.8, 1},
	Poison = {0, 0.8, 0},
	none = {0, 0, 0}
}

local function Update(self, event, unit)
	if(unit ~= self.unit) then
		return
	end

	if(self.PreUpdateDebuffHighlight) then
		self:PreUpdateDebuffHighlight()
	end

	local debuffType, removable
	if(UnitCanCooperate('player', unit)) then
		for index = 1, 40 do
			local _, _, _, _, type = UnitAura(unit, index, 'HARMFUL')
			if(type) then
				debuffType = type
				removable = dispelTypes[type]
			end
		end
	end

	local color = self.colors.debuffType[removable and debuffType or 'none']
	local target = self.__highlightTarget
	target[self.__highlightMethod](target, color[1], color[2], color[3], color[4] or 1)

	if(self.PostUpdateDebuffHighlight) then
		return self:PostUpdateDebuffHighlight(debuffType, removable)
	end
end

local function Path(self, ...)
	return (self.OverrideDebuffHighlight or Update)(self, ...)
end

local function Enable(self)
	if(self.DebuffHighlight) then
		if(self.DebuffHighlight:IsObjectType('Texture')) then
			if(self.DebuffHighlight:GetTexture()) then
				self.__highlightMethod = 'SetVertexColor'
			else
				self.__highlightMethod = 'SetColorTexture'
			end

			self.__highlightTarget = self.DebuffHighlight
		else
			self.__highlightMethod = 'SetBackdropColor'
			self.__highlightTarget = self
		end
	elseif(self.DebuffHighlightBorder) then
		self.__highlightMethod = 'SetBackdropBorderColor'
		self.__highlightTarget = self
	end

	if(self.__highlightMethod) then
		self:RegisterEvent('UNIT_AURA', Path)

		return true
	end
end

local function Disable(self)
	if(self.__highlightMethod) then
		self:UnregisterEvent('UNIT_AURA', Path)

		local color = self.colors.debuffType.none
		local target = self.__highlightTarget
		target[self.__highlightMethod](target, color[1], color[2], color[3], color[4] or 1)
	end
end

oUF:AddElement('DebuffHighlight', Path, Enable, Disable)

local Handler = CreateFrame('Frame')
Handler:RegisterEvent('SPELLS_CHANGED')
Handler:SetScript('OnEvent', function(self, event)
	table.wipe(dispelTypes)

	if(playerClass == 'DRUID') then
		dispelTypes.Magic = IsSpellKnown(88423)
		dispelTypes.Curse = dispelTypes.Magic or IsSpellKnown(2782)
		dispelTypes.Poison = dispelTypes.Curse
	elseif(playerClass == 'MONK') then
		dispelTypes.Magic = IsSpellKnown(115450)
		dispelTypes.Disease = dispelTypes.Disease or IsSpellKnown(218164)
		dispelTypes.Poison = dispelTypes.Disease
	elseif(playerClass == 'PALADIN') then
		dispelTypes.Magic = IsSpellKnown(4987)
		dispelTypes.Disease = dispelTypes.Magic or IsSpellKnown(213644)
		dispelTypes.Poison = dispelTypes.Disease
	elseif(playerClass == 'PRIEST') then
		dispelTypes.Magic = IsSpellKnown(527) or IsSpellKnown(32375)
		dispelTypes.Disease = dispelTypes.Magic or IsSpellKnown(213634)
	elseif(playerClass == 'SHAMAN') then
		dispelTypes.Magic = IsSpellKnown(77130)
		dispelTypes.Curse = dispelTypes.Magic or IsSpellKnown(51886)
	elseif(playerClass == 'WARLOCK') then
		dispelTypes.Magic = IsSpellKnown(111859) or IsSpellKnown(89808, true) or IsSpellKnown(115276, true)
	end
end)

