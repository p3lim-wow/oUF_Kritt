local tags = select(2, ...).oUF.Tags

local events = {
	leader = 'PARTY_LEADER_CHANGED',
	health = 'UNIT_HEALTH UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION'
}

for tag, method in next, {
	leader = function(unit)
		return UnitIsGroupLeader(unit) and '|cffffff00!|r'
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
} do
	tags.Methods['kritt:' .. tag] = method
	tags.Events['kritt:' .. tag] = events[tag]
end
