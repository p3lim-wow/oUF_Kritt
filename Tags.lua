local tags = select(2, ...).oUF.Tags

local gsub = string.gsub
local format = string.format
local floor = math.floor

local events = {
	leader = 'PARTY_LEADER_CHANGED',
	grouphp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION',
	curhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	defhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	maxhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	perhp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	targethp = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH',
	curpp = 'UNIT_POWER_FREQUENT UNIT_MAXPOWER',
	addpp = 'UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER',
	name = 'UNIT_SPELLCAST_START UNIT_SPELLCAST_STOP UNIT_SPELLCAST_CHANNEL_START UNIT_SPELLCAST_CHANNEL_STOP UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_CLASSIFICATION_CHANGED',
	cast = 'UNIT_SPELLCAST_START UNIT_SPELLCAST_STOP UNIT_SPELLCAST_CHANNEL_START UNIT_SPELLCAST_CHANNEL_STOP',
	color = 'UNIT_REACTION UNIT_FACTION',
	status = 'UNIT_CONNECTION UNIT_HEALTH',
}

local function Short(value)
	if(value >= 1e6) then
		return gsub(format('%.2fm', value / 1e6), '%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return gsub(format('%.1fk', value / 1e3), '%.?0+([km])$', '%1')
	else
		return value
	end
end

local function Status(unit)
	if(not UnitIsConnected(unit)) then
		return 'Offline'
	elseif(UnitIsGhost(unit)) then
		return 'Ghost'
	elseif(UnitIsDead(unit)) then
		return 'Dead'
	end
end

for tag, method in next, {
	leader = function(unit)
		return UnitIsGroupLeader(unit) and '|cffffff00!|r'
	end,
	grouphp = function(unit)
		if(UnitIsDeadOrGhost(unit)) then
			return '|cffff0000DEAD|r'
		elseif(not UnitIsConnected(unit)) then
			return '|cff666666OFF|r'
		else
			local cur, max = UnitHealth(unit), UnitHealthMax(unit)
			if(cur / max < 0.8) then
				return format('|cffff8080%.1f|r', (max - cur) / 1e3)
			end
		end
	end,
	curhp = function(unit)
		if(Status(unit)) then return end
		return Short(UnitHealth(unit))
	end,
	defhp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(cur ~= max) then
			return Short(max - cur)
		end
	end,
	maxhp = function(unit)
		if(Status(unit)) then return end

		local max = UnitHealthMax(unit)
		if(max == UnitHealth(unit)) then
			return Short(max)
		end
	end,
	perhp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(cur ~= max) then
			return floor(cur / max * 100)
		end
	end,
	targethp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitHealth(unit)
		local max = UnitHealthMax(unit)
		if(UnitCanAttack('player', unit)) then
			return format('(%d|cff0090ff%%|r)', cur / max * 100)
		elseif(cur ~= max) then
			return format('|cff0090ff/|r %s', Short(max))
		end
	end,
	curpp = function(unit)
		if(Status(unit)) then return end

		local cur = UnitPower(unit)
		if(cur > 0) then
			return Short(cur)
		end
	end,
	addpp = function(unit)
		local cur = UnitPower(unit, 0)
		local max = UnitPowerMax(unit, 0)
		if(UnitPowerType(unit) ~= 0 and cur ~= max) then
			return floor(cur / max * 100)
		end
	end,
	cast = function(unit)
		return UnitCastingInfo(unit) or UnitChannelInfo(unit)
	end,
	color = function(unit)
		local reaction = UnitReaction(unit, 'player')
		if(UnitIsTapDenied(unit) or not UnitIsConnected(unit)) then
			return '|cff999999'
		elseif(not UnitIsPlayer(unit) and reaction) then
			return Hex(_COLORS.reaction[reaction])
		elseif(UnitFactionGroup(unit) and UnitIsEnemy(unit, 'player') and UnitIsPVP(unit)) then
			return '|cffff0000'
		elseif(UnitIsPlayer(unit)) then
			return _TAGS['raidcolor'](unit)
		end
	end,
	name = function(unit)
		local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
		if(name) then
			local color = notInterruptible and 'ff9000' or 'ff0000'
			return format('|cff%s%s|r', color, name)
		end

		name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
		if(name) then
			local color = notInterruptible and 'ff9000' or 'ff0000'
			return format('|cff%s%s|r', color, name)
		end

		name = UnitName(unit)

		local color = _TAGS['kritt:color'](unit)
		name = color and format('%s%s|r', color, name) or name

		local rare = _TAGS['rare'](unit)
		return rare and format('%s |cff0090ff%s|r', name, rare) or name
	end,
	status = Status
} do
	tags.Methods['kritt:' .. tag] = method
	tags.Events['kritt:' .. tag] = events[tag]
end
