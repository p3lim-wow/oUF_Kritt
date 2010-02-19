local _, ns = ...

local debuffList = {
	['Trial of the Crusader'] = {
		-- Beasts of Northrend
		[66331] = true, -- Impale (Gormok)
		[67475] = true, -- Fire Bomb (Gormok)
		[67618] = true, -- Paralytic Toxin (Jormungar)

		-- Lord Jaraxxus
		[66237] = true, -- Incinerate Flesh
		[66197] = true, -- Legion Flame

		-- Twin Val'kyr
		[66075] = true, -- Twin Spike

		-- Anub'arak
		[67700] = true, -- Penetrating Cold
		[66012] = true, -- Freezing Slash
	},
	['Icecrown Citadel'] = {
		-- Lord Marrowgar
		[69065] = true, -- Impaled

		-- Deathbringer Saurfang
		[72293] = true, -- Mark of the Fallen Champion

		-- Professor Putricide
		[70215] = true, -- Gaseous Bloat (Orange Ooze)
		[72454] = true, -- Volatile Ooze Adhesive (Green Ooze)

		-- Blood Princes
		[72796] = true, -- Glittering Sparks (Taldaram)
		[71822] = true, -- Shadow Resonance (Keleseth)
	},
}

local addon = CreateFrame('Frame')
addon:RegisterEvent('RAID_INSTANCE_WELCOME')
addon:SetScript('OnEvent', function(self, event, name)
	ns = {}

	for k, v in pairs(debuffList) do
		if(string.find(name, k)) then
			ns = v
		end
	end
end)
