-- SettingsUI.client.lua
-- Music, SFX, graphics, volume settings.

local Players           = game:GetService("Players")
local SoundService      = game:GetService("SoundService")
local UserGameSettings  = UserSettings():GetService("UserGameSettings")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name  = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent  = playerGui

local panel = Instance.new("Frame")
panel.Size  = UDim2.new(0, 360, 0, 340)
panel.Position = UDim2.new(0.5, -180, 0.5, -170)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
panel.BorderSizePixel  = 0
panel.Parent = screenGui
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = panel end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, 0, 0, 44)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
titleLabel.BorderSizePixel  = 0
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.TextSize   = 20
titleLabel.Font       = Enum.Font.GothamBold
titleLabel.Text       = "Settings"
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

-- ── Helper: toggle row ────────────────────────────────────────────────────────

local yOffset = 54

local function addToggle(labelText, state, onChange)
	local row = Instance.new("Frame")
	row.Size  = UDim2.new(1, -20, 0, 44)
	row.Position = UDim2.new(0, 10, 0, yOffset)
	row.BackgroundTransparency = 1
	row.Parent = panel
	yOffset = yOffset + 50

	local lbl = Instance.new("TextLabel")
	lbl.Size  = UDim2.new(0.7, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextSize   = 15
	lbl.Font       = Enum.Font.Gotham
	lbl.Text       = labelText
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(0, 70, 0, 30)
	btn.Position = UDim2.new(1, -74, 0.5, -15)
	btn.BackgroundColor3 = state and Color3.fromRGB(60,200,60) or Color3.fromRGB(180,50,50)
	btn.BorderSizePixel  = 0
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize   = 14
	btn.Font       = Enum.Font.GothamBold
	btn.Text       = state and "ON" or "OFF"
	btn.Parent = row
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn end

	local current = state
	btn.MouseButton1Click:Connect(function()
		current = not current
		btn.Text = current and "ON" or "OFF"
		btn.BackgroundColor3 = current
			and Color3.fromRGB(60,200,60) or Color3.fromRGB(180,50,50)
		onChange(current)
	end)
end

local function addSlider(labelText, initialVal, onChange)
	local row = Instance.new("Frame")
	row.Size  = UDim2.new(1, -20, 0, 54)
	row.Position = UDim2.new(0, 10, 0, yOffset)
	row.BackgroundTransparency = 1
	row.Parent = panel
	yOffset = yOffset + 60

	local lbl = Instance.new("TextLabel")
	lbl.Size  = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextSize   = 14
	lbl.Font       = Enum.Font.Gotham
	lbl.Text       = labelText .. ": " .. math.floor(initialVal * 100)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local track = Instance.new("Frame")
	track.Size  = UDim2.new(1, 0, 0, 10)
	track.Position = UDim2.new(0, 0, 0, 28)
	track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	track.BorderSizePixel  = 0
	track.Parent = row
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = track end

	local fill = Instance.new("Frame")
	fill.Size  = UDim2.new(initialVal, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
	fill.BorderSizePixel  = 0
	fill.Parent = track
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = fill end

	-- Drag to change
	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local trackPos  = track.AbsolutePosition
			local trackSize = track.AbsoluteSize
			local relX = math.clamp((input.Position.X - trackPos.X) / trackSize.X, 0, 1)
			fill.Size = UDim2.new(relX, 0, 1, 0)
			lbl.Text  = labelText .. ": " .. math.floor(relX * 100)
			onChange(relX)
		end
	end)
end

addToggle("Music", true, function(on)
	local music = workspace:FindFirstChild("BGM")
	if music then music.Volume = on and 0.5 or 0 end
end)

addToggle("Sound Effects", true, function(on)
	SoundService.RespectFilteringEnabled = true
end)

addSlider("Volume", 0.5, function(val)
	SoundService.AmbientReverb = Enum.ReverbType.NoReverb
	-- In production: adjust master volume or SoundGroup
end)

-- Credits button
local creditBtn = Instance.new("TextButton")
creditBtn.Size  = UDim2.new(1, -20, 0, 34)
creditBtn.Position = UDim2.new(0, 10, 1, -44)
creditBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
creditBtn.BorderSizePixel  = 0
creditBtn.TextColor3 = Color3.fromRGB(160, 160, 200)
creditBtn.TextSize   = 13
creditBtn.Font       = Enum.Font.Gotham
creditBtn.Text       = "Credits — Brainrot Diner Tycoon"
creditBtn.Parent     = panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = creditBtn end
