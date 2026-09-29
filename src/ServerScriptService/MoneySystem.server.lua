-- MoneySystem.server.lua
-- Authoritative IGC management. All balance changes go through here.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local Modules  = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules.Constants)

-- Wait for DataPersistence to be available via module binding
-- (loaded by require across server scripts via a ModuleScript bridge)
local DataPersistence   -- assigned below after scripts load in order

local UpdateBalance = Remotes:WaitForChild("UpdateBalance")  -- RemoteEvent to client
local SpendMoney    = Remotes:WaitForChild("SpendMoney")     -- RemoteEvent from client

-- ── Internal helpers ─────────────────────────────────────────────────────────

local function getDP()
	if not DataPersistence then
		DataPersistence = require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
	end
	return DataPersistence
end

local function syncBalance(player)
	local data = getDP().get(player)
	if data then
		UpdateBalance:FireClient(player, data.money.currentBalance, data.money.totalEarned)
	end
end

-- ── Public functions ─────────────────────────────────────────────────────────

local MoneyServer = {}

function MoneyServer.earn(player, amount)
	if amount <= 0 then return end
	local data = getDP().get(player)
	if not data then return end
	data.money.currentBalance = data.money.currentBalance + amount
	data.money.totalEarned    = data.money.totalEarned    + amount
	syncBalance(player)
end

function MoneyServer.spend(player, amount, reason)
	if amount <= 0 then return true end
	local data = getDP().get(player)
	if not data then return false end
	if data.money.currentBalance < amount then return false end
	data.money.currentBalance = data.money.currentBalance - amount
	syncBalance(player)
	return true
end

function MoneyServer.giveIGC(player, amount)
	MoneyServer.earn(player, amount)
end

-- ── Handle client spend requests ──────────────────────────────────────────────

SpendMoney.OnServerEvent:Connect(function(player, amount, reason)
	-- Clients can only request; server decides
	if type(amount) ~= "number" or amount <= 0 then return end
	MoneyServer.spend(player, amount, reason)
end)

-- ── Check milestone rewards ───────────────────────────────────────────────────

local function checkMilestones(player, data)
	for _, milestone in ipairs(Constants.MILESTONES) do
		if data.dishesServed >= milestone.dishes then
			local alreadyClaimed = false
			for _, d in ipairs(data.claimedMilestones or {}) do
				if d == milestone.dishes then alreadyClaimed = true; break end
			end
			if not alreadyClaimed then
				MoneyServer.earn(player, milestone.igcReward)
				table.insert(data.claimedMilestones, milestone.dishes)
				-- Notify client
				local notify = Remotes:FindFirstChild("Notification")
				if notify then
					notify:FireClient(player, "Milestone! +" .. milestone.igcReward .. " IGC")
				end
			end
		end
	end
end

-- Called by GameLoop when a dish is successfully served
function MoneyServer.onDishServed(player, dishKey, waitSeconds, customerType)
	local data = getDP().get(player)
	if not data then return end

	local DishSystem = require(Modules.DishSystem)
	local hasVIP = data.vip and data.vip.active and os.time() < data.vip.expiresAt
	local hasBP  = data.battlePass and data.battlePass.purchased

	local earned = DishSystem.calcEarnings(dishKey, waitSeconds, customerType, hasVIP, hasBP)
	MoneyServer.earn(player, earned)

	data.dishesServed = (data.dishesServed or 0) + 1
	data.level        = require(Modules.DataManager).getLevel(data.dishesServed)
	checkMilestones(player, data)
	syncBalance(player)

	return earned
end

-- ── Salary deduction (called by game loop every minute) ───────────────────────

function MoneyServer.deductSalaries(player)
	local data = getDP().get(player)
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

return MoneyServer
