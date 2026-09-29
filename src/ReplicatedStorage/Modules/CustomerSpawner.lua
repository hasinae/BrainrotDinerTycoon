-- CustomerSpawner.lua (shared)
-- Spawn-rate math and customer-decision helpers.

local CustomerSpawner = {}

local Constants = require(script.Parent.Constants)

local CUSTOMER_TYPES = { "regular", "sigma", "npc", "skibidi" }
local TYPE_WEIGHTS   = { 50, 15, 25, 10 }  -- relative weights

-- Pick a weighted random customer type
function CustomerSpawner.randomType()
	local total = 0
	for _, w in ipairs(TYPE_WEIGHTS) do total = total + w end
	local roll = math.random() * total
	local acc = 0
	for i, w in ipairs(TYPE_WEIGHTS) do
		acc = acc + w
		if roll <= acc then return CUSTOMER_TYPES[i] end
	end
	return "regular"
end

-- Spawn interval in seconds given player level and current reputation modifier
function CustomerSpawner.spawnInterval(level, reputationMod)
	-- Every 5 levels reduces interval by 1, minimum 3 sec
	local base = Constants.SPAWN_BASE_INTERVAL - math.floor(level / 5)
	base = math.max(Constants.SPAWN_MIN_INTERVAL, base)
	-- reputationMod: 1.0 = neutral, >1 = faster, <1 = slower
	return base / math.max(0.1, reputationMod)
end

-- Whether a customer decides to leave based on perceived wait
-- Returns true = leave, false = stay
function CustomerSpawner.decideLeave(estimatedWaitSec, customerType)
	local leaveChance = 0
	if estimatedWaitSec > 20 then
		leaveChance = 0.40
	elseif estimatedWaitSec > 10 then
		leaveChance = 0.20
	end

	-- Type modifiers
	if customerType == "sigma"   then leaveChance = leaveChance * 2 end
	if customerType == "skibidi" then leaveChance = leaveChance * 0.5 end

	return math.random() < leaveChance
end

-- Tip multiplier for a given customer type (resolved at call time for skibidi)
function CustomerSpawner.tipMultiplier(customerType)
	if customerType == "sigma"   then return 1.5 end
	if customerType == "npc"     then return 0   end
	if customerType == "skibidi" then return math.random() * 2 end
	return 1
end

-- Reputation delta after a customer interaction
-- state: "happy" | "neutral" | "angry"
function CustomerSpawner.reputationDelta(state)
	if state == "happy"   then return  0.02 end  -- +2%
	if state == "angry"   then return -0.15 end  -- -15%
	return 0
end

return CustomerSpawner
