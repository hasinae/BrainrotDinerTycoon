-- DataPersistence.server.lua  (Script — runs on server start)
-- Loads/saves player data using DataStore module.

local Players           = game:GetService("Players")
local DataStore         = require(script.Parent:WaitForChild("DataStore"))

Players.PlayerAdded:Connect(function(player)
	DataStore.load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataStore.unload(player)
end)

-- Autosave loop
task.spawn(function()
	local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Constants"))
	while true do
		task.wait(Constants.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			DataStore.save(player)
		end
	end
end)

-- Handle server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataStore.save(player)
	end
end)
