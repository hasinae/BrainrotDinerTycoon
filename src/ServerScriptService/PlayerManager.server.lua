-- PlayerManager.server.lua  (Script — weekly reset and salary loop)

local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStore   = require(ServerScriptService:WaitForChild("DataStore"))
local MoneyServer = require(ServerScriptService:WaitForChild("MoneyServer"))

local WEEK_SECONDS = 7 * 24 * 60 * 60

Players.PlayerAdded:Connect(function(player)
	local data = DataStore.waitForData(player, 15)
	if not data then return end

	-- Reset weekly earnings if a new week has started
	local lastReset = data.weeklyEarnedReset or 0
	if os.time() - lastReset >= WEEK_SECONDS then
		data.money.weeklyEarned    = 0
		data.weeklyEarnedReset     = os.time()
	end
end)

-- Salary deduction every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			MoneyServer.deductSalaries(player)
		end
	end
end)
