-- LeaderboardUI.client.lua
-- Displays top-100 leaderboard boards; refreshes when server pushes data.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local UpdateLeaderboard = Remotes:WaitForChild("UpdateLeaderboard")

local Modules   = ReplicatedStorage:WaitForChild("Modules")
local LBManager = require(Modules.LeaderboardManager)

-- ── Root GUI ──────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name  = "LeaderboardUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent  = playerGui

local panel = Instance.new("Frame")
panel.Size  = UDim2.new(0, 520, 0, 500)
panel.Position = UDim2.new(0.5, -260, 0.5, -250)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BorderSizePixel  = 0
panel.Parent = screenGui
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = panel end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, 0, 0, 44)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
titleLabel.BorderSizePixel  = 0
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextSize   = 22
titleLabel.Font       = Enum.Font.GothamBold
titleLabel.Text       = "Leaderboards"
titleLabel.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = titleLabel end

local closeBtn = Instance.new("TextButton")
closeBtn.Size  = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize   = 20
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.Text       = "×"
closeBtn.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = closeBtn end
closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

-- ── Tab bar ───────────────────────────────────────────────────────────────────

local BOARD_KEYS = { "TopEarners", "WeeklyEarners", "FastestProgression", "Efficiency" }
local BOARD_LABELS = {
	TopEarners         = "All-Time",
	WeeklyEarners      = "Weekly",
	FastestProgression = "Fastest",
	Efficiency         = "Efficiency",
}

local tabBar = Instance.new("Frame")
tabBar.Size  = UDim2.new(1, -10, 0, 34)
tabBar.Position = UDim2.new(0, 5, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.Parent = panel
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.Parent  = tabBar
end

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size  = UDim2.new(1, -10, 1, -92)
listFrame.Position = UDim2.new(0, 5, 0, 88)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = panel
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent  = listFrame
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
	end)
end

local currentData = {}
local activeBoard = "TopEarners"
local tabBtns     = {}

local function renderBoard(boardKey)
	for _, child in ipairs(listFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local rows = currentData[boardKey] or {}
	for _, row in ipairs(rows) do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size  = UDim2.new(1, 0, 0, 34)
		rowFrame.BackgroundColor3 = row.rank % 2 == 0
			and Color3.fromRGB(30, 30, 45) or Color3.fromRGB(38, 38, 55)
		rowFrame.BorderSizePixel  = 0
		rowFrame.Parent = listFrame
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = rowFrame end

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size  = UDim2.new(0, 40, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.TextColor3 = row.rank <= 3
			and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 180, 200)
		rankLabel.TextSize   = 14
		rankLabel.Font       = Enum.Font.GothamBold
		rankLabel.Text       = "#" .. row.rank
		rankLabel.Parent     = rowFrame

		local userLabel = Instance.new("TextLabel")
		userLabel.Size  = UDim2.new(0.5, 0, 1, 0)
		userLabel.Position = UDim2.new(0, 44, 0, 0)
		userLabel.BackgroundTransparency = 1
		userLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
		userLabel.TextSize   = 13
		userLabel.Font       = Enum.Font.Gotham
		userLabel.Text       = tostring(row.userId)
		userLabel.TextXAlignment = Enum.TextXAlignment.Left
		userLabel.Parent     = rowFrame

		local valLabel = Instance.new("TextLabel")
		valLabel.Size  = UDim2.new(0, 90, 1, 0)
		valLabel.Position = UDim2.new(1, -95, 0, 0)
		valLabel.BackgroundTransparency = 1
		valLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
		valLabel.TextSize   = 13
		valLabel.Font       = Enum.Font.GothamBold
		valLabel.Text       = tostring(row.value)
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.Parent     = rowFrame

		-- Badge
		local badge = LBManager.getBadge(row.rank)
		if badge then
			local badgeLabel = Instance.new("TextLabel")
			badgeLabel.Size  = UDim2.new(0, 70, 0, 18)
			badgeLabel.Position = UDim2.new(0, 160, 0.5, -9)
			badgeLabel.BackgroundColor3 = Color3.fromRGB(180, 130, 0)
			badgeLabel.BorderSizePixel  = 0
			badgeLabel.TextColor3 = Color3.fromRGB(255,255,255)
			badgeLabel.TextSize   = 10
			badgeLabel.Font       = Enum.Font.GothamBold
			badgeLabel.Text       = badge
			badgeLabel.Parent     = rowFrame
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = badgeLabel end
		end
	end

	if #rows == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size  = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.TextColor3 = Color3.fromRGB(120,120,140)
		empty.TextSize   = 15
		empty.Font       = Enum.Font.Gotham
		empty.Text       = "No data yet — start serving dishes!"
		empty.Parent     = listFrame
	end
end

local function selectBoard(key)
	activeBoard = key
	for k, btn in pairs(tabBtns) do
		btn.BackgroundColor3 = k == key
			and Color3.fromRGB(60,120,220) or Color3.fromRGB(45,45,65)
	end
	renderBoard(key)
end

for _, key in ipairs(BOARD_KEYS) do
	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(0, 112, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	btn.BorderSizePixel  = 0
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize   = 13
	btn.Font       = Enum.Font.GothamBold
	btn.Text       = BOARD_LABELS[key] or key
	btn.Parent     = tabBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn end
	tabBtns[key] = btn
	local k = key
	btn.MouseButton1Click:Connect(function() selectBoard(k) end)
end

UpdateLeaderboard.OnClientEvent:Connect(function(allData)
	currentData = allData
	renderBoard(activeBoard)
end)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screenGui.Enabled then selectBoard("TopEarners") end
end)
