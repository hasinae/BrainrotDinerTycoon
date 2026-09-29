-- DataManager.lua
-- Shared data schema and utilities; actual DataStore calls live server-side.

local DataManager = {}

function DataManager.defaultData(userId)
	return {
		userId       = tostring(userId),
		restaurant   = {
			objects        = {},
			expansionLevel = 1,
			theme          = "default",
		},
		money        = {
			currentBalance = 500,
			totalEarned    = 0,
		},
		level        = 1,
		dishesServed = 0,
		employees    = {},
		cosmetics    = {
			unlockedThemes  = { "default" },
			equippedTheme   = "default",
			unlockedOutfits = {},
			equippedOutfit  = "",
			unlockedSkins   = {},
		},
		vip          = { active = false, expiresAt = 0 },
		battlePass   = { season = 0, tier = 0, purchased = false },
		lastLogin    = os.time(),
		premiumDishPack = false,
		claimedMilestones = {},
	}
end

-- Validate and fill missing keys when loading old saves
function DataManager.migrate(data, userId)
	local default = DataManager.defaultData(userId)
	for k, v in pairs(default) do
		if data[k] == nil then
			data[k] = v
		end
	end
	-- Nested
	for k, v in pairs(default.money) do
		if data.money[k] == nil then data.money[k] = v end
	end
	for k, v in pairs(default.restaurant) do
		if data.restaurant[k] == nil then data.restaurant[k] = v end
	end
	for k, v in pairs(default.cosmetics) do
		if data.cosmetics[k] == nil then data.cosmetics[k] = v end
	end
	for k, v in pairs(default.vip) do
		if data.vip[k] == nil then data.vip[k] = v end
	end
	for k, v in pairs(default.battlePass) do
		if data.battlePass[k] == nil then data.battlePass[k] = v end
	end
	return data
end

function DataManager.getLevel(dishesServed)
	return math.max(1, math.floor(dishesServed / 10))
end

return DataManager
