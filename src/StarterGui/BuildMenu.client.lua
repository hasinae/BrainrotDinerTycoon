-- BuildMenu.client.lua  (LocalScript)
-- HIRE employees and PLACE furniture. Opened by the BUILD button in HUD.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local HireEmployee = Remotes:WaitForChild("HireEmployee")
local PlaceObject  = Remotes:WaitForChild("PlaceObject")
local Notification = Remotes:WaitForChild("Notification")

local Modules    = ReplicatedStorage:WaitForChild("Modules")
local Constants  = require(Modules.Constants)

-- ── Colors ────────────────────────────────────────────────────────────────────
local HOT_PINK  = Color3.fromRGB(255, 20, 147)
local NEON_BLUE = Color3.fromRGB(0, 180, 255)
local GOLD      = Color3.fromRGB(255, 200, 0)
local NEON_GREEN= Color3.fromRGB(0, 220, 100)
local DARK_BG   = Color3.fromRGB(12, 8, 22)
local CARD_BG   = Color3.fromRGB(28, 16, 46)
local MID_BG    = Color3.fromRGB(20, 12, 35)

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p
end
local function stroke(p, col, t)
	local s = Instance.new("UIStroke"); s.Color = col or HOT_PINK; s.Thickness = t or 2; s.Parent = p
end

-- ── ScreenGui ────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name            = "BuildMenu"
screen.ResetOnSpawn    = false
screen.IgnoreGuiInset  = true
screen.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screen.Enabled         = false
screen.Parent          = playerGui

-- Dim overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screen

-- Close when clicking overlay
overlay.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		screen.Enabled = false
	end
end)

-- Main panel
local panel = Instance.new("Frame")
panel.Size            = UDim2.new(0, 580, 0, 520)
panel.Position        = UDim2.new(0.5,-290, 0.5,-260)
panel.BackgroundColor3= DARK_BG
panel.BorderSizePixel = 0
panel.ZIndex          = 2
panel.Parent          = screen
corner(panel, 18)
stroke(panel, HOT_PINK, 2)

-- Header bar
local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1,0, 0,56)
hdr.BackgroundColor3 = HOT_PINK
hdr.BorderSizePixel  = 0
hdr.ZIndex = 3
hdr.Parent = panel
corner(hdr, 16)
-- bottom corners squared
local hdrFix = Instance.new("Frame")
hdrFix.Size = UDim2.new(1,0,0.5,0)
hdrFix.Position = UDim2.new(0,0,0.5,0)
hdrFix.BackgroundColor3 = HOT_PINK
hdrFix.BorderSizePixel = 0
hdrFix.ZIndex = 3
hdrFix.Parent = hdr

local hdrLabel = Instance.new("TextLabel")
hdrLabel.Size = UDim2.new(1,-70,1,0)
hdrLabel.Position = UDim2.new(0,18,0,0)
hdrLabel.BackgroundTransparency = 1
hdrLabel.Text = "🔨  BUILD & HIRE"
hdrLabel.TextSize = 22
hdrLabel.TextColor3 = Color3.new(1,1,1)
hdrLabel.Font = Enum.Font.GothamBlack
hdrLabel.TextXAlignment = Enum.TextXAlignment.Left
hdrLabel.ZIndex = 4
hdrLabel.Parent = hdr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-48,0,8)
closeBtn.BackgroundColor3 = Color3.fromRGB(220,40,40)
closeBtn.BorderSizePixel = 0
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Text = "✕"
closeBtn.ZIndex = 5
closeBtn.Parent = hdr
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- ── Tab bar ───────────────────────────────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1,-20,0,42)
tabBar.Position = UDim2.new(0,10,0,64)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 3
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,8)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Parent = tabBar

-- ── Scroll area ───────────────────────────────────────────────────────────────
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-16,1,-116)
scroll.Position = UDim2.new(0,8,0,112)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = HOT_PINK
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = panel

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0,8)
scrollLayout.Parent = scroll

local scrollPad = Instance.new("UIPadding")
scrollPad.PaddingTop    = UDim.new(0,4)
scrollPad.PaddingLeft   = UDim.new(0,4)
scrollPad.PaddingRight  = UDim.new(0,4)
scrollPad.PaddingBottom = UDim.new(0,8)
scrollPad.Parent = scroll

-- ── Tab helpers ───────────────────────────────────────────────────────────────
local tabBtns = {}

local function clearScroll()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end
end

local function makeTabBtn(label, icon)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,172,0,38)
	btn.BackgroundColor3 = CARD_BG
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.fromRGB(150,130,170)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.Text = icon.." "..label
	btn.ZIndex = 4
	btn.Parent = tabBar
	corner(btn, 8)
	tabBtns[label] = btn
	return btn
end

local function activateTab(name)
	for n, b in pairs(tabBtns) do
		b.BackgroundColor3 = (n==name) and HOT_PINK or CARD_BG
		b.TextColor3 = (n==name) and Color3.new(1,1,1) or Color3.fromRGB(150,130,170)
	end
end

-- ── Employee data ─────────────────────────────────────────────────────────────
local EMP_INFO = {
	{ key="tung_tung_sahur",      icon="💪", color=Color3.fromRGB(255,130,0),
	  trait="Fast worker • 20% error chance • Alpha mindset" },
	{ key="tralalero_tralala",    icon="🤖", color=Color3.fromRGB(80,160,255),
	  trait="Slow but steady • Freezes randomly • Huh?" },
	{ key="ballerina_cappuccina", icon="🩰", color=Color3.fromRGB(255,80,200),
	  trait="Unpredictable speed • 0.5–2× variance" },
}

local function addSectionLabel(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,0,28)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(160,140,190)
	l.Font = Enum.Font.Gotham
	l.ZIndex = 4
	l.Parent = scroll
end

local function buildStaffTab()
	clearScroll()
	addSectionLabel("Hire a worker — they'll cook orders and earn you IGC!")

	for _, emp in ipairs(EMP_INFO) do
		local cfg = Constants.EMPLOYEES[emp.key]
		if not cfg then continue end

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1,0,0,96)
		card.BackgroundColor3 = CARD_BG
		card.BorderSizePixel = 0
		card.ZIndex = 4
		card.Parent = scroll
		corner(card, 12)
		stroke(card, emp.color, 1)

		-- Left color bar
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0,5,1,-12)
		bar.Position = UDim2.new(0,0,0,6)
		bar.BackgroundColor3 = emp.color
		bar.BorderSizePixel = 0
		bar.ZIndex = 5
		bar.Parent = card
		corner(bar, 3)

		-- Icon
		local ico = Instance.new("TextLabel")
		ico.Size = UDim2.new(0,54,0,54)
		ico.Position = UDim2.new(0,10,0.5,-27)
		ico.BackgroundTransparency = 1
		ico.Text = emp.icon
		ico.TextSize = 34
		ico.ZIndex = 5
		ico.Font = Enum.Font.GothamBold
		ico.Parent = card

		-- Name
		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0,280,0,26)
		nameL.Position = UDim2.new(0,72,0,10)
		nameL.BackgroundTransparency = 1
		nameL.Text = cfg.displayName
		nameL.TextSize = 17
		nameL.TextColor3 = Color3.new(1,1,1)
		nameL.Font = Enum.Font.GothamBlack
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.ZIndex = 5
		nameL.Parent = card

		-- Trait
		local traitL = Instance.new("TextLabel")
		traitL.Size = UDim2.new(0,280,0,20)
		traitL.Position = UDim2.new(0,72,0,36)
		traitL.BackgroundTransparency = 1
		traitL.Text = emp.trait
		traitL.TextSize = 11
		traitL.TextColor3 = Color3.fromRGB(160,140,185)
		traitL.Font = Enum.Font.Gotham
		traitL.TextXAlignment = Enum.TextXAlignment.Left
		traitL.ZIndex = 5
		traitL.Parent = card

		-- Stats row
		local statsL = Instance.new("TextLabel")
		statsL.Size = UDim2.new(0,280,0,20)
		statsL.Position = UDim2.new(0,72,0,58)
		statsL.BackgroundTransparency = 1
		statsL.Text = "💸 "..cfg.salary.." IGC/min salary   Max: "..cfg.maxPerRestaurant.." hired"
		statsL.TextSize = 11
		statsL.TextColor3 = Color3.fromRGB(100,220,140)
		statsL.Font = Enum.Font.Gotham
		statsL.TextXAlignment = Enum.TextXAlignment.Left
		statsL.ZIndex = 5
		statsL.Parent = card

		-- Hire button
		local hireBtn = Instance.new("TextButton")
		hireBtn.Size = UDim2.new(0,120,0,42)
		hireBtn.Position = UDim2.new(1,-128,0.5,-21)
		hireBtn.BackgroundColor3 = NEON_GREEN
		hireBtn.BorderSizePixel = 0
		hireBtn.TextColor3 = Color3.fromRGB(5,30,12)
		hireBtn.TextSize = 15
		hireBtn.Font = Enum.Font.GothamBlack
		hireBtn.Text = "HIRE\n"..cfg.hireCost.." 💰"
		hireBtn.ZIndex = 6
		hireBtn.Parent = card
		corner(hireBtn, 10)

		hireBtn.MouseButton1Click:Connect(function()
			HireEmployee:FireServer(emp.key)
			-- Brief flash feedback
			hireBtn.BackgroundColor3 = GOLD
			task.delay(0.3, function() hireBtn.BackgroundColor3 = NEON_GREEN end)
		end)
		hireBtn.MouseEnter:Connect(function()
			TweenService:Create(hireBtn, TweenInfo.new(0.1), {Size=UDim2.new(0,128,0,46)}):Play()
		end)
		hireBtn.MouseLeave:Connect(function()
			TweenService:Create(hireBtn, TweenInfo.new(0.1), {Size=UDim2.new(0,120,0,42)}):Play()
		end)
	end
end

-- ── Furniture tab ─────────────────────────────────────────────────────────────
local FURN_INFO = {
	{ key="KitchenCounter", icon="🍳", color=Color3.fromRGB(220,100,0),  desc="Employees cook orders here" },
	{ key="DiningTable",    icon="🪑", color=Color3.fromRGB(140,90,50),  desc="Customers sit and wait for food" },
	{ key="CashierStation", icon="💳", color=Color3.fromRGB(220,180,0),  desc="Orders delivered and paid here" },
	{ key="TrashBin",       icon="🗑️", color=Color3.fromRGB(60,160,80),  desc="Keep the diner tidy" },
	{ key="Wall",           icon="🧱", color=Color3.fromRGB(180,180,180),desc="Build your restaurant layout" },
	{ key="FloorTile",      icon="⬛", color=Color3.fromRGB(200,200,200),desc="Custom flooring" },
}

local function buildFurnitureTab()
	clearScroll()
	addSectionLabel("Place furniture on your restaurant plot!")

	-- Compute plot origin client-side (matches server formula)
	local slot       = (player.UserId % 20) * 40
	local plotOrigin = Vector3.new(slot, 0.2, 0)

	for _, item in ipairs(FURN_INFO) do
		local cfg = Constants.FURNITURE[item.key]
		if not cfg then continue end

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1,0,0,72)
		card.BackgroundColor3 = CARD_BG
		card.BorderSizePixel = 0
		card.ZIndex = 4
		card.Parent = scroll
		corner(card, 10)
		stroke(card, item.color, 1)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0,5,1,-10)
		bar.Position = UDim2.new(0,0,0,5)
		bar.BackgroundColor3 = item.color
		bar.BorderSizePixel = 0
		bar.ZIndex = 5
		bar.Parent = card
		corner(bar, 3)

		local ico = Instance.new("TextLabel")
		ico.Size = UDim2.new(0,44,0,44)
		ico.Position = UDim2.new(0,10,0.5,-22)
		ico.BackgroundTransparency = 1
		ico.Text = item.icon
		ico.TextSize = 28
		ico.ZIndex = 5
		ico.Font = Enum.Font.GothamBold
		ico.Parent = card

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0,280,0,24)
		nameL.Position = UDim2.new(0,62,0,10)
		nameL.BackgroundTransparency = 1
		nameL.Text = item.key
		nameL.TextSize = 15
		nameL.TextColor3 = Color3.new(1,1,1)
		nameL.Font = Enum.Font.GothamBold
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.ZIndex = 5
		nameL.Parent = card

		local descL = Instance.new("TextLabel")
		descL.Size = UDim2.new(0,280,0,18)
		descL.Position = UDim2.new(0,62,0,36)
		descL.BackgroundTransparency = 1
		descL.Text = item.desc
		descL.TextSize = 11
		descL.TextColor3 = Color3.fromRGB(160,140,185)
		descL.Font = Enum.Font.Gotham
		descL.TextXAlignment = Enum.TextXAlignment.Left
		descL.ZIndex = 5
		descL.Parent = card

		local placeBtn = Instance.new("TextButton")
		placeBtn.Size = UDim2.new(0,120,0,40)
		placeBtn.Position = UDim2.new(1,-128,0.5,-20)
		placeBtn.BackgroundColor3 = NEON_BLUE
		placeBtn.BorderSizePixel = 0
		placeBtn.TextColor3 = Color3.fromRGB(5,20,40)
		placeBtn.TextSize = 15
		placeBtn.Font = Enum.Font.GothamBlack
		placeBtn.Text = "PLACE\n"..cfg.cost.." 💰"
		placeBtn.ZIndex = 6
		placeBtn.Parent = card
		corner(placeBtn, 10)

		placeBtn.MouseButton1Click:Connect(function()
			-- Pick an open grid slot in the plot
			local dx = math.random(-3, 3) * 2
			local dz = math.random(-3, 2) * 2
			local worldPos = Vector3.new(plotOrigin.X + dx, plotOrigin.Y + 1, plotOrigin.Z + dz)
			local ok, result = pcall(function()
				return PlaceObject:InvokeServer(item.key, worldPos, 0)
			end)
			if ok and result then
				placeBtn.BackgroundColor3 = NEON_GREEN
				task.delay(0.4, function() placeBtn.BackgroundColor3 = NEON_BLUE end)
			end
		end)
	end
end

-- ── Wire tabs ─────────────────────────────────────────────────────────────────
local staffTabBtn = makeTabBtn("STAFF",     "👥")
local furnTabBtn  = makeTabBtn("FURNITURE", "🏗️")

staffTabBtn.MouseButton1Click:Connect(function()
	activateTab("STAFF"); buildStaffTab()
end)
furnTabBtn.MouseButton1Click:Connect(function()
	activateTab("FURNITURE"); buildFurnitureTab()
end)

-- Show staff tab when menu opens
screen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screen.Enabled then
		activateTab("STAFF")
		buildStaffTab()
	end
end)
