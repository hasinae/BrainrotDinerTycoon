-- EmployeeManager.lua (shared)
-- Employee type data helpers. Actual AI runs server-side in EmployeeAI.server.lua.

local EmployeeManager = {}

local Constants = require(script.Parent.Constants)

-- Returns config for an employee type key
function EmployeeManager.getConfig(typeKey)
	return Constants.EMPLOYEES[typeKey]
end

-- Pick a random quote for this employee type
function EmployeeManager.getQuote(typeKey)
	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg or #cfg.quotes == 0 then return nil end
	return cfg.quotes[math.random(1, #cfg.quotes)]
end

-- Actual speed for a task after applying VIP/pass bonuses
function EmployeeManager.effectiveSpeed(typeKey, hasVIP, hasPremiumPass, hasWeeklyPass)
	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg then return 1 end
	local speed = cfg.speedMult
	if hasVIP            then speed = speed * 1.25 end
	if hasPremiumPass    then speed = speed * 1.5  end
	if hasWeeklyPass     then speed = speed * 2.0  end
	-- Ballerina variance
	if typeKey == "ballerina_cappuccina" then
		local variance = cfg.varianceMin + math.random() * (cfg.varianceMax - cfg.varianceMin)
		speed = speed * variance
	end
	return speed
end

-- Salary cost per real-time minute
function EmployeeManager.minuteSalary(typeKey)
	local cfg = Constants.EMPLOYEES[typeKey]
	return cfg and cfg.salary or 0
end

-- Check if employee makes an error on this task
function EmployeeManager.rollError(typeKey)
	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg then return false end
	return math.random() < cfg.errorChance
end

-- Check if employee freezes this tick
function EmployeeManager.rollFreeze(typeKey)
	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg then return false end
	return math.random() < (cfg.freezeChance or 0)
end

-- Max employees of this type per restaurant
function EmployeeManager.maxOfType(typeKey)
	local cfg = Constants.EMPLOYEES[typeKey]
	return cfg and cfg.maxPerRestaurant or 0
end

-- Total max employees across all types
function EmployeeManager.totalCapacity()
	local n = 0
	for _, cfg in pairs(Constants.EMPLOYEES) do
		n = n + cfg.maxPerRestaurant
	end
	return n
end

return EmployeeManager
