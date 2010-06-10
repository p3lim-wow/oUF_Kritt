local _, module = ...

local dispel = {
	Poison = true,
	Disease = true,
	Curse = true,
}

local blacklist = {
	[GetSpellInfo(70311)] = true, -- Mutated Abo @ Putricide
}

local function UNIT_AURA(self, event, unit)
	if(self.unit ~= unit) then return end

	for index = 1, 40 do
		local name, _, _, _, type = UnitAura(unit, index, 'HARMFUL')

		if(name and dispel[type] and not blacklist[name]) then
			local color = DebuffTypeColor[type]
			return self:SetBackdropBorderColor(color.r, color.g, color.b)
		end
	end

	self:SetBackdropBorderColor(0, 0, 0)
end

function module.Dispel(self)
	self:SetAttribute('type3', 'spell')
	self:SetAttribute('spell', GetSpellInfo(51886))
	self:RegisterEvent('UNIT_AURA', UNIT_AURA)
end

