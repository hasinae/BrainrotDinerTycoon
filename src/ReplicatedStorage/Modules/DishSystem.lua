-- DishSystem.lua
-- Shared dish data helpers and cook-time calculations.

local DishSystem = {}

local Constants = require(script.Parent.Constants)

-- Returns list of dish keys available to this player
function DishSystem.getAvailableDishes(playerData)
	local dishes = {}
	for key, info in pairs(Constants.DISHES) do
		if not info.premium or playerData.premiumDishPack then
			table.insert(dishes, key)
		end
	end
	return dishes
end

-- Actual cook time after applying employee speed multiplier
function DishSystem.getCookTime(dishKey, speedMult)
	local dish = Constants.DISHES[dishKey]
	if not dish then return 5 end
	return math.max(0.5, dish.cookTime / (speedMult or 1))
end

-- Earnings from a completed dish based on customer satisfaction
function DishSystem.calcEarnings(dishKey, waitSeconds, customerType, hasVIP, battlePassActive)
	local dish = Constants.DISHES[dishKey]
	if not dish then return 0 end

	local base = dish.price
	local mult = 1

	if waitSeconds <= Constants.HAPPY_THRESHOLD_SEC then
		mult = 1 + Constants.CUSTOMER_HAPPY_TIP
		if customerType == "sigma" then
			mult = mult * 1.5
		elseif customerType == "skibidi" then
			mult = mult * (math.random() * 2)   -- 0-2x
		end
	elseif waitSeconds <= Constants.NEUTRAL_THRESHOLD_SEC then
		mult = 1
		if customerType == "npc" then mult = 0 end
	else
		mult = Constants.CUSTOMER_ANGRY_REDUCE
	end

	if hasVIP then mult = mult * 2 end
	if battlePassActive then mult = mult * 1.5 end

	return math.floor(base * mult)
end

-- Human-readable speed label for menu display
function DishSystem.speedLabel(cookTime)
	if cookTime <= 3 then return "Fast"
	elseif cookTime <= 6 then return "Medium"
	else return "Slow" end
end

return DishSystem
