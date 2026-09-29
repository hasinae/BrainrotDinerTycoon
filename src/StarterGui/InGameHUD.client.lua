-- InGameHUD.client.lua  (LocalScript)
-- Colorful brainrot-themed HUD

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local UpdateBalance   = Remotes:WaitForChild("UpdateBalance")
local UpdateProgress  = Remotes:WaitForChild("UpdateProgress")
local Notification    = Remotes:WaitForChild("Notification")
local GetPlayerData   = Remotes:WaitForChild("GetPlayerData")
local FireEmployee    = Remotes:WaitForChild("FireEmployee")

-- ── Palette ───────────────────────────────────────────────────────────────────
local HOT_PINK    = Color3.fromRGB(255, 20, 147)
local NEON_BLUE   = Color3.fromRGB(0, 180, 255)
local GOLD        = Color3.fromRGB(255, 200, 0)
local NEON_GREEN  = Color3.fromRGB(0, 255, 120)
local DARK_BG     = Color3.fromRGB(15, 10, 25)
local CARD_BG     = Color3.fromRGB(30, 18, 50)
local PANEL_BG    = Color3.fromRGB(20, 12, 35)

local EMP_COLORS = {
	tung_tung_sahur      = Color3.fromRGB(255, 120, 0),
	tralalero_tralala    = Color3.fromRGB(100, 180, 255),
	ballerina_cappuccina = Color3.fromRGB(255, 80, 200),
}
local EMP_ICONS = {
	tung_tung_sahur      = "💪",
	tralalero_tralala    = "🤖",
	ballerina_cappuccina = "🩰",
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or HOT_PINK
	s.Thickness = thickness or 2
	s.Parent = parent
	return s
end

local function label(parent, text, size, color, font, bold)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 16
	l.TextColor3 = color or Color3.new(1,1,1)
	l.Font = bold ~= false and Enum.Font.GothamBold or Enum.Font.Gotham
	l.Parent = parent
	return l
end

local function gradient(parent, color0, color1, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(color0, color1)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

-- ── ScreenGui ────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name = "InGameHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- ── Money frame (top left) ────────────────────────────────────────────────────
local moneyFrame = Instance.new("Frame")
moneyFrame.Size = UDim2.new(0, 220, 0, 56)
moneyFrame.Position = UDim2.new(0, 12, 0, 12)
moneyFrame.BackgroundColor3 = DARK_BG
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screen
corner(moneyFrame, 14)
stroke(moneyFrame, GOLD, 2)
gradient(moneyFrame, Color3.fromRGB(40, 20, 0), Color3.fromRGB(15, 10, 25))

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, -8, 1, 0)
moneyLabel.Position = UDim2.new(0, 8, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 500 IGC"
moneyLabel.TextSize = 22
moneyLabel.TextColor3 = GOLD
moneyLabel.Font = Enum.Font.GothamBlack
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyFrame

-- Subtle pulse on money label
local function pulseMoney()
	local info = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(moneyLabel, info, {TextSize = 26}):Play()
	task.delay(0.15, function()
		TweenService:Create(moneyLabel, info, {TextSize = 22}):Play()
	end)
end

-- ── Level frame (top center) ──────────────────────────────────────────────────
local levelFrame = Instance.new("Frame")
levelFrame.Size = UDim2.new(0, 220, 0, 60)
levelFrame.Position = UDim2.new(0.5, -110, 0, 12)
levelFrame.BackgroundColor3 = DARK_BG
levelFrame.BorderSizePixel = 0
levelFrame.Parent = screen
corner(levelFrame, 14)
stroke(levelFrame, NEON_BLUE, 2)
gradient(levelFrame, Color3.fromRGB(0, 20, 50), Color3.fromRGB(15, 10, 25))

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, 0, 0.55, 0)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "⚡ LEVEL 1"
levelLabel.TextSize = 20
levelLabel.TextColor3 = NEON_BLUE
levelLabel.Font = Enum.Font.GothamBlack
levelLabel.Parent = levelFrame

local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(0.88, 0, 0, 8)
xpBarBg.Position = UDim2.new(0.06, 0, 0.78, 0)
xpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
xpBarBg.BorderSizePixel = 0
xpBarBg.Parent = levelFrame
corner(xpBarBg, 4)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = NEON_BLUE
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBarBg
corner(xpFill, 4)
gradient(xpFill, NEON_BLUE, NEON_GREEN)

-- ── Employee panel (left side) ────────────────────────────────────────────────
local empPanel = Instance.new("ScrollingFrame")
empPanel.Name = "EmployeePanel"
empPanel.Size = UDim2.new(0, 220, 0.42, 0)
empPanel.Position = UDim2.new(0, 12, 0.5, -8)
empPanel.AnchorPoint = Vector2.new(0, 1)
empPanel.BackgroundColor3 = PANEL_BG
empPanel.BorderSizePixel = 0
empPanel.ScrollBarThickness = 3
empPanel.ScrollBarImageColor3 = HOT_PINK
empPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
empPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
empPanel.Parent = screen
corner(empPanel, 14)
stroke(empPanel, HOT_PINK, 2)

local empListLayout = Instance.new("UIListLayout")
empListLayout.Padding = UDim.new(0, 6)
empListLayout.Parent = empPanel

local empPadding = Instance.new("UIPadding")
empPadding.PaddingTop    = UDim.new(0, 6)
empPadding.PaddingLeft   = UDim.new(0, 6)
empPadding.PaddingRight  = UDim.new(0, 6)
empPadding.PaddingBottom = UDim.new(0, 6)
empPadding.Parent = empPanel

-- Panel header
local empHeader = Instance.new("Frame")
empHeader.Size = UDim2.new(1, 0, 0, 32)
empHeader.BackgroundColor3 = HOT_PINK
empHeader.BorderSizePixel = 0
empHeader.Parent = empPanel
corner(empHeader, 8)

local empHeaderLabel = label(empHeader, "👥 EMPLOYEES", 14, Color3.new(1,1,1), nil, true)
empHeaderLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ── Quick action buttons (bottom right) ──────────────────────────────────────
local BTN_DEFS = {
	{ text = "🛍 SHOP",   color = HOT_PINK,   target = "ShopUI",         x = -10   },
	{ text = "🔨 BUILD",  color = NEON_BLUE,  target = "BuildMenu",      x = -122  },
	{ text = "🏆 BOARD",  color = GOLD,       target = "LeaderboardUI",  x = -234  },
}

for _, def in ipairs(BTN_DEFS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 104, 0, 46)
	btn.Position = UDim2.new(1, def.x, 1, -58)
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.BackgroundColor3 = def.color
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.fromRGB(15, 10, 25)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBlack
	btn.Text = def.text
	btn.Parent = screen
	corner(btn, 12)

	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new(def.color, def.color:Lerp(Color3.new(1,1,1), 0.25))
	btnGrad.Rotation = 90
	btnGrad.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local g = playerGui:FindFirstChild(def.target)
		if g then g.Enabled = not g.Enabled end
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, 112, 0, 50)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, 104, 0, 46)}):Play()
	end)
end

-- ── Toast notifications (top right) ──────────────────────────────────────────
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.new(0, 290, 0, 50)
toastFrame.Position = UDim2.new(1, -302, 0, 12)
toastFrame.BackgroundColor3 = NEON_GREEN
toastFrame.BorderSizePixel = 0
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = screen
corner(toastFrame, 12)

local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(1, -12, 1, 0)
toastLabel.Position = UDim2.new(0, 10, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3 = Color3.new(1, 1, 1)
toastLabel.TextSize = 15
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextXAlignment = Enum.TextXAlignment.Left
toastLabel.Text = ""
toastLabel.Parent = toastFrame

local function showToast(text, color)
	toastFrame.BackgroundColor3 = color or NEON_GREEN
	toastLabel.Text = text
	toastFrame.BackgroundTransparency = 0

	TweenService:Create(toastFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Position = UDim2.new(1, -302, 0, 12)
	}):Play()

	task.delay(3, function()
		TweenService:Create(toastFrame, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()
	end)
end

-- ── Rebuild employee cards ────────────────────────────────────────────────────
local function buildEmployeeCard(emp)
	local card = Instance.new("Frame")
	card.Name = "Emp_" .. emp.id
	card.Size = UDim2.new(1, 0, 0, 66)
	card.BackgroundColor3 = CARD_BG
	card.BorderSizePixel = 0
	card.Parent = empPanel
	corner(card, 10)

	local empColor = EMP_COLORS[emp.type] or HOT_PINK
	local empIcon  = EMP_ICONS[emp.type] or "🧑"
	stroke(card, empColor, 1)

	-- Color accent strip on left
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 4, 1, -8)
	accent.Position = UDim2.new(0, 0, 0, 4)
	accent.BackgroundColor3 = empColor
	accent.BorderSizePixel = 0
	accent.Parent = card
	corner(accent, 2)

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 36, 0, 36)
	iconLabel.Position = UDim2.new(0, 8, 0.5, -18)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = empIcon
	iconLabel.TextSize = 24
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = card

	-- Name
	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(0.55, 0, 0, 22)
	nameL.Position = UDim2.new(0, 50, 0, 8)
	nameL.BackgroundTransparency = 1
	nameL.Text = emp.name or emp.type
	nameL.TextSize = 13
	nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.Font = Enum.Font.GothamBold
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.TextTruncate = Enum.TextTruncate.AtEnd
	nameL.Parent = card

	-- Salary
	local salaryL = Instance.new("TextLabel")
	salaryL.Size = UDim2.new(0.55, 0, 0, 18)
	salaryL.Position = UDim2.new(0, 50, 0, 30)
	salaryL.BackgroundTransparency = 1
	salaryL.Text = "💸 " .. (emp.salary or "?") .. " IGC/min"
	salaryL.TextSize = 11
	salaryL.TextColor3 = Color3.fromRGB(180, 160, 210)
	salaryL.Font = Enum.Font.Gotham
	salaryL.TextXAlignment = Enum.TextXAlignment.Left
	salaryL.Parent = card

	-- Fire button
	local fireBtn = Instance.new("TextButton")
	fireBtn.Size = UDim2.new(0, 44, 0, 30)
	fireBtn.Position = UDim2.new(1, -50, 0.5, -15)
	fireBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	fireBtn.BorderSizePixel = 0
	fireBtn.TextColor3 = Color3.new(1, 1, 1)
	fireBtn.TextSize = 12
	fireBtn.Font = Enum.Font.GothamBold
	fireBtn.Text = "🔥"
	fireBtn.Parent = card
	corner(fireBtn, 6)

	local eid = emp.id
	fireBtn.MouseButton1Click:Connect(function()
		FireEmployee:FireServer(eid)
		local existing = empPanel:FindFirstChild("Emp_" .. eid)
		if existing then existing:Destroy() end
	end)

	return card
end

local function rebuildEmployeeList(employees)
	for _, child in ipairs(empPanel:GetChildren()) do
		if child:IsA("Frame") and child.Name:sub(1, 4) == "Emp_" then
			child:Destroy()
		end
	end
	if not employees or #employees == 0 then
		local emptyL = Instance.new("TextLabel")
		emptyL.Name = "Emp_empty"
		emptyL.Size = UDim2.new(1, 0, 0, 40)
		emptyL.BackgroundTransparency = 1
		emptyL.Text = "No employees yet!\nHire from Build menu."
		emptyL.TextSize = 12
		emptyL.TextColor3 = Color3.fromRGB(150, 130, 170)
		emptyL.Font = Enum.Font.Gotham
		emptyL.TextWrapped = true
		emptyL.Parent = empPanel
		return
	end
	for _, emp in ipairs(employees) do
		buildEmployeeCard(emp)
	end
end

-- ── Level bar update ──────────────────────────────────────────────────────────
local function updateLevel(level, dishesServed)
	levelLabel.Text = "⚡ LEVEL " .. level
	local progress = (dishesServed % 10) / 10
	TweenService:Create(xpFill, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
		Size = UDim2.new(progress, 0, 1, 0)
	}):Play()
end

-- ── Remote handlers ───────────────────────────────────────────────────────────
UpdateBalance.OnClientEvent:Connect(function(balance, _totalEarned)
	moneyLabel.Text = "💰 " .. tostring(balance) .. " IGC"
	pulseMoney()
end)

UpdateProgress.OnClientEvent:Connect(function(level, dishesServed)
	updateLevel(level, dishesServed)
end)

Notification.OnClientEvent:Connect(function(text)
	local isGood = text:find("Served") or text:find("Hired") or text:find("Milestone")
		or text:find("Welcome") or text:find("Order:") or text:find("expanded")
	showToast(text, isGood and NEON_GREEN or Color3.fromRGB(200, 60, 60))
	-- Mirror order-related events to the ticker
	if text:find("Order:") or text:find("Served!") or text:find("gave up") then
		orderLabel.Text = text
	end
end)

-- ── Order ticker (top right corner) ──────────────────────────────────────────
local orderFrame = Instance.new("Frame")
orderFrame.Size = UDim2.new(0, 200, 0, 44)
orderFrame.Position = UDim2.new(1, -214, 0, 12)
orderFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
orderFrame.BorderSizePixel = 0
orderFrame.Parent = screen
corner(orderFrame, 10)
stroke(orderFrame, Color3.fromRGB(255, 200, 0), 2)
gradient(orderFrame, Color3.fromRGB(40, 30, 0), Color3.fromRGB(20, 12, 35))

local orderLabel = Instance.new("TextLabel")
orderLabel.Size = UDim2.new(1, -8, 1, 0)
orderLabel.Position = UDim2.new(0, 8, 0, 0)
orderLabel.BackgroundTransparency = 1
orderLabel.Text = "🍽️ Waiting for customers..."
orderLabel.TextSize = 12
orderLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
orderLabel.Font = Enum.Font.GothamBold
orderLabel.TextXAlignment = Enum.TextXAlignment.Left
orderLabel.TextWrapped = true
orderLabel.Parent = orderFrame

-- ── Initial data fetch ────────────────────────────────────────────────────────
task.spawn(function()
	task.wait(2)
	local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
	if ok and data then
		moneyLabel.Text = "💰 " .. tostring(data.money.currentBalance) .. " IGC"
		updateLevel(data.level or 1, data.dishesServed or 0)
		rebuildEmployeeList(data.employees)
		showToast("🍔 Welcome to your Brainrot Diner!", NEON_BLUE)
	else
		showToast("⚠ Couldn't load data — try rejoining", Color3.fromRGB(200, 150, 0))
	end
end)
