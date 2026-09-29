-- BuildMenu.client.lua
-- Drag-to-place building interface with grid snap, rotate (R), delete (X).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local mouse     = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local PlaceObject  = Remotes:WaitForChild("PlaceObject")
local DeleteObject = Remotes:WaitForChild("DeleteObject")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local Constants    = require(Modules.Constants)
local RMShared     = require(Modules.RestaurantManager)

-- ── Build GUI ─────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name  = "BuildMenu"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent  = playerGui

local panel = Instance.new("Frame")
panel.Size  = UDim2.new(0, 350, 0, 420)
panel.Position = UDim2.new(0.5, -175, 1, -430)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.BorderSizePixel  = 0
panel.Parent = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
end

local title = Instance.new("TextLabel")
title.Size  = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.BorderSizePixel  = 0
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize   = 17
title.Font       = Enum.Font.GothamBold
title.Text       = "Build Menu  (R = Rotate, X = Delete)"
title.Parent     = panel
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = title
end

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize   = 18
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.Text       = "×"
closeBtn.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = closeBtn end
closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local grid = Instance.new("ScrollingFrame")
grid.Size  = UDim2.new(1, -10, 1, -46)
grid.Position = UDim2.new(0, 5, 0, 40)
grid.BackgroundTransparency = 1
grid.BorderSizePixel  = 0
grid.ScrollBarThickness = 4
grid.CanvasSize = UDim2.new(0, 0, 0, 0)
grid.Parent = panel
do
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 100, 0, 90)
	layout.CellPadding = UDim2.new(0, 6, 0, 6)
	layout.Parent = grid
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		grid.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
end

-- ── Ghost preview part ────────────────────────────────────────────────────────

local ghostPart = Instance.new("Part")
ghostPart.Anchored    = true
ghostPart.CanCollide  = false
ghostPart.Transparency = 0.55
ghostPart.BrickColor  = BrickColor.new("Bright blue")
ghostPart.Material    = Enum.Material.Neon
ghostPart.Size        = Vector3.new(2, 2, 2)
ghostPart.Parent      = workspace

local selectedType  = nil
local rotationN     = 0   -- 0-3 (×90°)

local FURNITURE_SIZES = {
	KitchenCounter = Vector3.new(4, 3, 2),
	DiningTable    = Vector3.new(4, 2, 4),
	CashierStation = Vector3.new(3, 3, 2),
	TrashBin       = Vector3.new(1, 2, 1),
	Door           = Vector3.new(3, 5, 1),
	Wall           = Vector3.new(4, 5, 0.5),
	FloorTile      = Vector3.new(4, 0.2, 4),
}

-- ── Populate grid ─────────────────────────────────────────────────────────────

for furnitureType, info in pairs(Constants.FURNITURE) do
	local cell = Instance.new("TextButton")
	cell.Size  = UDim2.new(0, 100, 0, 90)
	cell.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	cell.BorderSizePixel  = 0
	cell.TextColor3 = Color3.fromRGB(255, 255, 255)
	cell.TextSize   = 13
	cell.Font       = Enum.Font.Gotham
	cell.Text       = furnitureType .. "\n" .. info.cost .. " IGC"
	cell.TextWrapped = true
	cell.Parent     = grid
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = cell end

	local ft = furnitureType
	cell.MouseButton1Click:Connect(function()
		selectedType = ft
		ghostPart.Size = RMShared.rotateSize(FURNITURE_SIZES[ft] or Vector3.new(2,2,2), rotationN)
		ghostPart.Visible = true
	end)
end

-- ── Ghost follows mouse ───────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
	if not selectedType then
		ghostPart.Visible = false
		return
	end
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, RaycastParams.new())
	if result then
		local snapped = RMShared.snapToGrid(result.Position)
		snapped = Vector3.new(snapped.X, result.Position.Y + ghostPart.Size.Y / 2, snapped.Z)
		ghostPart.CFrame = CFrame.new(snapped) * CFrame.Angles(0, math.rad(rotationN * 90), 0)
		ghostPart.Visible = true
	end
end)

-- ── Input handling ────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- R = rotate
	if input.KeyCode == Enum.KeyCode.R and selectedType then
		rotationN = (rotationN + 1) % 4
		ghostPart.Size = RMShared.rotateSize(FURNITURE_SIZES[selectedType] or Vector3.new(2,2,2), rotationN)
	end

	-- X = cancel / delete mode
	if input.KeyCode == Enum.KeyCode.X then
		selectedType   = nil
		ghostPart.Visible = false

		-- Attempt to delete object under mouse
		local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
		local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, RaycastParams.new())
		if result and result.Instance then
			local obj = result.Instance
			local objId = obj:GetAttribute("FurnitureId")
			if objId then
				DeleteObject:FireServer(objId)
			end
		end
	end

	-- Left click = place
	if input.UserInputType == Enum.UserInputType.MouseButton1 and selectedType then
		if screenGui.Enabled then
			local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
			local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, RaycastParams.new())
			if result then
				local snapped = RMShared.snapToGrid(result.Position)
				local ok, objId = PlaceObject:InvokeServer(selectedType, snapped, rotationN)
				if not ok then
					-- show error feedback (flash ghost red)
					local orig = ghostPart.BrickColor
					ghostPart.BrickColor = BrickColor.new("Bright red")
					task.delay(0.3, function() ghostPart.BrickColor = orig end)
				end
			end
		end
	end
end)
