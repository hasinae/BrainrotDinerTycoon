-- MoneyServer.lua  (ModuleScript — required by GameLoop, RestaurantManager, etc.)
-- Authoritative IGC earn/spend. Requires DataStore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local Constants    = require(Modules.Constants)

local DataStore    -- injected via MoneyServer.init() to avoid circular require
local UpdateBalance

local MoneyServer = {}

function MoneyServer.init(ds, updateBalanceRemote)
	DataStore    = ds
	UpdateBalance = updateBalanceRemote
end

local function syncBalance(player)
	local data = DataStore.get(player)
	if data and UpdateBalance then
		UpdateBalance:FireClient(player, data.money.currentBalance, data.money.totalEarned)
	end
end

function MoneyServer.earn(player, amount)
	if amount <= 0 then return end
	local data = DataStore.get(player)
	if not data then return end
	data.money.currentBalance = data.money.currentBalance + amount
	data.money.totalEarned    = data.money.totalEarned    + amount
	syncBalance(player)
end

function MoneyServer.spend(player, amount)
	if amount <= 0 then return true end
	local data = DataStore.get(player)
	if not data then return false end
	if data.money.currentBalance < amount then return false end
	data.money.currentBalance = data.money.currentBalance - amount
	syncBalance(player)
	return true
end

function MoneyServer.getBalance(player)
	local data = DataStore.get(player)
	return data and data.money.currentBalance or 0
end

function MoneyServer.pushBalance(player)
	syncBalance(player)
end

function MoneyServer.deductSalaries(player)
	local data = DataStore.get(player)
	if not data or not data.employees then return end
	local EmployeeManager = require(Modules.EmployeeManager)
	local total = 0
	for _, emp in ipairs(data.employees) do
		total = total + EmployeeManager.minuteSalary(emp.type)
	end
	if total > 0 then
		data.money.currentBalance = math.max(0, data.money.currentBalance - total)
		syncBalance(player)
	end
end

function MoneyServer.checkMilestones(player)
	local data = DataStore.get(player)
	if not data then return end
	for _, m in ipairs(Constants.MILESTONES) do
		if data.dishesServed >= m.dishes then
			local claimed = false
			for _, d in ipairs(data.claimedMilestones or {}) do
				if d == m.dishes then claimed = true; break end
			end
			if not claimed then
				MoneyServer.earn(player, m.igcReward)
				data.claimedMilestones = data.claimedMilestones or {}
				table.insert(data.claimedMilestones, m.dishes)
				local notif = ReplicatedStorage:FindFirstChild("Remotes") and
					ReplicatedStorage.Remotes:FindFirstChild("Notification")
				if notif then
					notif:FireClient(player, "🎉 Milestone! +" .. m.igcReward .. " IGC!")
				end
			end
		end
	end
end

return MoneyServer
