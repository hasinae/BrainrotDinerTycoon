-- InGameHUD.client.lua
-- Manages the always-visible HUD: balance, level, employee list, notifications.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local UpdateBalance     = Remotes:WaitForChild("UpdateBalance")
local Notification      = Remotes:WaitForChild("Notification")
local UpdateLeaderboard = Remotes:WaitForChild("UpdateLeaderboard")

-- ── Build ScreenGui ────────────────────────────────────────────────────────────

local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "InGameHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent       = playerGui

-- ── Money counter (top left) ──────────────────────────────────────────────────

local moneyFrame  = Instance.new("Frame")
moneyFrame.Size   = UDim2.new(0, 200, 0, 50)
moneyFrame.Position = UDim2.new(0, 10, 0, 10)
moneyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
moneyFrame.BackgroundTransparency = 0.3
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = moneyFrame
end

local moneyLabel  = Instance.new("TextLabel")
moneyLabel.Size   = UDim2.new(1, -10, 1, 0)
moneyLabel.Position = UDim2.new(0, 10, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
moneyLabel.TextSize   = 22
moneyLabel.Font       = Enum.Font.GothamBold
moneyLabel.Text       = "💰 0 IGC"
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent     = moneyFrame

-- ── Level display (top center) ────────────────────────────────────────────────

local levelFrame    = Instance.new("Frame")
levelFrame.Size     = UDim2.new(0, 200, 0, 50)
levelFrame.Position = UDim2.new(0.5, -100, 0, 10)
levelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
levelFrame.BackgroundTransparency = 0.3
levelFrame.BorderSizePixel = 0
levelFrame.Parent = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = levelFrame
end

local levelLabel  = Instance.new("TextLabel")
levelLabel.Size   = UDim2.new(1, 0, 0.6, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.TextSize   = 18
levelLabel.Font       = Enum.Font.GothamBold
levelLabel.Text       = "LEVEL 1"
levelLabel.Parent     = levelFrame

local xpBar = Instance.new("Frame")
xpBar.Size  = UDim2.new(0.9, 0, 0.2, 0)
xpBar.Position = UDim2.new(0.05, 0, 0.75, 0)
xpBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
xpBar.BorderSizePixel = 0
xpBar.Parent = levelFrame
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = xpBar
end

local xpFill = Instance.new("Frame")
xpFill.Size  = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
xpFill.BorderSizePixel  = 0
xpFill.Parent = xpBar
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = xpFill
end

-- ── Employee sidebar (left) ────────────────────────────────────────────────────

local empPanel   = Instance.new("ScrollingFrame")
empPanel.Name    = "EmployeePanel"
empPanel.Size    = UDim2.new(0, 210, 0.5, 0)
empPanel.Position= UDim2.new(0, 10, 0.5, -10)
empPanel.AnchorPoint = Vector2.new(0, 1)
empPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
empPanel.BackgroundTransparency = 0.2
empPanel.BorderSizePixel = 0
empPanel.ScrollBarThickness = 4
empPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
empPanel.Parent  = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = empPanel
end
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent  = empPanel
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		empPanel.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
end

local empTitle = Instance.new("TextLabel")
empTitle.Size  = UDim2.new(1, 0, 0, 28)
empTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
empTitle.BorderSizePixel  = 0
empTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
empTitle.TextSize   = 14
empTitle.Font       = Enum.Font.GothamBold
empTitle.Text       = " Employees"
empTitle.TextXAlignment = Enum.TextXAlignment.Left
empTitle.Parent     = empPanel

-- ── Quick buttons (bottom right) ──────────────────────────────────────────────

local function makeQuickButton(labelText, xOffset, callback)
	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(0, 100, 0, 40)
	btn.Position = UDim2.new(1, xOffset, 1, -50)
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
	btn.BorderSizePixel  = 0
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize   = 15
	btn.Font       = Enum.Font.GothamBold
	btn.Text       = labelText
	btn.Parent     = screenGui
	do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
	end
	btn.MouseButton1Click:Connect(callback)
	return btn
end

makeQuickButton("Shop", -10, function()
	local shopGui = playerGui:FindFirstChild("ShopUI")
	if shopGui then shopGui.Enabled = not shopGui.Enabled end
end)

makeQuickButton("Build", -120, function()
	local buildGui = playerGui:FindFirstChild("BuildMenu")
	if buildGui then buildGui.Enabled = not buildGui.Enabled end
end)

makeQuickButton("Board", -230, function()
	local lbGui = playerGui:FindFirstChild("LeaderboardUI")
	if lbGui then lbGui.Enabled = not lbGui.Enabled end
end)

-- ── Notification toast (top right) ────────────────────────────────────────────

local notifLabel = Instance.new("TextLabel")
notifLabel.Size  = UDim2.new(0, 280, 0, 44)
notifLabel.Position = UDim2.new(1, -290, 0, 10)
notifLabel.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
notifLabel.BackgroundTransparency = 0.2
notifLabel.BorderSizePixel = 0
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextSize   = 15
notifLabel.Font       = Enum.Font.Gotham
notifLabel.Text       = ""
notifLabel.Visible    = false
notifLabel.Parent     = screenGui
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notifLabel
end

local function showNotif(text, duration)
	notifLabel.Text    = text
	notifLabel.Visible = true
	task.delay(duration or 3, function()
		notifLabel.Visible = false
	end)
end

-- ── Remote event handlers ─────────────────────────────────────────────────────

UpdateBalance.OnClientEvent:Connect(function(balance, totalEarned)
	moneyLabel.Text = string.format("💰 %d IGC", balance)
end)

Notification.OnClientEvent:Connect(function(text)
	showNotif(text)
end)

-- ── Rebuild employee list ─────────────────────────────────────────────────────

local FireEmployee = Remotes:WaitForChild("FireEmployee")

local function rebuildEmployeeList(employees)
	-- Remove old rows (keep title)
	for _, child in ipairs(empPanel:GetChildren()) do
		if child:IsA("Frame") and child.Name:sub(1, 4) == "Emp_" then
			child:Destroy()
		end
	end
	for _, emp in ipairs(employees or {}) do
		local row = Instance.new("Frame")
		row.Name  = "Emp_" .. emp.id
		row.Size  = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		row.BorderSizePixel  = 0
		row.Parent = empPanel
		do
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = row
		end

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size  = UDim2.new(0.65, 0, 0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize   = 13
		nameLabel.Font       = Enum.Font.GothamBold
		nameLabel.Text       = emp.name or emp.type
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Position   = UDim2.new(0, 6, 0, 2)
		nameLabel.Parent     = row

		local salaryLabel = Instance.new("TextLabel")
		salaryLabel.Size   = UDim2.new(0.65, 0, 0.4, 0)
		salaryLabel.Position = UDim2.new(0, 6, 0.55, 0)
		salaryLabel.BackgroundTransparency = 1
		salaryLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		salaryLabel.TextSize   = 11
		salaryLabel.Font       = Enum.Font.Gotham
		salaryLabel.Text       = (emp.salary or 0) .. " IGC/min"
		salaryLabel.TextXAlignment = Enum.TextXAlignment.Left
		salaryLabel.Parent     = row

		local fireBtn = Instance.new("TextButton")
		fireBtn.Size  = UDim2.new(0, 42, 0, 28)
		fireBtn.Position = UDim2.new(1, -48, 0.5, -14)
		fireBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		fireBtn.BorderSizePixel  = 0
		fireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		fireBtn.TextSize   = 12
		fireBtn.Font       = Enum.Font.GothamBold
		fireBtn.Text       = "Fire"
		fireBtn.Parent     = row
		do
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = fireBtn
		end
		local empId = emp.id
		fireBtn.MouseButton1Click:Connect(function()
			FireEmployee:FireServer(empId)
		end)
	end
end

-- ── Level bar update ──────────────────────────────────────────────────────────

local function updateLevel(level, dishesServed)
	levelLabel.Text = "LEVEL " .. level
	local progress = (dishesServed % 10) / 10
	xpFill.Size = UDim2.new(progress, 0, 1, 0)
end

-- ── Initial data fetch ─────────────────────────────────────────────────────────

local GetPlayerData = Remotes:WaitForChild("GetPlayerData")
task.spawn(function()
	task.wait(2)
	local data = GetPlayerData:InvokeServer()
	if data then
		moneyLabel.Text = string.format("💰 %d IGC", data.money.currentBalance)
		updateLevel(data.level or 1, data.dishesServed or 0)
		rebuildEmployeeList(data.employees)
		showNotif("Welcome back! " .. (data.employees and #data.employees or 0) .. " employees on shift.")
	end
end)
