local tags = select(2, ...).oUF.Tags

local events = {
	leader = 'PARTY_LEADER_CHANGED',
	health = 'UNIT_HEALTH UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION'
}

local format = string.format

for tag, method in next, {
	leader = function(unit)
		return UnitIsGroupLeader(unit) and '|cffffff00!|r'
	end,
	health = function(unit)
		if(UnitIsDeadOrGhost(unit)) then
			return '|cffff0000X|r'
		elseif(not UnitIsConnected(unit)) then
			return '|cff333333#|r'
		else
			local cur, max = UnitHealth(unit), UnitHealthMax(unit)
			if(cur / max < 0.8) then
				return format('|cffff8080%.1f|r', (max - cur) / 1e3)
			end
		end
	end,
} do
	tags.Methods['kritt:' .. tag] = method
	tags.Events['kritt:' .. tag] = events[tag]
end
