-- MoneySystem.lua (shared)
-- Client-facing helpers; authoritative changes go through server remotes.

local MoneySystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes expected to exist under ReplicatedStorage/Remotes
local function remote(name)
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name)
end

function MoneySystem.getBalance(playerData)
	return playerData.money.currentBalance
end

function MoneySystem.canAfford(playerData, amount)
	return playerData.money.currentBalance >= amount
end

-- Called client-side to request a spend; server validates
function MoneySystem.requestSpend(amount, reason)
	remote("SpendMoney"):FireServer(amount, reason)
end

-- Called client-side to display money gain feedback only
function MoneySystem.formatIGC(amount)
	return string.format("%d IGC", amount)
end

return MoneySystem
