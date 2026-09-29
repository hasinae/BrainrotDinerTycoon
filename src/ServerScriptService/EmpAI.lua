-- EmpAI.lua  (ModuleScript — required by GameLoop and RestaurantManager)
-- Spawns employee NPCs, drives AI: cook orders when available, wander when idle.

local Players             = game:GetService("Players")
local ServerStorage       = game:GetService("ServerStorage")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules         = ReplicatedStorage:WaitForChild("Modules")
local EmployeeManager = require(Modules.EmployeeManager)
local Constants       = require(Modules.Constants)
local OrderQueue      = require(ServerScriptService:WaitForChild("OrderQueue"))

local plotOrigins  = {}           -- [userId] = Vector3
local activeModels = {}           -- [userId] = { [empId] = model }

local TYPE_COLORS = {
	tung_tung_sahur      = BrickColor.new("Bright orange"),
	tralalero_tralala    = BrickColor.new("Medium stone grey"),
	ballerina_cappuccina = BrickColor.new("Hot pink"),
}

local EmployeeAI = {}

function EmployeeAI.registerPlot(player, origin)
	plotOrigins[player.UserId] = origin
end

function EmployeeAI.getPlotOrigin(player)
	return plotOrigins[player.UserId]
end

local function buildFallbackCharacter(empData)
	local model   = Instance.new("Model")
	model.Name    = empData.name or empData.type

	local root    = Instance.new("Part")
	root.Name     = "HumanoidRootPart"
	root.Size     = Vector3.new(2, 2, 1)
	root.Anchored = false
	root.BrickColor = TYPE_COLORS[empData.type] or BrickColor.new("Bright red")
	root.Material = Enum.Material.SmoothPlastic
	root.Parent   = model

	local head    = Instance.new("Part")
	head.Name     = "Head"
	head.Size     = Vector3.new(2, 2, 2)
	head.BrickColor = root.BrickColor
	head.Position = root.Position + Vector3.new(0, 2, 0)
	head.Anchored = false
	head.Parent   = model

	local weld    = Instance.new("WeldConstraint")
	weld.Part0    = root
	weld.Part1    = head
	weld.Parent   = root

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 14
	humanoid.Parent = model

	model.PrimaryPart = root

	local billboard = Instance.new("BillboardGui")
	billboard.Size  = UDim2.new(0, 140, 0, 36)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name  = "StatusLabel"
	nameLabel.Size  = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Font  = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Text  = empData.name or empData.type
	nameLabel.Parent = billboard

	return model
end

local function setStatus(model, text)
	local board = model:FindFirstChild("HumanoidRootPart")
		and model.HumanoidRootPart:FindFirstChild("BillboardGui")
	if board then
		local lbl = board:FindFirstChild("StatusLabel")
		if lbl then lbl.Text = text end
	end
end

local function runAI(userId, empData, model, plotOrigin)
	local cfg      = Constants.EMPLOYEES[empData.type] or {}
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local baseSpeed  = 14 * (cfg.speedMult or 1)
	local kitchenPos = Vector3.new(plotOrigin.X - 3, plotOrigin.Y + 3, plotOrigin.Z - 2)
	local cashierPos = Vector3.new(plotOrigin.X + 3, plotOrigin.Y + 3, plotOrigin.Z - 2)

	humanoid.WalkSpeed = baseSpeed

	task.spawn(function()
		while model and model.Parent do
			local order = OrderQueue.getNextPending(userId)

			if order then
				-- Claim the order
				order.assignedTo = empData.id

				-- Ballerina: randomise speed each task
				if cfg.varianceMin and cfg.varianceMax then
					local v = cfg.varianceMin + math.random() * (cfg.varianceMax - cfg.varianceMin)
					humanoid.WalkSpeed = math.max(4, 14 * v)
				end

				-- Walk to kitchen counter
				setStatus(model, "🍳 Cooking...")
				humanoid:MoveTo(kitchenPos)
				task.wait(1.5)

				-- Tralalero freeze mid-cook
				if cfg.freezeChance and math.random() < cfg.freezeChance then
					humanoid.WalkSpeed = 0
					setStatus(model, "😐 ...huh?")
					task.wait(math.random(2, 5))
					humanoid.WalkSpeed = baseSpeed
				end

				-- Cook time
				local dish     = Constants.DISHES[order.dishKey]
				local cookTime = math.max(0.5, (dish and dish.cookTime or 3) / (cfg.speedMult or 1))
				task.wait(cookTime)

				-- Error chance (Tung Tung Sahur)
				if cfg.errorChance and math.random() < cfg.errorChance then
					setStatus(model, "💀 Dropped it!")
					order.status = "error"
					task.wait(2)
					setStatus(model, empData.name or empData.type)
				else
					-- Walk to cashier / customer
					setStatus(model, "🏃 Delivering!")
					humanoid:MoveTo(cashierPos)
					task.wait(1.5)
					order.status = "ready"
					setStatus(model, "✅ Done!")
					task.wait(1.5)
					setStatus(model, empData.name or empData.type)
				end

				humanoid.WalkSpeed = baseSpeed
			else
				-- Idle: wander around the plot
				if cfg.freezeChance and math.random() < cfg.freezeChance then
					humanoid.WalkSpeed = 0
					task.wait(math.random(3, 7))
					humanoid.WalkSpeed = baseSpeed
				end
				local offset = Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
				humanoid:MoveTo(plotOrigin + offset + Vector3.new(0, 3, 0))
				task.wait(math.random(2, 4))
			end
		end
	end)
end

function EmployeeAI.spawnEmployee(player, empData, plotOrigin)
	if not activeModels[player.UserId] then
		activeModels[player.UserId] = {}
	end
	if activeModels[player.UserId][empData.id] then return end

	local templates = ServerStorage:FindFirstChild("EmployeeModels")
	local template  = templates and templates:FindFirstChild(empData.type)
	local model
	if template and #template:GetChildren() > 0 then
		model = template:Clone()
		model.Name = empData.name or empData.type
	else
		model = buildFallbackCharacter(empData)
	end

	local spawnPos = plotOrigin + Vector3.new(math.random(-3, 3), 4, math.random(-3, 3))
	model:PivotTo(CFrame.new(spawnPos))
	model.Parent = workspace

	activeModels[player.UserId][empData.id] = model
	runAI(player.UserId, empData, model, plotOrigin)

	return model
end

function EmployeeAI.removeEmployee(player, empId)
	local tbl = activeModels[player.UserId]
	if not tbl or not tbl[empId] then return end
	if tbl[empId] then tbl[empId]:Destroy() end
	tbl[empId] = nil
end

function EmployeeAI.despawnAll(player)
	local tbl = activeModels[player.UserId]
	if not tbl then return end
	for _, model in pairs(tbl) do
		if model then model:Destroy() end
	end
	activeModels[player.UserId] = nil
	plotOrigins[player.UserId]  = nil
end

Players.PlayerRemoving:Connect(function(player)
	EmployeeAI.despawnAll(player)
end)

return EmployeeAI
