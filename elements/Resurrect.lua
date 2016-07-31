local _, ns = ...
local oUF = ns.oUF or oUF
local elementName = 'oUF Resurrect'
assert(oUF, elementName .. ' was unable to locate oUF install')

local LRI = LibStub('LibResInfo-1.0', true)
assert(LRI, elementName .. ' requires LibResInfo-1.0')

local function Update(self, event, unit)
	if(unit ~= self.unit) then
		return
	end

	local element = self.Resurrect
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local status, endTime, casterUnit = LRI:UnitHasIncomingRes(unit)
	if(status) then
		if(status == 'CASTING' or status == 'MASSRES') then
			element:SetVertexColor(1, 1, 1)
		elseif(status == 'SELFRES') then
			element:SetVertexColor(1, 3/5, 0)
		else
			element:SetVertexColor(1/9, 1/2, 1)
		end

		element:Show()
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(status, endTime, casterUnit)
	end
end

local function Path(self, ...)
	return (self.Resurrect.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	local parent = element.__owner
	return Path(parent, 'ForceUpdate', parent.unit)
end

local function Enable(self)
	local element = self.Resurrect
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.Resurrect
	if(element) then
		element:Hide()
		-- TODO: kill callbacks
	end
end

oUF:AddElement('Resurrect', Path, Enable, Disable)

LRI.RegisterAllCallbacks(elementName, function(event)
	for index = 1, #oUF.objects do
		local frame = oUF.objects[index]
		if(frame.unit and frame.Resurrect) then
			Path(frame, event, frame.unit)
		end
	end
end, true)
