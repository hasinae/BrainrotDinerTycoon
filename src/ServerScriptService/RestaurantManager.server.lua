-- RestaurantManager.server.lua
-- Validates placement requests and manages the physical restaurant objects.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local Modules          = ReplicatedStorage:WaitForChild("Modules")
local RMShared         = require(Modules.RestaurantManager)
local Constants        = require(Modules.Constants)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceObject  = Remotes:WaitForChild("PlaceObject")   -- RemoteFunction
local DeleteObject = Remotes:WaitForChild("DeleteObject")  -- RemoteEvent
local Expand       = Remotes:WaitForChild("Expand")        -- RemoteFunction

-- [userId] = { plotPart, placedObjects = [{id, type, model}] }
local restaurantState = {}

local function getDP()
	return require(game:GetService("ServerScriptService"):WaitForChild("DataPersistenceBridge"))
end

local function getMS()
	return require(game:GetService("ServerScriptService"):WaitForChild("MoneyServerBridge"))
end

-- ── Build a furniture model ────────────────────────────────────────────────────

local FURNITURE_SIZES = {
	KitchenCounter = Vector3.new(4, 3, 2),
	DiningTable    = Vector3.new(4, 2, 4),
	CashierStation = Vector3.new(3, 3, 2),
	TrashBin       = Vector3.new(1, 2, 1),
	Door           = Vector3.new(3, 5, 1),
	Wall           = Vector3.new(4, 5, 0.5),
	FloorTile      = Vector3.new(4, 0.2, 4),
}

local function makeFurnitureModel(furnitureType, cframe)
	local templates = ServerStorage:FindFirstChild("FurnitureModels")
	local template  = templates and templates:FindFirstChild(furnitureType)
	local part
	if template then
		part = template:Clone()
	else
		part        = Instance.new("Part")
		part.Name   = furnitureType
		part.Size   = FURNITURE_SIZES[furnitureType] or Vector3.new(2, 2, 2)
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.BrickColor = BrickColor.new("Medium stone grey")
	end
	part.CFrame  = cframe
	part.Parent  = workspace
	return part
end

-- ── PlaceObject handler ────────────────────────────────────────────────────────

PlaceObject.OnServerInvoke = function(player, furnitureType, rawPos, rotationN)
	local data = getDP().get(player)
	if not data then return false, "no data" end

	-- Validate furniture type
	if not Constants.FURNITURE[furnitureType] then
		return false, "unknown type"
	end

	local state = restaurantState[player.UserId]
	if not state then return false, "no plot" end

	-- Snap and bounds check
	local snapped = RMShared.snapToGrid(rawPos)
	if not RMShared.isInBounds(snapped, state.plotOrigin, data.restaurant.expansionLevel) then
		return false, "out of bounds"
	end

	-- Object cap
	if not RMShared.canPlaceMore(#state.placedObjects, data.restaurant.expansionLevel) then
		return false, "at capacity"
	end

	-- Check afford
	local cost = RMShared.getBuildCost(furnitureType)
	local MS   = getMS()
	if not MS.spend(player, cost, "build_" .. furnitureType) then
		return false, "insufficient funds"
	end

	-- Overlap check
	local newSize = RMShared.rotateSize(FURNITURE_SIZES[furnitureType] or Vector3.new(2,2,2), rotationN or 0)
	local newRect = { pos = snapped, size = newSize }
	for _, obj in ipairs(state.placedObjects) do
		local objSize = RMShared.rotateSize(FURNITURE_SIZES[obj.type] or Vector3.new(2,2,2), obj.rotationN or 0)
		if RMShared.overlaps(newRect, { pos = obj.pos, size = objSize }) then
			MS.earn(player, cost) -- refund
			return false, "overlapping"
		end
	end

	-- Place
	local rotAngle = (rotationN or 0) * 90
	local cf = CFrame.new(snapped) * CFrame.Angles(0, math.rad(rotAngle), 0)
	local model = makeFurnitureModel(furnitureType, cf)

	local objId = #state.placedObjects + 1
	table.insert(state.placedObjects, {
		id        = objId,
		type      = furnitureType,
		pos       = snapped,
		rotationN = rotationN or 0,
		model     = model,
	})

	-- Persist layout
	table.insert(data.restaurant.objects, {
		id        = objId,
		type      = furnitureType,
		x         = snapped.X,
		y         = snapped.Y,
		z         = snapped.Z,
		rotation  = rotationN or 0,
	})

	return true, objId
end

-- ── DeleteObject handler ───────────────────────────────────────────────────────

DeleteObject.OnServerEvent:Connect(function(player, objId)
	local state = restaurantState[player.UserId]
	if not state then return end
	local data = getDP().get(player)

	for i, obj in ipairs(state.placedObjects) do
		if obj.id == objId then
			local refund = RMShared.getRefundAmount(obj.type)
			getMS().earn(player, refund)
			if obj.model then obj.model:Destroy() end
			table.remove(state.placedObjects, i)

			-- Remove from persisted data
			for j, saved in ipairs(data.restaurant.objects) do
				if saved.id == objId then
					table.remove(data.restaurant.objects, j)
					break
				end
			end
			break
		end
	end
end)

-- ── Expand handler ─────────────────────────────────────────────────────────────

Expand.OnServerInvoke = function(player)
	local data  = getDP().get(player)
	if not data then return false, "no data" end
	local curLv = data.restaurant.expansionLevel
	local cost  = RMShared.getExpansionCost(curLv)
	if not cost then return false, "max size" end

	if not getMS().spend(player, cost, "expansion") then
		return false, "insufficient funds"
	end

	data.restaurant.expansionLevel = curLv + 1
	-- Resize the plot part
	local state = restaurantState[player.UserId]
	if state and state.plotPart then
		local newSize = Constants.EXPANSIONS[curLv + 1].size
		state.plotPart.Size = Vector3.new(newSize, 0.5, newSize)
	end

	return true, curLv + 1
end

-- ── Initialize on player join ─────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	-- Wait for data to load
	local loadEvent = ReplicatedStorage:WaitForChild("DataLoaded_" .. player.UserId, 30)
	if not loadEvent then return end
	loadEvent.Event:Wait()

	local data = getDP().get(player)
	if not data then return end

	-- Create plot
	local plotPart       = Instance.new("Part")
	plotPart.Name        = player.Name .. "_Plot"
	plotPart.Anchored    = true
	plotPart.CanCollide  = false
	plotPart.Transparency= 0.8
	plotPart.Material    = Enum.Material.SmoothPlastic
	plotPart.BrickColor  = BrickColor.new("Bright yellow")
	local initSize       = Constants.EXPANSIONS[data.restaurant.expansionLevel].size
	plotPart.Size        = Vector3.new(initSize, 0.5, initSize)

	-- Assign unique plot position (offset by UserId mod for multiplayer spacing)
	local slot = (player.UserId % 20) * 35
	local origin = Vector3.new(slot, 0, 0)
	plotPart.Position = origin
	plotPart.Parent   = workspace

	restaurantState[player.UserId] = {
		plotOrigin   = origin,
		plotPart     = plotPart,
		placedObjects= {},
	}

	-- Restore saved objects
	for _, saved in ipairs(data.restaurant.objects) do
		local pos     = Vector3.new(saved.x, saved.y, saved.z)
		local rotAngle= (saved.rotation or 0) * 90
		local cf      = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotAngle), 0)
		local model   = makeFurnitureModel(saved.type, cf)
		table.insert(restaurantState[player.UserId].placedObjects, {
			id        = saved.id,
			type      = saved.type,
			pos       = pos,
			rotationN = saved.rotation or 0,
			model     = model,
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local state = restaurantState[player.UserId]
	if not state then return end
	for _, obj in ipairs(state.placedObjects) do
		if obj.model then obj.model:Destroy() end
	end
	if state.plotPart then state.plotPart:Destroy() end
	restaurantState[player.UserId] = nil
end)

return {}
