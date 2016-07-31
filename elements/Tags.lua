local tags = select(2, ...).oUF.Tags

local events = {
	shield = 'UNIT_AURA',
	threat = 'UNIT_THREAT_LIST_UPDATE',
	riptide = 'UNIT_AURA',
	leader = 'PARTY_LEADER_CHANGED',
	name = 'UNIT_NAME_UPDATE',
}

for tag, method in next, {
	shield = function(unit)
		local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Earth Shield')
		return caster == 'player' and '|cff00ff00.|r'
	end,
	threat = function(unit)
		local status = UnitThreatSituation(unit)
		if(status and status > 0) then
			return ('%s.|r'):format(Hex(GetThreatStatusColor(status)))
		end
	end,
	riptide = function(unit)
		local _, _, _, _, _, _, _, caster = UnitAura(unit, 'Riptide')
		return caster == 'player' and '|cff0090ff.|r'
	end,
	leader = function(unit)
		return UnitIsPartyLeader(unit) and '|cffffff00!|r'
	end,
	health = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		if(UnitIsDeadOrGhost(unit)) then
			return '|cffff0000X|r'
		elseif(not UnitIsConnected(unit)) then
			return '|cff333333#|r'
		elseif(min / max < 0.8) then
			return ('|cffff8080%.1f|r'):format((max - min) / 1e3)
		end
	end,
	name = function(unit, realUnit)
		local _, class = UnitClass(realUnit or unit)
		local colors = _COLORS.class
		return ('%s%s|r%s'):format(Hex(colors[class] or colors['WARRIOR']), UnitName(realUnit or unit), realUnit and '*' or '')
	end,
} do
	tags.Methods['kritt:' .. tag] = method
	tags.Events['kritt:' .. tag] = events[tag]
end
