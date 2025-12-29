local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Wait for RemoteEvents to be available
local RemoteEvents
local success, err = pcall(function()
	RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
end)

if not success then
	warn("[Gameboy Client] Failed to load RemoteEvents:", err)
	return
end

-- Verify RemoteEvents are accessible
print("[Gameboy Client] RemoteEvents loaded:")
print("  - LoadROM:", RemoteEvents.LoadROM and "OK" or "MISSING")
print("  - PlayerInput:", RemoteEvents.PlayerInput and "OK" or "MISSING")
print("  - GetEditableImage:", RemoteEvents.GetEditableImage and "OK" or "MISSING")
print("  - StatusMessage:", RemoteEvents.StatusMessage and "OK" or "MISSING")

-- Double-check by getting from ReplicatedStorage directly
local loadROMCheck = ReplicatedStorage:FindFirstChild("LoadROM")
print("[Gameboy Client] LoadROM in ReplicatedStorage:", loadROMCheck and "Found" or "NOT FOUND")
if loadROMCheck then
	print("[Gameboy Client] LoadROM type:", loadROMCheck.ClassName)
end

local WIDTH = 160
local HEIGHT = 144

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameboyEmulator"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Main container frame (full screen with padding)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, -40, 1, -40)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Left panel - Emulator Display
local displayPanel = Instance.new("Frame")
displayPanel.Name = "DisplayPanel"
displayPanel.Size = UDim2.new(0, 520, 1, 0)
displayPanel.Position = UDim2.new(0, 0, 0, 0)
displayPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
displayPanel.BorderSizePixel = 0
displayPanel.Parent = mainFrame

local displayCorner = Instance.new("UICorner")
displayCorner.CornerRadius = UDim.new(0, 12)
displayCorner.Parent = displayPanel

-- Title bar for display panel
local displayTitle = Instance.new("Frame")
displayTitle.Name = "TitleBar"
displayTitle.Size = UDim2.new(1, 0, 0, 50)
displayTitle.Position = UDim2.new(0, 0, 0, 0)
displayTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
displayTitle.BorderSizePixel = 0
displayTitle.Parent = displayPanel

local displayTitleCorner = Instance.new("UICorner")
displayTitleCorner.CornerRadius = UDim.new(0, 12)
displayTitleCorner.Parent = displayTitle

-- Fix bottom corners
local displayTitleBottom = Instance.new("Frame")
displayTitleBottom.Size = UDim2.new(1, 0, 0, 12)
displayTitleBottom.Position = UDim2.new(0, 0, 1, -12)
displayTitleBottom.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
displayTitleBottom.BorderSizePixel = 0
displayTitleBottom.Parent = displayTitle

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Game Boy Emulator"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = displayTitle

-- Minimize button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 50, 0, 40)
minimizeButton.Position = UDim2.new(1, -60, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
minimizeButton.BorderSizePixel = 0
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 24
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.AutoButtonColor = false
minimizeButton.Parent = displayTitle

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

-- Minimized button (shown when UI is minimized)
local minimizedButton = Instance.new("TextButton")
minimizedButton.Name = "MinimizedButton"
minimizedButton.Size = UDim2.new(0, 60, 0, 60)
minimizedButton.Position = UDim2.new(1, -80, 0, 20)
minimizedButton.AnchorPoint = Vector2.new(1, 0)
minimizedButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
minimizedButton.BorderSizePixel = 0
minimizedButton.Text = "📱"
minimizedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedButton.TextSize = 24
minimizedButton.Font = Enum.Font.Gotham
minimizedButton.AutoButtonColor = false
minimizedButton.Visible = false
minimizedButton.ZIndex = 100
minimizedButton.Parent = screenGui

local minimizedCorner = Instance.new("UICorner")
minimizedCorner.CornerRadius = UDim.new(0, 12)
minimizedCorner.Parent = minimizedButton

-- Tooltip for minimized button
local tooltip = Instance.new("TextLabel")
tooltip.Name = "Tooltip"
tooltip.Size = UDim2.new(0, 150, 0, 30)
tooltip.Position = UDim2.new(1, 10, 0, 0)
tooltip.AnchorPoint = Vector2.new(0, 0.5)
tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tooltip.BorderSizePixel = 0
tooltip.Text = "Click to open emulator"
tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltip.TextSize = 12
tooltip.Font = Enum.Font.Gotham
tooltip.Visible = false
tooltip.ZIndex = 101
tooltip.Parent = minimizedButton

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 6)
tooltipCorner.Parent = tooltip

local tooltipPadding = Instance.new("UIPadding")
tooltipPadding.PaddingLeft = UDim.new(0, 8)
tooltipPadding.PaddingRight = UDim.new(0, 8)
tooltipPadding.Parent = tooltip

-- Show tooltip on hover
minimizedButton.MouseEnter:Connect(function()
	tooltip.Visible = true
end)

minimizedButton.MouseLeave:Connect(function()
	tooltip.Visible = false
end)

-- Track minimized state
local isMinimized = false

-- Minimize/maximize functionality
local function toggleMinimize()
	isMinimized = not isMinimized
	mainFrame.Visible = not isMinimized
	minimizedButton.Visible = isMinimized
	
	if isMinimized then
		minimizeButton.Text = "+"
	else
		minimizeButton.Text = "−"
	end
end

minimizeButton.MouseButton1Click:Connect(toggleMinimize)
minimizedButton.MouseButton1Click:Connect(toggleMinimize)

-- Emulator screen container
local screenContainer = Instance.new("Frame")
screenContainer.Name = "ScreenContainer"
screenContainer.Size = UDim2.new(1, -40, 1, -90)
screenContainer.Position = UDim2.new(0, 20, 0, 70)
screenContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
screenContainer.BorderSizePixel = 0
screenContainer.Parent = displayPanel

local screenCorner = Instance.new("UICorner")
screenCorner.CornerRadius = UDim.new(0, 8)
screenCorner.Parent = screenContainer

-- Emulator display (scaled to fit nicely)
local displayFrame = Instance.new("Frame")
displayFrame.Name = "DisplayFrame"
displayFrame.Size = UDim2.new(0, WIDTH * 2.8, 0, HEIGHT * 2.8)
displayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
displayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
displayFrame.BackgroundColor3 = Color3.new(0, 0, 0)
displayFrame.BorderSizePixel = 0
displayFrame.Parent = screenContainer

local displayCorner2 = Instance.new("UICorner")
displayCorner2.CornerRadius = UDim.new(0, 4)
displayCorner2.Parent = displayFrame

local screenImage = Instance.new("ImageLabel")
screenImage.Name = "Screen"
screenImage.Size = UDim2.new(1, 0, 1, 0)
screenImage.Position = UDim2.new(0, 0, 0, 0)
screenImage.BackgroundTransparency = 1
screenImage.ResampleMode = Enum.ResamplerMode.Pixelated
screenImage.Parent = displayFrame

local aspectRatio = Instance.new("UIAspectRatioConstraint")
aspectRatio.AspectRatio = WIDTH / HEIGHT
aspectRatio.Parent = screenImage

-- Right panel - Controls and Info
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(1, -540, 1, 0)
controlPanel.Position = UDim2.new(0, 540, 0, 0)
controlPanel.BackgroundTransparency = 1
controlPanel.Parent = mainFrame

-- ROM Loading section
local romSection = Instance.new("Frame")
romSection.Name = "ROMSection"
romSection.Size = UDim2.new(1, 0, 0, 140)
romSection.Position = UDim2.new(0, 0, 0, 0)
romSection.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
romSection.BorderSizePixel = 0
romSection.Parent = controlPanel

local romCorner = Instance.new("UICorner")
romCorner.CornerRadius = UDim.new(0, 12)
romCorner.Parent = romSection

local romPadding = Instance.new("UIPadding")
romPadding.PaddingTop = UDim.new(0, 20)
romPadding.PaddingBottom = UDim.new(0, 20)
romPadding.PaddingLeft = UDim.new(0, 20)
romPadding.PaddingRight = UDim.new(0, 20)
romPadding.Parent = romSection

local romTitle = Instance.new("TextLabel")
romTitle.Name = "Title"
romTitle.Size = UDim2.new(1, 0, 0, 20)
romTitle.Position = UDim2.new(0, 0, 0, 0)
romTitle.BackgroundTransparency = 1
romTitle.Text = "Load ROM"
romTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
romTitle.TextSize = 14
romTitle.Font = Enum.Font.GothamBold
romTitle.TextXAlignment = Enum.TextXAlignment.Left
romTitle.Parent = romSection

local urlTextBox = Instance.new("TextBox")
urlTextBox.Name = "URLTextBox"
urlTextBox.Size = UDim2.new(1, 0, 0, 40)
urlTextBox.Position = UDim2.new(0, 0, 0, 30)
urlTextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
urlTextBox.BorderSizePixel = 0
urlTextBox.Text = ""
urlTextBox.PlaceholderText = "Enter ROM URL..."
urlTextBox.TextColor3 = Color3.new(1, 1, 1)
urlTextBox.TextSize = 13
urlTextBox.Font = Enum.Font.Gotham
urlTextBox.TextXAlignment = Enum.TextXAlignment.Left
urlTextBox.ClearTextOnFocus = false
urlTextBox.Parent = romSection

local urlCorner = Instance.new("UICorner")
urlCorner.CornerRadius = UDim.new(0, 6)
urlCorner.Parent = urlTextBox

local urlPadding = Instance.new("UIPadding")
urlPadding.PaddingLeft = UDim.new(0, 12)
urlPadding.PaddingRight = UDim.new(0, 12)
urlPadding.Parent = urlTextBox

local loadButton = Instance.new("TextButton")
loadButton.Name = "LoadButton"
loadButton.Size = UDim2.new(1, 0, 0, 40)
loadButton.Position = UDim2.new(0, 0, 0, 80)
loadButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
loadButton.BorderSizePixel = 0
loadButton.Text = "Load ROM"
loadButton.TextColor3 = Color3.new(1, 1, 1)
loadButton.TextSize = 14
loadButton.Font = Enum.Font.GothamBold
loadButton.AutoButtonColor = false
loadButton.Parent = romSection

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 6)
loadCorner.Parent = loadButton

-- Actions section
local actionsSection = Instance.new("Frame")
actionsSection.Name = "ActionsSection"
actionsSection.Size = UDim2.new(1, 0, 0, 190)
actionsSection.Position = UDim2.new(0, 0, 0, 160)
actionsSection.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
actionsSection.BorderSizePixel = 0
actionsSection.Parent = controlPanel

local actionsCorner = Instance.new("UICorner")
actionsCorner.CornerRadius = UDim.new(0, 12)
actionsCorner.Parent = actionsSection

local actionsPadding = Instance.new("UIPadding")
actionsPadding.PaddingTop = UDim.new(0, 20)
actionsPadding.PaddingBottom = UDim.new(0, 20)
actionsPadding.PaddingLeft = UDim.new(0, 20)
actionsPadding.PaddingRight = UDim.new(0, 20)
actionsPadding.Parent = actionsSection

local actionsTitle = Instance.new("TextLabel")
actionsTitle.Name = "Title"
actionsTitle.Size = UDim2.new(1, 0, 0, 20)
actionsTitle.Position = UDim2.new(0, 0, 0, 0)
actionsTitle.BackgroundTransparency = 1
actionsTitle.Text = "Actions"
actionsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
actionsTitle.TextSize = 14
actionsTitle.Font = Enum.Font.GothamBold
actionsTitle.TextXAlignment = Enum.TextXAlignment.Left
actionsTitle.Parent = actionsSection

local dashboardButton = Instance.new("TextButton")
dashboardButton.Name = "DashboardButton"
dashboardButton.Size = UDim2.new(1, 0, 0, 40)
dashboardButton.Position = UDim2.new(0, 0, 0, 30)
dashboardButton.BackgroundColor3 = Color3.fromRGB(87, 75, 144)
dashboardButton.BorderSizePixel = 0
dashboardButton.Text = "📚 Library"
dashboardButton.TextColor3 = Color3.new(1, 1, 1)
dashboardButton.TextSize = 14
dashboardButton.Font = Enum.Font.GothamBold
dashboardButton.AutoButtonColor = false
dashboardButton.Active = true
dashboardButton.ZIndex = 5
dashboardButton.Parent = actionsSection

local dashboardCorner = Instance.new("UICorner")
dashboardCorner.CornerRadius = UDim.new(0, 6)
dashboardCorner.Parent = dashboardButton

local saveButton = Instance.new("TextButton")
saveButton.Name = "SaveButton"
saveButton.Size = UDim2.new(1, 0, 0, 40)
saveButton.Position = UDim2.new(0, 0, 0, 80)
saveButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
saveButton.BorderSizePixel = 0
saveButton.Text = "💾 Save Game"
saveButton.TextColor3 = Color3.new(1, 1, 1)
saveButton.TextSize = 14
saveButton.Font = Enum.Font.GothamBold
saveButton.Visible = false
saveButton.AutoButtonColor = false
saveButton.Active = true
saveButton.ZIndex = 5
saveButton.Parent = actionsSection

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 6)
saveCorner.Parent = saveButton

local leaderboardButton = Instance.new("TextButton")
leaderboardButton.Name = "LeaderboardButton"
leaderboardButton.Size = UDim2.new(1, 0, 0, 40)
leaderboardButton.Position = UDim2.new(0, 0, 0, 130)
leaderboardButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
leaderboardButton.BorderSizePixel = 0
leaderboardButton.Text = "🏆 Leaderboard"
leaderboardButton.TextColor3 = Color3.new(1, 1, 1)
leaderboardButton.TextSize = 14
leaderboardButton.Font = Enum.Font.GothamBold
leaderboardButton.Visible = false
leaderboardButton.AutoButtonColor = false
leaderboardButton.Active = true
leaderboardButton.ZIndex = 5
leaderboardButton.Parent = actionsSection

local leaderboardCorner = Instance.new("UICorner")
leaderboardCorner.CornerRadius = UDim.new(0, 6)
leaderboardCorner.Parent = leaderboardButton

-- Controls info section
local controlsSection = Instance.new("Frame")
controlsSection.Name = "ControlsSection"
controlsSection.Size = UDim2.new(1, 0, 1, -320)
controlsSection.Position = UDim2.new(0, 0, 0, 320)
controlsSection.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
controlsSection.BorderSizePixel = 0
controlsSection.Parent = controlPanel

local controlsCorner = Instance.new("UICorner")
controlsCorner.CornerRadius = UDim.new(0, 12)
controlsCorner.Parent = controlsSection

local controlsPadding = Instance.new("UIPadding")
controlsPadding.PaddingTop = UDim.new(0, 20)
controlsPadding.PaddingBottom = UDim.new(0, 20)
controlsPadding.PaddingLeft = UDim.new(0, 20)
controlsPadding.PaddingRight = UDim.new(0, 20)
controlsPadding.Parent = controlsSection

local controlsTitle = Instance.new("TextLabel")
controlsTitle.Name = "Title"
controlsTitle.Size = UDim2.new(1, 0, 0, 20)
controlsTitle.Position = UDim2.new(0, 0, 0, 0)
controlsTitle.BackgroundTransparency = 1
controlsTitle.Text = "Controls"
controlsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsTitle.TextSize = 14
controlsTitle.Font = Enum.Font.GothamBold
controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
controlsTitle.Parent = controlsSection

local controlsInfo = Instance.new("TextLabel")
controlsInfo.Name = "Info"
controlsInfo.Size = UDim2.new(1, 0, 1, -30)
controlsInfo.Position = UDim2.new(0, 0, 0, 30)
controlsInfo.BackgroundTransparency = 1
controlsInfo.Text = "Arrow Keys / WASD - D-Pad\nX - A Button\nZ - B Button\nEnter - Start\nRight Shift - Select"
controlsInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
controlsInfo.TextSize = 12
controlsInfo.Font = Enum.Font.Gotham
controlsInfo.TextXAlignment = Enum.TextXAlignment.Left
controlsInfo.TextYAlignment = Enum.TextYAlignment.Top
controlsInfo.TextWrapped = true
controlsInfo.Parent = controlsSection

-- Status label (overlay on display)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -40, 0, 40)
statusLabel.Position = UDim2.new(0, 20, 1, -60)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
statusLabel.BackgroundTransparency = 0.1
statusLabel.BorderSizePixel = 0
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Visible = false
statusLabel.ZIndex = 10
statusLabel.Parent = displayPanel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 15)
statusPadding.PaddingRight = UDim.new(0, 15)
statusPadding.Parent = statusLabel

-- Button hover effects
local function addHoverEffect(button: TextButton, normalColor: Color3, hoverColor: Color3)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
	end)
end

addHoverEffect(loadButton, Color3.fromRGB(88, 101, 242), Color3.fromRGB(98, 111, 252))
addHoverEffect(dashboardButton, Color3.fromRGB(87, 75, 144), Color3.fromRGB(97, 85, 154))
addHoverEffect(saveButton, Color3.fromRGB(67, 181, 129), Color3.fromRGB(77, 191, 139))

local controlsTitle = Instance.new("TextLabel")
controlsTitle.Name = "ControlsTitle"
controlsTitle.Size = UDim2.new(1, 0, 0, 20)
controlsTitle.Position = UDim2.new(0, 0, 0, 0)
controlsTitle.BackgroundTransparency = 1
controlsTitle.Text = "Controls"
controlsTitle.TextColor3 = Color3.new(1, 1, 1)
controlsTitle.TextSize = 16
controlsTitle.Font = Enum.Font.GothamBold
controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
controlsTitle.Parent = controlsFrame

local controlsText = Instance.new("TextLabel")
controlsText.Name = "ControlsText"
controlsText.Size = UDim2.new(1, 0, 1, -25)
controlsText.Position = UDim2.new(0, 0, 0, 25)
controlsText.BackgroundTransparency = 1
controlsText.Text = "Arrow Keys/WASD: D-Pad\nX/Z: A/B Buttons\nEnter: Start\nRight Shift: Select"
controlsText.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsText.TextSize = 12
controlsText.Font = Enum.Font.Gotham
controlsText.TextXAlignment = Enum.TextXAlignment.Left
controlsText.TextYAlignment = Enum.TextYAlignment.Top
controlsText.Parent = controlsFrame

-- Status message label (positioned after URL frame)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 90)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.BorderSizePixel = 0
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Visible = false
statusLabel.ZIndex = 10
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 4)
statusCorner.Parent = statusLabel

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 10)
statusPadding.PaddingRight = UDim.new(0, 10)
statusPadding.Parent = statusLabel

-- Input map (same as server)
local inputMap = {
	[Enum.KeyCode.Up] = "Up",
	[Enum.KeyCode.Down] = "Down",
	[Enum.KeyCode.Left] = "Left",
	[Enum.KeyCode.Right] = "Right",
	[Enum.KeyCode.X] = "A",
	[Enum.KeyCode.Z] = "B",
	[Enum.KeyCode.W] = "Up",
	[Enum.KeyCode.S] = "Down",
	[Enum.KeyCode.A] = "Left",
	[Enum.KeyCode.D] = "Right",
	[Enum.KeyCode.Return] = "Start",
	[Enum.KeyCode.RightShift] = "Select",
	[Enum.KeyCode.DPadUp] = "Up",
	[Enum.KeyCode.DPadDown] = "Down",
	[Enum.KeyCode.DPadLeft] = "Left",
	[Enum.KeyCode.DPadRight] = "Right",
	[Enum.KeyCode.ButtonY] = "A",
	[Enum.KeyCode.ButtonX] = "B",
}

-- Handle input
local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	local key = inputMap[input.KeyCode]
	if key then
		RemoteEvents.PlayerInput:FireServer(key, true)
	end
end

local function onInputEnded(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	local key = inputMap[input.KeyCode]
	if key then
		RemoteEvents.PlayerInput:FireServer(key, false)
	end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- Handle ROM loading
local function onLoadRom()
	if not urlTextBox then
		warn("[Gameboy Client] urlTextBox is nil!")
		return
	end
	
	local url = urlTextBox.Text or ""
	print("[Gameboy Client] Load ROM clicked, URL:", url)
	
	if url == "" or url == "Enter ROM URL..." then
		if statusLabel then
			statusLabel.Text = "Please enter a ROM URL"
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			statusLabel.Visible = true
			task.spawn(function()
				task.wait(3)
				if statusLabel then
					statusLabel.Visible = false
				end
			end)
		end
		return
	end

	print("[Gameboy Client] Firing LoadROM RemoteEvent with URL:", url)
	
	loadButton.Text = "Loading..."
	loadButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	loadButton.Active = false

	local success = pcall(function()
		RemoteEvents.LoadROM:FireServer(url)
	end)
	
	if not success then
		warn("[Gameboy Client] Failed to fire LoadROM RemoteEvent")
		if statusLabel then
			statusLabel.Text = "Error: Failed to send request to server"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			statusLabel.Visible = true
		end
		loadButton.Text = "Load ROM"
		loadButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
		loadButton.Active = true
		return
	end

	-- Reset button after a delay (server will handle errors)
	task.spawn(function()
		task.wait(5)
		loadButton.Text = "Load ROM"
		loadButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
		loadButton.Active = true
	end)
end

loadButton.MouseButton1Click:Connect(onLoadRom)
urlTextBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		onLoadRom()
	end
end)

-- Handle status messages from server
RemoteEvents.StatusMessage.OnClientEvent:Connect(function(message: string, isInfo: boolean)
	if message and message ~= "" then
		statusLabel.Text = message
		statusLabel.Visible = true
		if isInfo then
			statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		else
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
		
		-- Show save button when game starts
		if message:find("Game starting") then
			currentGameLoaded = true
			saveButton.Visible = true
		end
		
		-- Hide status after delay
		task.spawn(function()
			task.wait(5)
			if statusLabel.Text == message then
				statusLabel.Visible = false
				statusLabel.Text = ""
			end
		end)
	end
end)

-- Create EditableImage on client
local AssetService = game:GetService("AssetService")
print("[Gameboy Client] Creating EditableImage...")
local clientScreen = AssetService:CreateEditableImage({ Size = Vector2.new(WIDTH, HEIGHT) })
screenImage.ImageContent = Content.fromObject(clientScreen)
print("[Gameboy Client] EditableImage created and set to screen")

-- Verify FrameData RemoteEvent exists
local frameDataCheck = ReplicatedStorage:FindFirstChild("FrameData")
print("[Gameboy Client] FrameData in ReplicatedStorage:", frameDataCheck and "Found" or "NOT FOUND")

-- Track if we're spectating
local isSpectating = false

-- Handle spectating updates
RemoteEvents.SpectatorUpdate.OnClientEvent:Connect(function(spectating: boolean, playerName: string?, gameTitle: string?)
	isSpectating = spectating
	-- Hide main UI when spectating, but keep minimized button visible if minimized
	if spectating then
		mainFrame.Visible = false
		minimizedButton.Visible = false
	else
		-- Restore previous minimized state
		mainFrame.Visible = not isMinimized
		minimizedButton.Visible = isMinimized
	end
end)

-- Handle frame data from server
local frameCount = 0
RemoteEvents.FrameData.OnClientEvent:Connect(function(frameDataString)
	-- Don't process frame data if we're spectating (spectator client handles it)
	if isSpectating then
		return
	end
	
	frameCount = frameCount + 1
	if frameCount == 1 then
		print("[Gameboy Client] Received first frame data, size:", #frameDataString, "bytes")
	end
	
	if frameDataString and #frameDataString > 0 then
		-- Convert string back to buffer
		local success, frameBuffer = pcall(function()
			local buf = buffer.create(WIDTH * HEIGHT * 4)
			local expectedSize = WIDTH * HEIGHT * 4
			
			if #frameDataString ~= expectedSize then
				warn("[Gameboy Client] Frame data size mismatch! Expected:", expectedSize, "Got:", #frameDataString)
			end
			
			-- Convert string bytes to buffer
			for i = 0, math.min(#frameDataString - 1, expectedSize - 1) do
				buffer.writeu8(buf, i, string.byte(frameDataString, i + 1))
			end
			
			return buf
		end)
		
		if success and frameBuffer then
			-- Update EditableImage with frame data
			clientScreen:WritePixelsBuffer(Vector2.zero, Vector2.new(WIDTH, HEIGHT), frameBuffer)
			if frameCount == 1 then
				print("[Gameboy Client] First frame written to EditableImage successfully")
			end
		else
			warn("[Gameboy Client] Failed to convert frame data:", frameBuffer)
		end
	else
		if frameCount <= 3 then
			warn("[Gameboy Client] Received empty frame data")
		end
	end
end)

print("[Gameboy Client] FrameData handler connected")

-- Get dashboard module from ReplicatedStorage
local dashboardModule
local success, err = pcall(function()
	dashboardModule = require(ReplicatedStorage:WaitForChild("GameboyDashboard"))
end)

if not success then
	warn("[Gameboy Client] Failed to load dashboard module:", err)
end

-- Dashboard button click
dashboardButton.MouseButton1Click:Connect(function()
	print("[Gameboy Client] Library button clicked")
	if dashboardModule then
		print("[Gameboy Client] Calling toggleDashboard")
		dashboardModule.toggleDashboard()
	else
		warn("[Gameboy Client] Dashboard module not available")
	end
end)

-- Save button click
saveButton.MouseButton1Click:Connect(function()
	print("[Gameboy Client] Save button clicked")
	if dashboardModule then
		print("[Gameboy Client] Calling showSaveUI")
		dashboardModule.showSaveUI()
	else
		warn("[Gameboy Client] Dashboard module not available")
	end
end)

-- Track current game (declare before handlers)
local currentGameId: string? = nil
local currentGameLoaded = false

-- Show save button when game loads
RemoteEvents.CurrentGameUpdate.OnClientEvent:Connect(function(gameId: string)
	print("[Gameboy Client] CurrentGameUpdate received, gameId:", gameId)
	currentGameLoaded = true
	currentGameId = gameId
	saveButton.Visible = true
	leaderboardButton.Visible = true
	
	-- Start audio when game loads
	if audioClient then
		audioClient.start()
	end
	
	print("[Gameboy Client] currentGameId set to:", currentGameId)
end)

-- Get leaderboard module
local leaderboardModule
local leaderboardSuccess, leaderboardErr = pcall(function()
	leaderboardModule = require(ReplicatedStorage:WaitForChild("GameboyLeaderboard"))
end)

if not leaderboardSuccess then
	warn("[Gameboy Client] Failed to load leaderboard module:", leaderboardErr)
end

-- Get audio client module
local audioClient
local audioSuccess, audioErr = pcall(function()
	audioClient = require(script:WaitForChild("AudioClient"))
end)

if not audioSuccess then
	warn("[Gameboy Client] Failed to load audio client:", audioErr)
end

-- Leaderboard button click
leaderboardButton.MouseButton1Click:Connect(function()
	print("[Gameboy Client] Leaderboard button clicked, currentGameId:", currentGameId)
	if leaderboardModule and currentGameId then
		leaderboardModule.show(currentGameId)
	else
		if not currentGameId then
			warn("[Gameboy Client] No game loaded - currentGameId is nil")
		else
			warn("[Gameboy Client] Leaderboard module not available")
		end
	end
end)

-- Handle score submission notification
RemoteEvents.ScoreSubmitted.OnClientEvent:Connect(function(gameId: string, score: number, rank: number?)
	if statusLabel then
		local message = "Score saved: " .. tostring(score)
		if rank then
			message = message .. " (Rank #" .. tostring(rank) .. ")"
		end
		statusLabel.Text = message
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		statusLabel.Visible = true
		
		-- Hide after delay
		task.spawn(function()
			task.wait(5)
			if statusLabel.Text == message then
				statusLabel.Visible = false
			end
		end)
	end
end)

-- Update existing StatusMessage handler to also show save button
-- (The handler is already defined above, so we'll modify it)

