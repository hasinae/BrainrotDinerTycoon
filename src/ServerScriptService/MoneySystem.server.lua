-- MoneySystem.server.lua  (Script — thin runner, delegates to MoneyServer module)
-- MoneyServer is initialized by GameLoop. This script just wires the SpendMoney remote.

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local SpendMoney  = Remotes:WaitForChild("SpendMoney")
local MoneyServer = require(ServerScriptService:WaitForChild("MoneyServer"))

SpendMoney.OnServerEvent:Connect(function(player, amount)
	if type(amount) ~= "number" or amount <= 0 then return end
	MoneyServer.spend(player, amount)
end)
