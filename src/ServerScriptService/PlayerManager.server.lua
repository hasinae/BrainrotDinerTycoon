-- PlayerManager.server.lua
-- Wires together player join/leave and initializes the salary deduction loop.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules  = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules.Constants)

local function getDP()
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
end
local function getMS()
	return require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge"))
end

-- Salary deducted once per minute per player
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function() getMS().deductSalaries(player) end)
		end
	end
end)

-- Weekly earnings reset (check on join; server timestamp based)
local WEEK_SECONDS = 7 * 24 * 60 * 60

Players.PlayerAdded:Connect(function(player)
	local loadEvent = ReplicatedStorage:WaitForChild("DataLoaded_" .. player.UserId, 30)
	if not loadEvent then return end
	loadEvent.Event:Wait()

	local data = getDP().get(player)
	if not data then return end

	-- Reset weekly earnings if a new week has started
	local lastReset = data.weeklyEarnedReset or 0
	if os.time() - lastReset >= WEEK_SECONDS then
		data.money.weeklyEarned = 0
		data.weeklyEarnedReset  = os.time()
	end

	-- Spawn starting free employee if none exist
	if not data.employees or #data.employees == 0 then
		local types = { "tung_tung_sahur", "tralalero_tralala", "ballerina_cappuccina" }
		local picked = types[math.random(1, #types)]
		local cfg    = Constants.EMPLOYEES[picked]
		data.employees = {{
			id   = 1,
			type = picked,
			name = cfg.displayName,
		}}
	end
end)

return {}
