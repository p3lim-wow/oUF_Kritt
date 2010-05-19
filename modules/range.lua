local _, module = ...

local function InRange(unit)
	return UnitIsConnected(unit) and not UnitIsDead(unit) and IsSpellInRange('Healing Wave', unit) == 1
end

local function OnUpdate(self, elapsed)
	if((self.elapsed or 1) > 0.2) then
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

function module.Range(self)
	CreateFrame('Frame', nil, self):SetScript('OnUpdate', OnUpdate)
end
