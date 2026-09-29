-- CustomerSystem.server.lua (Script)
-- Spawns customers, manages their orders via OrderQueue.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules          = ReplicatedStorage:WaitForChild("Modules")
local CustomerSpawner  = require(Modules.CustomerSpawner)
local Constants        = require(Modules.Constants)
local DishSystem       = require(Modules.DishSystem)
local PathfindingHelper= require(Modules.PathfindingHelper)

local DataStore   = require(ServerScriptService:WaitForChild("DataStore"))
local MoneyServer = require(ServerScriptService:WaitForChild("MoneyServer"))
local OrderQueue  = require(ServerScriptService:WaitForChild("OrderQueue"))

local CUSTOMER_COLORS = {
	regular = BrickColor.new("Bright blue"),
	sigma   = BrickColor.new("Bright yellow"),
	npc     = BrickColor.new("Medium stone grey"),
	skibidi = BrickColor.new("Bright red"),
}
local CUSTOMER_LABELS = {
	regular = "Regular",
	sigma   = "Sigma 😎",
	npc     = "NPC",
	skibidi = "Skibidi 🚽",
}

local function getRemote(name)
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	return rem and rem:FindFirstChild(name)
end

local function notify(player, text)
	local r = getRemote("Notification")
	if r then r:FireClient(player, text) end
end

-- Build a simple brick customer NPC
local function makeCustomerModel(customerType, spawnPos)
	local model = Instance.new("Model")
	model.Name  = "Customer_" .. customerType

	local root  = Instance.new("Part")
	root.Name   = "HumanoidRootPart"
	root.Size   = Vector3.new(2, 2, 1)
	root.BrickColor = CUSTOMER_COLORS[customerType] or BrickColor.new("Bright blue")
	root.Material   = Enum.Material.SmoothPlastic
	root.Anchored   = false
	root.Parent     = model

	local board = Instance.new("BillboardGui")
	board.Size  = UDim2.new(0, 120, 0, 30)
	board.StudsOffset = Vector3.new(0, 2.5, 0)
	board.AlwaysOnTop = false
	board.Parent = root
	local tag = Instance.new("TextLabel")
	tag.Name = "StatusLabel"
	tag.Size = UDim2.new(1, 0, 1, 0)
	tag.BackgroundTransparency = 1
	tag.TextColor3 = Color3.new(1, 1, 1)
	tag.TextStrokeTransparency = 0
	tag.TextStrokeColor3 = Color3.new(0, 0, 0)
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 13
	tag.Text = CUSTOMER_LABELS[customerType] or customerType
	tag.Parent = board

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 12
	humanoid.Parent = model

	model.PrimaryPart = root
	model.Parent = workspace
	model:PivotTo(CFrame.new(spawnPos))
	return model
end

-- Full customer lifecycle: enter → order → wait → paid/leave
local function runCustomer(player, customerType, plotOrigin)
	local session = OrderQueue.getSession(player.UserId)
	if #session.customers >= Constants.MAX_CONCURRENT_CUSTOMERS then return end

	local pendingCount = 0
	for _, o in ipairs(session.orders) do
		if o.status == "pending" then pendingCount = pendingCount + 1 end
	end
	if CustomerSpawner.decideLeave(pendingCount * 5, customerType) then return end

	-- Spawn at edge of plot
	local spawnPos = Vector3.new(plotOrigin.X - 16, plotOrigin.Y + 4, plotOrigin.Z)
	local model    = makeCustomerModel(customerType, spawnPos)
	OrderQueue.addCustomer(player.UserId, model)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		OrderQueue.removeCustomer(player.UserId, model)
		model:Destroy()
		return
	end

	-- Walk to a table spot inside the plot
	local dx = math.random(-3, 3)
	local dz = math.random(-2, 3)
	local tablePos = Vector3.new(plotOrigin.X + dx, plotOrigin.Y + 3, plotOrigin.Z + dz)

	PathfindingHelper.moveToSimple(humanoid, tablePos, function(_reached)
		if not model or not model.Parent then return end

		local data = DataStore.get(player)
		if not data then
			OrderQueue.removeCustomer(player.UserId, model)
			if model.Parent then model:Destroy() end
			return
		end

		local available = DishSystem.getAvailableDishes(data)
		if #available == 0 then
			OrderQueue.removeCustomer(player.UserId, model)
			if model.Parent then model:Destroy() end
			return
		end

		local dishKey  = available[math.random(1, #available)]
		local dishInfo = Constants.DISHES[dishKey]

		-- Update name tag to show order
		local statusLabel = model.HumanoidRootPart:FindFirstChild("BillboardGui")
			and model.HumanoidRootPart.BillboardGui:FindFirstChild("StatusLabel")
		if statusLabel then
			statusLabel.Text = "🍽️ " .. (dishInfo and dishInfo.name or dishKey)
		end

		local order = {
			id           = math.random(100000, 999999),
			dishKey      = dishKey,
			status       = "pending",
			orderedAt    = os.clock(),
			assignedTo   = nil,
			customerType = customerType,
			customer     = model,
		}
		OrderQueue.addOrder(player.UserId, order)
		notify(player, "📋 Order: " .. (dishInfo and dishInfo.name or dishKey))

		-- Wait for dish
		local startWait = os.clock()
		while os.clock() - startWait < Constants.ORDER_EXPIRE_SEC do
			task.wait(0.5)
			if not model or not model.Parent then
				OrderQueue.removeOrder(player.UserId, order.id)
				return
			end
			if order.status == "ready" or order.status == "error" then break end
		end

		local waitSec = os.clock() - startWait
		local earned  = 0

		if order.status == "ready" then
			-- Brief eating pause
			if statusLabel then statusLabel.Text = "😋 Eating..." end
			task.wait(1.5)

			earned = DishSystem.calcEarnings(
				dishKey, waitSec, customerType,
				data.vip and data.vip.active,
				data.battlePass and data.battlePass.purchased
			)
			MoneyServer.earn(player, earned)

			data.dishesServed = (data.dishesServed or 0) + 1
			data.level = math.max(1, math.floor(data.dishesServed / 10) + 1)
			MoneyServer.checkMilestones(player)

			local stateStr = waitSec <= Constants.HAPPY_THRESHOLD_SEC and "happy"
				or waitSec <= Constants.NEUTRAL_THRESHOLD_SEC and "neutral" or "angry"
			session.reputation = math.max(0.1, math.min(2.0,
				(session.reputation or 1) + CustomerSpawner.reputationDelta(stateStr)))

			notify(player, "💰 Served! +" .. earned .. " IGC")

			-- Fire level update to client
			local upd = getRemote("UpdateProgress")
			if upd then upd:FireClient(player, data.level, data.dishesServed) end
		else
			-- Expired or errored
			session.reputation = math.max(0.1, (session.reputation or 1) - 0.08)
			notify(player, "😤 Customer gave up waiting!")
			if statusLabel then statusLabel.Text = "😤 Leaving!" end
		end

		OrderQueue.removeOrder(player.UserId, order.id)
		OrderQueue.removeCustomer(player.UserId, model)

		-- Walk out
		if model and model.Parent and humanoid and humanoid.Parent then
			local exitPos = Vector3.new(plotOrigin.X - 16, plotOrigin.Y + 3, plotOrigin.Z)
			humanoid:MoveTo(exitPos)
			task.wait(3)
		end
		if model and model.Parent then model:Destroy() end
	end)
end

-- Spawn loop per player
local function startSpawnLoop(player, plotOrigin)
	task.spawn(function()
		task.wait(6)  -- let restaurant build first
		while player and player.Parent do
			local data = DataStore.get(player)
			if not data then task.wait(5); continue end

			local session  = OrderQueue.getSession(player.UserId)
			local interval = CustomerSpawner.spawnInterval(data.level or 1, session.reputation or 1)
			task.wait(interval)

			if not player or not player.Parent then break end
			local ctype = CustomerSpawner.randomType()
			task.spawn(function() runCustomer(player, ctype, plotOrigin) end)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	local data = DataStore.waitForData(player, 20)
	if not data then return end

	local slot      = (player.UserId % 20) * 40
	local plotOrigin = Vector3.new(slot, 0.2, 0)
	startSpawnLoop(player, plotOrigin)
end)

Players.PlayerRemoving:Connect(function(player)
	OrderQueue.cleanup(player.UserId)
end)
