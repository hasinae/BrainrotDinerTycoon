-- ShopUI.client.lua  (LocalScript)
-- IGC cash shop — cosmetics and game passes overview.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GOLD      = Color3.fromRGB(255, 200, 0)
local HOT_PINK  = Color3.fromRGB(255, 20, 147)
local DARK_BG   = Color3.fromRGB(12, 8, 22)
local CARD_BG   = Color3.fromRGB(28, 16, 46)
local NEON_GREEN= Color3.fromRGB(0, 220, 100)

local function corner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = p
end
local function stroke(p, col, t)
	local s = Instance.new("UIStroke"); s.Color = col or GOLD; s.Thickness = t or 2; s.Parent = p
end

local screen = Instance.new("ScreenGui")
screen.Name           = "ShopUI"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Enabled        = false
screen.Parent         = playerGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.55
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screen
overlay.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		screen.Enabled = false
	end
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0,500,0,460)
panel.Position = UDim2.new(0.5,-250,0.5,-230)
panel.BackgroundColor3 = DARK_BG
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = screen
corner(panel, 16)
stroke(panel, GOLD, 2)

-- Header
local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1,0,0,52)
hdr.BackgroundColor3 = GOLD
hdr.BorderSizePixel = 0
hdr.ZIndex = 3
hdr.Parent = panel
corner(hdr, 14)
local hdrFix = Instance.new("Frame")
hdrFix.Size = UDim2.new(1,0,0.5,0)
hdrFix.Position = UDim2.new(0,0,0.5,0)
hdrFix.BackgroundColor3 = GOLD
hdrFix.BorderSizePixel = 0
hdrFix.ZIndex = 3
hdrFix.Parent = hdr

local hdrL = Instance.new("TextLabel")
hdrL.Size = UDim2.new(1,-60,1,0)
hdrL.Position = UDim2.new(0,16,0,0)
hdrL.BackgroundTransparency = 1
hdrL.Text = "🛍  SHOP"
hdrL.TextSize = 22
hdrL.TextColor3 = Color3.fromRGB(20,10,0)
hdrL.Font = Enum.Font.GothamBlack
hdrL.TextXAlignment = Enum.TextXAlignment.Left
hdrL.ZIndex = 4
hdrL.Parent = hdr

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-48,0,6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
closeBtn.BorderSizePixel = 0
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.Text = "✕"
closeBtn.ZIndex = 5
closeBtn.Parent = hdr
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

-- Info text
local infoL = Instance.new("TextLabel")
infoL.Size = UDim2.new(1,-24,0,44)
infoL.Position = UDim2.new(0,12,0,58)
infoL.BackgroundTransparency = 1
infoL.Text = "Premium content coming soon! Earn IGC by serving customers to upgrade your diner."
infoL.TextSize = 13
infoL.TextColor3 = Color3.fromRGB(160,140,190)
infoL.Font = Enum.Font.Gotham
infoL.TextWrapped = true
infoL.TextXAlignment = Enum.TextXAlignment.Left
infoL.ZIndex = 3
infoL.Parent = panel

-- Item cards
local ITEMS = {
	{ name="500 IGC",           desc="Quick cash boost",             icon="💰", tag="35 R$",   color=GOLD        },
	{ name="Premium Speedup",   desc="2× earnings for a week",       icon="⚡", tag="399 R$",  color=Color3.fromRGB(0,180,255)  },
	{ name="All Themes Pack",   desc="Unlock every restaurant theme",icon="🎨", tag="999 R$",  color=HOT_PINK    },
	{ name="VIP Membership",    desc="2× earnings forever",          icon="👑", tag="300 R$/mo",color=GOLD        },
	{ name="Premium Dish Pack", desc="Unlock 5 premium recipes",     icon="🍣", tag="150 R$",  color=NEON_GREEN  },
}

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-16,1,-110)
scroll.Position = UDim2.new(0,8,0,106)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = GOLD
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = panel

local listL = Instance.new("UIListLayout")
listL.Padding = UDim.new(0,8)
listL.Parent = scroll

local shopPad = Instance.new("UIPadding")
shopPad.PaddingTop    = UDim.new(0,4)
shopPad.PaddingLeft   = UDim.new(0,4)
shopPad.PaddingRight  = UDim.new(0,4)
shopPad.PaddingBottom = UDim.new(0,8)
shopPad.Parent = scroll

for _, item in ipairs(ITEMS) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1,0,0,68)
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
	bar.Parent = card; corner(bar, 3)

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
	nameL.Size = UDim2.new(0,240,0,24)
	nameL.Position = UDim2.new(0,62,0,8)
	nameL.BackgroundTransparency = 1
	nameL.Text = item.name
	nameL.TextSize = 15
	nameL.TextColor3 = Color3.new(1,1,1)
	nameL.Font = Enum.Font.GothamBold
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.ZIndex = 5
	nameL.Parent = card

	local descL = Instance.new("TextLabel")
	descL.Size = UDim2.new(0,240,0,18)
	descL.Position = UDim2.new(0,62,0,34)
	descL.BackgroundTransparency = 1
	descL.Text = item.desc
	descL.TextSize = 11
	descL.TextColor3 = Color3.fromRGB(160,140,185)
	descL.Font = Enum.Font.Gotham
	descL.TextXAlignment = Enum.TextXAlignment.Left
	descL.ZIndex = 5
	descL.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0,106,0,38)
	buyBtn.Position = UDim2.new(1,-114,0.5,-19)
	buyBtn.BackgroundColor3 = item.color
	buyBtn.BorderSizePixel = 0
	buyBtn.TextColor3 = Color3.fromRGB(10,5,20)
	buyBtn.TextSize = 14
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.Text = item.tag
	buyBtn.ZIndex = 6
	buyBtn.Parent = card
	corner(buyBtn, 8)
	-- Robux purchases handled by DevProducts in live game; show info toast for now
	buyBtn.MouseButton1Click:Connect(function()
		-- Would open Roblox purchase prompt in production
	end)
end
