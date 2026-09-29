-- GameLoop.server.lua  (Script — bootstraps remotes and wires server systems)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ── Remotes (created FIRST so client never hangs on WaitForChild) ─────────────
local Remotes = Instance.new("Folder")
Remotes.Name  = "Remotes"
Remotes.Parent = ReplicatedStorage

-- Wrap everything else so a crash here doesn't kill the Remotes
local ok, err = pcall(function()

local function evt(name)
	local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remotes; return r
end
local function fn(name)
	local r = Instance.new("RemoteFunction"); r.Name = name; r.Parent = Remotes; return r
end

local UpdateBalance     = evt("UpdateBalance")
local UpdateProgress    = evt("UpdateProgress")
local Notification      = evt("Notification")
local UpdateLeaderboard = evt("UpdateLeaderboard")
local HireEmployee      = evt("HireEmployee")
local FireEmployee      = evt("FireEmployee")
local DeleteObject      = evt("DeleteObject")
local SpendMoney        = evt("SpendMoney")
local EquipCosmetic     = evt("EquipCosmetic")
local GetPlayerData     = fn("GetPlayerData")
local PlaceObject       = fn("PlaceObject")
local Expand            = fn("Expand")

-- ── Require modules (these are .lua ModuleScripts, safe to require) ───────────
local DataStore   = require(ServerScriptService:WaitForChild("DataStore"))
local MoneyServer = require(ServerScriptService:WaitForChild("MoneyServer"))
MoneyServer.init(DataStore, UpdateBalance)

local Modules         = ReplicatedStorage:WaitForChild("Modules")
local Constants       = require(Modules.Constants)
local EmployeeManager = require(Modules.EmployeeManager)

-- ── GetPlayerData ─────────────────────────────────────────────────────────────
GetPlayerData.OnServerInvoke = function(player)
	return DataStore.waitForData(player, 10)
end

-- ── Hire employee ─────────────────────────────────────────────────────────────
HireEmployee.OnServerEvent:Connect(function(player, typeKey)
	local data = DataStore.get(player)
	if not data then return end

	local cfg = Constants.EMPLOYEES[typeKey]
	if not cfg then return end

	-- Count existing of this type
	local count = 0
	for _, e in ipairs(data.employees) do
		if e.type == typeKey then count = count + 1 end
	end
	if count >= cfg.maxPerRestaurant then
		Notification:FireClient(player, "❌ Max " .. cfg.displayName .. " employees reached!")
		return
	end

	if not MoneyServer.spend(player, cfg.hireCost) then
		Notification:FireClient(player, "❌ Not enough IGC!")
		return
	end

	local newId = #data.employees + 1
	local emp   = { id = newId, type = typeKey, name = cfg.displayName, salary = cfg.salary }
	table.insert(data.employees, emp)
	Notification:FireClient(player, "✅ Hired " .. cfg.displayName .. "!")

	-- Tell EmployeeAI to spawn this character
	local EmployeeAI = require(ServerScriptService:WaitForChild("EmpAI"))
	local plotOrigin = EmployeeAI.getPlotOrigin(player)
	if plotOrigin then
		EmployeeAI.spawnEmployee(player, emp, plotOrigin)
	end

	-- Push fresh data back to client
	UpdateBalance:FireClient(player, data.money.currentBalance, data.money.totalEarned)
end)

-- ── Fire employee ─────────────────────────────────────────────────────────────
FireEmployee.OnServerEvent:Connect(function(player, empId)
	local data = DataStore.get(player)
	if not data then return end

	for i, emp in ipairs(data.employees) do
		if emp.id == empId then
			local cfg = Constants.EMPLOYEES[emp.type]
			if cfg then
				local refund = math.floor(cfg.hireCost * 0.5)
				MoneyServer.earn(player, refund)
				Notification:FireClient(player, "💸 Fired " .. emp.name .. " (+" .. refund .. " IGC refund)")
				task.delay(1.5, function()
					Notification:FireClient(player, "👥 Open BUILD to hire a replacement!")
				end)
			end
			local EmployeeAI = require(ServerScriptService:WaitForChild("EmpAI"))
			EmployeeAI.removeEmployee(player, empId)
			table.remove(data.employees, i)
			break
		end
	end
end)

-- ── SpendMoney (client-initiated, validated here) ────────────────────────────
SpendMoney.OnServerEvent:Connect(function(player, amount, _reason)
	if type(amount) ~= "number" or amount <= 0 then return end
	MoneyServer.spend(player, amount)
end)

-- ── Salary deduction loop ─────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			MoneyServer.deductSalaries(player)
		end
	end
end)

-- ── Sync balance when player's data becomes ready ────────────────────────────
Players.PlayerAdded:Connect(function(player)
	DataStore.waitForData(player, 15)
	MoneyServer.pushBalance(player)
	-- Spawn employees that were in saved data
	task.delay(1, function()
		local data = DataStore.get(player)
		if not data then return end
		local EmployeeAI = require(ServerScriptService:WaitForChild("EmpAI"))
		local plotOrigin = EmployeeAI.getPlotOrigin(player)
		if plotOrigin then
			for _, emp in ipairs(data.employees) do
				EmployeeAI.spawnEmployee(player, emp, plotOrigin)
			end
		end
	end)
end)

print("[GameLoop] Server ready ✅")
end)  -- end pcall
if not ok then warn("[GameLoop] Error during init:", err) end
