-- RestaurantManager.server.lua  (Script — handles plot creation and furniture)

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStore   = require(ServerScriptService:WaitForChild("DataStore"))
local MoneyServer = require(ServerScriptService:WaitForChild("MoneyServer"))
local EmployeeAI  = require(ServerScriptService:WaitForChild("EmpAI"))

local Modules    = ReplicatedStorage:WaitForChild("Modules")
local Constants  = require(Modules.Constants)
local RMShared   = require(Modules.RestaurantManager)

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local PlaceObject  = Remotes:WaitForChild("PlaceObject")
local DeleteObject = Remotes:WaitForChild("DeleteObject")
local Expand       = Remotes:WaitForChild("Expand")
local Notification = Remotes:WaitForChild("Notification")

-- [userId] = { plotOrigin, plotModel, placedObjects }
local restaurantState = {}

local FURNITURE_SIZES = {
	KitchenCounter = Vector3.new(4, 3, 2),
	DiningTable    = Vector3.new(4, 2, 4),
	CashierStation = Vector3.new(3, 3, 2),
	TrashBin       = Vector3.new(1, 2, 1),
	Door           = Vector3.new(3, 5, 1),
	Wall           = Vector3.new(4, 5, 0.5),
	FloorTile      = Vector3.new(4, 0.2, 4),
}

local FURNITURE_CFG = {
	KitchenCounter = { body = Color3.fromRGB(50,50,60),   top = Color3.fromRGB(220,220,220), accent = Color3.fromRGB(255,120,0),   label = "KITCHEN" },
	DiningTable    = { body = Color3.fromRGB(120,75,40),  top = Color3.fromRGB(200,160,100), accent = nil,                         label = "TABLE"   },
	CashierStation = { body = Color3.fromRGB(30,30,50),   top = Color3.fromRGB(255,200,0),   accent = Color3.fromRGB(0,200,255),   label = "CASHIER" },
	TrashBin       = { body = Color3.fromRGB(40,110,50),  top = Color3.fromRGB(60,160,70),   accent = nil,                         label = ""        },
	Wall           = { body = Color3.fromRGB(140,140,155),top = nil,                          accent = nil,                         label = ""        },
	FloorTile      = { body = Color3.fromRGB(240,235,220),top = nil,                          accent = nil,                         label = ""        },
}

local function makeFurniturePart(furnitureType, cframe)
	local sz  = FURNITURE_SIZES[furnitureType] or Vector3.new(2, 2, 2)
	local cfg = FURNITURE_CFG[furnitureType]

	local model        = Instance.new("Model")
	model.Name         = furnitureType
	model.Parent       = workspace

	local body         = Instance.new("Part")
	body.Name          = "Body"
	body.Size          = sz
	body.CFrame        = cframe
	body.Anchored      = true
	body.Material      = Enum.Material.SmoothPlastic
	body.Color         = cfg and cfg.body or Color3.fromRGB(120,120,130)
	body.Parent        = model
	model.PrimaryPart  = body

	if cfg and cfg.top then
		local top      = Instance.new("Part")
		top.Name       = "Top"
		top.Size       = Vector3.new(sz.X - 0.2, 0.25, sz.Z - 0.2)
		top.CFrame     = cframe * CFrame.new(0, sz.Y/2 + 0.12, 0)
		top.Anchored   = true
		top.Material   = Enum.Material.SmoothPlastic
		top.Color      = cfg.top
		top.Parent     = model
	end

	if cfg and cfg.accent then
		local acc      = Instance.new("Part")
		acc.Name       = "Accent"
		acc.Size       = Vector3.new(sz.X - 0.4, 0.2, 0.2)
		acc.CFrame     = cframe * CFrame.new(0, sz.Y/2 - 0.3, -sz.Z/2 + 0.15)
		acc.Anchored   = true
		acc.Material   = Enum.Material.Neon
		acc.Color      = cfg.accent
		acc.Parent     = model
	end

	if cfg and cfg.label and cfg.label ~= "" then
		local labelPart = Instance.new("Part")
		labelPart.Name  = "Label"
		labelPart.Size  = Vector3.new(sz.X - 0.4, sz.Y * 0.4, 0.15)
		labelPart.CFrame= cframe * CFrame.new(0, 0, -sz.Z/2 - 0.08)
		labelPart.Anchored = true
		labelPart.Material = Enum.Material.SmoothPlastic
		labelPart.Color    = cfg and cfg.top or Color3.fromRGB(200,200,200)
		labelPart.Parent   = model

		local sg = Instance.new("SurfaceGui")
		sg.Face  = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 60
		sg.Parent = labelPart

		local lbl = Instance.new("TextLabel")
		lbl.Size  = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = cfg.label
		lbl.TextColor3 = Color3.fromRGB(20,10,5)
		lbl.Parent = sg
	end

	return model
end

-- ── Build the restaurant plot ─────────────────────────────────────────────────

local function buildPlot(player, origin, expansionLevel)
	local expData = Constants.EXPANSIONS[expansionLevel] or Constants.EXPANSIONS[1]
	local size    = expData.size

	local plotModel      = Instance.new("Model")
	plotModel.Name       = player.Name .. "_Restaurant"
	plotModel.Parent     = workspace

	-- Floor (warm cream tile)
	local floor          = Instance.new("Part")
	floor.Name           = "Floor"
	floor.Anchored       = true
	floor.CanCollide     = true
	floor.Size           = Vector3.new(size, 0.4, size)
	floor.CFrame         = CFrame.new(origin + Vector3.new(0, -0.2, 0))
	floor.Material       = Enum.Material.SmoothPlastic
	floor.Color          = Color3.fromRGB(245, 235, 210)
	floor.Parent         = plotModel

	-- Hot-pink neon border glow strip
	local border         = Instance.new("Part")
	border.Name          = "Border"
	border.Anchored      = true
	border.CanCollide    = false
	border.Size          = Vector3.new(size + 0.5, 0.12, size + 0.5)
	border.CFrame        = CFrame.new(origin + Vector3.new(0, -0.06, 0))
	border.Material      = Enum.Material.Neon
	border.BrickColor    = BrickColor.new("Hot pink")
	border.Parent        = plotModel

	-- ── Perimeter neon walls (decorative, non-blocking) ──────────────────────
	local wallH   = 3.2
	local wallT   = 0.3
	local wallMat = Enum.Material.Neon
	local wallClr = BrickColor.new("Hot pink")
	local wallFns = {
		-- back wall
		{ sz = Vector3.new(size, wallH, wallT),
		  cf = CFrame.new(origin + Vector3.new(0, wallH/2, size/2)) },
		-- left wall
		{ sz = Vector3.new(wallT, wallH, size),
		  cf = CFrame.new(origin + Vector3.new(-size/2, wallH/2, 0)) },
		-- right wall
		{ sz = Vector3.new(wallT, wallH, size),
		  cf = CFrame.new(origin + Vector3.new(size/2, wallH/2, 0)) },
		-- front-left section (gap for entrance on left)
		{ sz = Vector3.new(size/2 - 1.5, wallH, wallT),
		  cf = CFrame.new(origin + Vector3.new(-(size/4 + 0.5), wallH/2, -size/2)) },
		-- front-right section
		{ sz = Vector3.new(size/2 - 1.5, wallH, wallT),
		  cf = CFrame.new(origin + Vector3.new(size/4 + 0.5, wallH/2, -size/2)) },
	}
	for _, w in ipairs(wallFns) do
		local wp       = Instance.new("Part")
		wp.Anchored    = true
		wp.CanCollide  = false
		wp.Size        = w.sz
		wp.CFrame      = w.cf
		wp.Material    = wallMat
		wp.BrickColor  = wallClr
		wp.Transparency = 0.55
		wp.Parent      = plotModel
	end

	-- ── Ceiling neon light bars ────────────────────────────────────────────────
	local ceilY = wallH + 0.5
	local lightClr = BrickColor.new("Cyan")
	for _, dx in ipairs({-size/4, size/4}) do
		local bar       = Instance.new("Part")
		bar.Anchored    = true
		bar.CanCollide  = false
		bar.Size        = Vector3.new(0.3, 0.2, size - 1)
		bar.CFrame      = CFrame.new(origin + Vector3.new(dx, ceilY, 0))
		bar.Material    = Enum.Material.Neon
		bar.BrickColor  = lightClr
		bar.Parent      = plotModel
	end

	-- ── Entrance archway ──────────────────────────────────────────────────────
	local archH = 3
	for _, sx in ipairs({-1.5, 1.5}) do
		local post       = Instance.new("Part")
		post.Anchored    = true
		post.CanCollide  = false
		post.Size        = Vector3.new(wallT + 0.2, archH, wallT + 0.2)
		post.CFrame      = CFrame.new(origin + Vector3.new(sx, archH/2, -size/2))
		post.Material    = Enum.Material.Neon
		post.BrickColor  = BrickColor.new("Hot pink")
		post.Parent      = plotModel
	end

	-- ── Restaurant sign (cleaner design) ─────────────────────────────────────
	local signPost       = Instance.new("Part")
	signPost.Anchored    = true
	signPost.CanCollide  = false
	signPost.Size        = Vector3.new(0.4, wallH + 2, 0.4)
	signPost.CFrame      = CFrame.new(origin + Vector3.new(0, (wallH + 2)/2, -size/2 - 1))
	signPost.BrickColor  = BrickColor.new("Dark orange")
	signPost.Material    = Enum.Material.SmoothPlastic
	signPost.Parent      = plotModel

	local signBoard      = Instance.new("Part")
	signBoard.Anchored   = true
	signBoard.CanCollide = false
	signBoard.Size       = Vector3.new(9, 2.2, 0.4)
	signBoard.CFrame     = CFrame.new(origin + Vector3.new(0, wallH + 1.5, -size/2 - 1))
	signBoard.BrickColor = BrickColor.new("Hot pink")
	signBoard.Material   = Enum.Material.Neon
	signBoard.Parent     = plotModel

	local signGui        = Instance.new("SurfaceGui")
	signGui.Face         = Enum.NormalId.Front
	signGui.SizingMode   = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 50
	signGui.Parent       = signBoard

	local signBg         = Instance.new("Frame")
	signBg.Size          = UDim2.new(1, 0, 1, 0)
	signBg.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
	signBg.BackgroundTransparency = 0.2
	signBg.BorderSizePixel = 0
	signBg.Parent        = signGui

	local signLabel      = Instance.new("TextLabel")
	signLabel.Size       = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.TextScaled = true
	signLabel.Font       = Enum.Font.GothamBlack
	signLabel.Text       = "🍔 " .. player.Name .. "'s Diner"
	signLabel.TextStrokeTransparency = 0.5
	signLabel.TextStrokeColor3 = Color3.fromRGB(100, 0, 50)
	signLabel.Parent     = signBg

	plotModel.PrimaryPart = floor
	return plotModel
end

-- ── Player join: create plot, restore furniture ───────────────────────────────

Players.PlayerAdded:Connect(function(player)
	local data = DataStore.waitForData(player, 15)
	if not data then return end

	local slot   = (player.UserId % 20) * 40
	local origin = Vector3.new(slot, 0.2, 0)

	local plotModel = buildPlot(player, origin, data.restaurant.expansionLevel)

	restaurantState[player.UserId] = {
		plotOrigin    = origin,
		plotModel     = plotModel,
		placedObjects = {},
	}

	-- Register origin with EmployeeAI
	EmployeeAI.registerPlot(player, origin)

	-- Place starter furniture for new players (empty restaurant)
	if #(data.restaurant.objects or {}) == 0 then
		local starter = {
			{ type = "KitchenCounter",  dx = -3, dy = 0,  dz = -2 },
			{ type = "CashierStation",  dx =  3, dy = 0,  dz = -2 },
			{ type = "DiningTable",     dx = -1, dy = 0,  dz =  2 },
			{ type = "DiningTable",     dx =  1, dy = 0,  dz =  2 },
		}
		data.restaurant.objects = {}
		restaurantState[player.UserId].placedObjects = {}
		for i, item in ipairs(starter) do
			local pos = Vector3.new(origin.X + item.dx, origin.Y + item.dy + 0.2, origin.Z + item.dz)
			local cf  = CFrame.new(pos)
			local part = makeFurniturePart(item.type, cf)
			table.insert(restaurantState[player.UserId].placedObjects, {
				id = i, type = item.type,
				pos = pos, rotationN = 0, model = part,
			})
			table.insert(data.restaurant.objects, {
				id = i, type = item.type,
				x = pos.X, y = pos.Y, z = pos.Z, rotation = 0,
			})
		end
	end

	-- Restore previously-saved furniture (skipped for brand new players above)
	if #restaurantState[player.UserId].placedObjects == 0 then
		for _, saved in ipairs(data.restaurant.objects or {}) do
			local pos    = Vector3.new(saved.x, saved.y, saved.z)
			local angle  = (saved.rotation or 0) * 90
			local cf     = CFrame.new(pos) * CFrame.Angles(0, math.rad(angle), 0)
			local part   = makeFurniturePart(saved.type, cf)
			table.insert(restaurantState[player.UserId].placedObjects, {
				id = saved.id, type = saved.type,
				pos = pos, rotationN = saved.rotation or 0, model = part,
			})
		end
	end

	-- Teleport player onto their plot
	task.wait(1)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(origin + Vector3.new(0, 5, 0))
	end
end)

-- ── PlaceObject ───────────────────────────────────────────────────────────────

PlaceObject.OnServerInvoke = function(player, furnitureType, rawPos, rotationN)
	local data  = DataStore.get(player)
	local state = restaurantState[player.UserId]
	if not data or not state then return false, "not ready" end

	if not Constants.FURNITURE[furnitureType] then return false, "unknown type" end

	local snapped = RMShared.snapToGrid(rawPos)
	if not RMShared.isInBounds(snapped, state.plotOrigin, data.restaurant.expansionLevel) then
		return false, "out of bounds"
	end

	local exp = Constants.EXPANSIONS[data.restaurant.expansionLevel]
	if #state.placedObjects >= exp.maxObjects then return false, "at capacity" end

	local cost = Constants.FURNITURE[furnitureType].cost
	if not MoneyServer.spend(player, cost) then
		Notification:FireClient(player, "❌ Not enough IGC!")
		return false, "insufficient funds"
	end

	local angle = (rotationN or 0) * 90
	local cf    = CFrame.new(snapped) * CFrame.Angles(0, math.rad(angle), 0)
	local part  = makeFurniturePart(furnitureType, cf)

	local objId = #state.placedObjects + 1
	table.insert(state.placedObjects, {
		id = objId, type = furnitureType,
		pos = snapped, rotationN = rotationN or 0, model = part,
	})
	table.insert(data.restaurant.objects, {
		id = objId, type = furnitureType,
		x = snapped.X, y = snapped.Y, z = snapped.Z,
		rotation = rotationN or 0,
	})

	return true, objId
end

-- ── DeleteObject ──────────────────────────────────────────────────────────────

DeleteObject.OnServerEvent:Connect(function(player, objId)
	local state = restaurantState[player.UserId]
	local data  = DataStore.get(player)
	if not state or not data then return end

	for i, obj in ipairs(state.placedObjects) do
		if obj.id == objId then
			local cost   = (Constants.FURNITURE[obj.type] or {}).cost or 0
			local refund = math.floor(cost * 0.5)
			MoneyServer.earn(player, refund)
			if obj.model then obj.model:Destroy() end
			table.remove(state.placedObjects, i)
			for j, s in ipairs(data.restaurant.objects) do
				if s.id == objId then table.remove(data.restaurant.objects, j); break end
			end
			break
		end
	end
end)

-- ── Expand ────────────────────────────────────────────────────────────────────

Expand.OnServerInvoke = function(player)
	local data  = DataStore.get(player)
	local state = restaurantState[player.UserId]
	if not data or not state then return false, "not ready" end

	local curLv  = data.restaurant.expansionLevel
	local nextLv = curLv + 1
	if nextLv > #Constants.EXPANSIONS then return false, "max size reached" end

	local cost = Constants.EXPANSIONS[nextLv].cost
	if not MoneyServer.spend(player, cost) then
		Notification:FireClient(player, "❌ Not enough IGC!")
		return false, "insufficient funds"
	end

	data.restaurant.expansionLevel = nextLv

	-- Resize floor
	local floor = state.plotModel:FindFirstChild("Floor")
	local border = state.plotModel:FindFirstChild("Border")
	local newSize = Constants.EXPANSIONS[nextLv].size
	if floor  then floor.Size  = Vector3.new(newSize, 0.4, newSize) end
	if border then border.Size = Vector3.new(newSize + 0.4, 0.1, newSize + 0.4) end

	Notification:FireClient(player, "🎉 Restaurant expanded to " .. newSize .. "x" .. newSize .. "!")
	return true, nextLv
end

-- ── Cleanup on leave ──────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	local state = restaurantState[player.UserId]
	if not state then return end
	if state.plotModel then state.plotModel:Destroy() end
	restaurantState[player.UserId] = nil
end)
