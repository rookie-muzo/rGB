local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Wait for RemoteEvents
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Module table
local GameboyDashboard = {}

-- Constants
local MAX_SAVE_SLOTS = 5

-- Create ScreenGui for dashboard (ensures proper layering)
local dashboardScreenGui = Instance.new("ScreenGui")
dashboardScreenGui.Name = "GameboyDashboardGui"
dashboardScreenGui.ResetOnSpawn = false
dashboardScreenGui.DisplayOrder = 100
dashboardScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
dashboardScreenGui.Parent = playerGui

-- Create main dashboard frame
local dashboardFrame = Instance.new("Frame")
dashboardFrame.Name = "GameboyDashboard"
dashboardFrame.Size = UDim2.new(1, 0, 1, 0)
dashboardFrame.Position = UDim2.new(0, 0, 0, 0)
dashboardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dashboardFrame.BackgroundTransparency = 0.3
dashboardFrame.Visible = false
dashboardFrame.ZIndex = 1
dashboardFrame.Parent = dashboardScreenGui

-- Background blur (must be in Lighting)
local Lighting = game:GetService("Lighting")
local blur = Lighting:FindFirstChild("GameboyDashboardBlur")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Name = "GameboyDashboardBlur"
	blur.Size = 0
	blur.Parent = Lighting
end

-- Main container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0.9, 0, 0.9, 0)
mainContainer.Position = UDim2.new(0.05, 0, 0.05, 0)
mainContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainContainer.BorderSizePixel = 0
mainContainer.ZIndex = 2
mainContainer.Parent = dashboardFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.BorderSizePixel = 0
title.Text = "My Game Library"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.ZIndex = 3
title.Parent = mainContainer

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -40, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 4
closeButton.Parent = mainContainer

-- Scrolling frame for games list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "GamesList"
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ZIndex = 3
scrollFrame.Parent = mainContainer

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Store games data
local gamesData = {}

-- Format timestamp
local function formatTime(timestamp: number): string
	local date = os.date("*t", timestamp)
	return string.format("%02d/%02d/%04d %02d:%02d", date.month, date.day, date.year, date.hour, date.min)
end

-- Create game card
local function createGameCard(gameId: string, gameData: any)
	local card = Instance.new("Frame")
	card.Name = gameId
	card.Size = UDim2.new(1, -20, 0, 200)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 0
	card.Parent = scrollFrame
	
	-- Game title
	local gameTitle = Instance.new("TextLabel")
	gameTitle.Name = "Title"
	gameTitle.Size = UDim2.new(1, -10, 0, 30)
	gameTitle.Position = UDim2.new(0, 10, 0, 5)
	gameTitle.BackgroundTransparency = 1
	gameTitle.Text = gameData.title .. " (" .. gameData.type .. ")"
	gameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	gameTitle.TextSize = 18
	gameTitle.Font = Enum.Font.GothamBold
	gameTitle.TextXAlignment = Enum.TextXAlignment.Left
	gameTitle.Parent = card
	
	-- Last played
	local lastPlayed = Instance.new("TextLabel")
	lastPlayed.Name = "LastPlayed"
	lastPlayed.Size = UDim2.new(1, -10, 0, 20)
	lastPlayed.Position = UDim2.new(0, 10, 0, 35)
	lastPlayed.BackgroundTransparency = 1
	lastPlayed.Text = "Last played: " .. formatTime(gameData.lastPlayed)
	lastPlayed.TextColor3 = Color3.fromRGB(200, 200, 200)
	lastPlayed.TextSize = 14
	lastPlayed.Font = Enum.Font.Gotham
	lastPlayed.TextXAlignment = Enum.TextXAlignment.Left
	lastPlayed.Parent = card
	
	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(0, 220, 0, 30)
	buttonContainer.Position = UDim2.new(1, -230, 0, 5)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = card
	
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 5)
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonContainer
	
	-- Reload button
	local reloadButton = Instance.new("TextButton")
	reloadButton.Name = "ReloadButton"
	reloadButton.Size = UDim2.new(0, 100, 1, 0)
	reloadButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	reloadButton.BorderSizePixel = 0
	reloadButton.Text = "Reload"
	reloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	reloadButton.TextSize = 14
	reloadButton.Font = Enum.Font.Gotham
	reloadButton.Parent = buttonContainer
	
	local reloadCorner = Instance.new("UICorner")
	reloadCorner.CornerRadius = UDim.new(0, 6)
	reloadCorner.Parent = reloadButton
	
	reloadButton.MouseButton1Click:Connect(function()
		RemoteEvents.ReloadGame:FireServer(gameId)
		dashboardFrame.Visible = false
		blur.Size = 0
	end)
	
	-- Leaderboard button
	local leaderboardButton = Instance.new("TextButton")
	leaderboardButton.Name = "LeaderboardButton"
	leaderboardButton.Size = UDim2.new(0, 110, 1, 0)
	leaderboardButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	leaderboardButton.BorderSizePixel = 0
	leaderboardButton.Text = "🏆 Leaderboard"
	leaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	leaderboardButton.TextSize = 14
	leaderboardButton.Font = Enum.Font.Gotham
	leaderboardButton.Parent = buttonContainer
	
	local leaderboardCorner = Instance.new("UICorner")
	leaderboardCorner.CornerRadius = UDim.new(0, 6)
	leaderboardCorner.Parent = leaderboardButton
	
	-- Get leaderboard module
	local leaderboardModule = require(ReplicatedStorage:WaitForChild("GameboyLeaderboard"))
	
	leaderboardButton.MouseButton1Click:Connect(function()
		leaderboardModule.show(gameId)
	end)
	
	-- Save slots container
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "SlotsContainer"
	slotsContainer.Size = UDim2.new(1, -20, 0, 120)
	slotsContainer.Position = UDim2.new(0, 10, 0, 70)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.Parent = card
	
	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.Padding = UDim.new(0, 5)
	slotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	slotsLayout.Parent = slotsContainer
	
	-- Create save slot buttons
	for i = 1, MAX_SAVE_SLOTS do
		local slot = gameData.saveSlots[i]
		local slotButton = Instance.new("TextButton")
		slotButton.Name = "Slot" .. i
		slotButton.Size = UDim2.new(0, 150, 1, 0)
		slotButton.BackgroundColor3 = slot and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40)
		slotButton.BorderSizePixel = 0
		slotButton.Text = ""
		slotButton.Parent = slotsContainer
		
		-- Slot name
		local slotName = Instance.new("TextLabel")
		slotName.Name = "Name"
		slotName.Size = UDim2.new(1, -10, 0, 25)
		slotName.Position = UDim2.new(0, 5, 0, 5)
		slotName.BackgroundTransparency = 1
		slotName.Text = slot and slot.name or ("Slot " .. i)
		slotName.TextColor3 = slot and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
		slotName.TextSize = 14
		slotName.Font = Enum.Font.Gotham
		slotName.TextXAlignment = Enum.TextXAlignment.Left
		slotName.Parent = slotButton
		
		-- Slot timestamp
		if slot then
			local slotTime = Instance.new("TextLabel")
			slotTime.Name = "Time"
			slotTime.Size = UDim2.new(1, -10, 0, 20)
			slotTime.Position = UDim2.new(0, 5, 0, 30)
			slotTime.BackgroundTransparency = 1
			slotTime.Text = formatTime(slot.timestamp)
			slotTime.TextColor3 = Color3.fromRGB(200, 200, 200)
			slotTime.TextSize = 12
			slotTime.Font = Enum.Font.Gotham
			slotTime.TextXAlignment = Enum.TextXAlignment.Left
			slotTime.Parent = slotButton
		end
		
		-- Load button (if slot exists)
		if slot then
			local loadBtn = Instance.new("TextButton")
			loadBtn.Name = "LoadButton"
			loadBtn.Size = UDim2.new(0.45, -5, 0, 25)
			loadBtn.Position = UDim2.new(0, 5, 1, -30)
			loadBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			loadBtn.BorderSizePixel = 0
			loadBtn.Text = "Load"
			loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			loadBtn.TextSize = 12
			loadBtn.Font = Enum.Font.Gotham
			loadBtn.Parent = slotButton
			
			loadBtn.MouseButton1Click:Connect(function()
				RemoteEvents.LoadState:FireServer(i)
				dashboardFrame.Visible = false
				blur.Size = 0
			end)
			
			-- Delete button
			local deleteBtn = Instance.new("TextButton")
			deleteBtn.Name = "DeleteButton"
			deleteBtn.Size = UDim2.new(0.45, -5, 0, 25)
			deleteBtn.Position = UDim2.new(0.55, 0, 1, -30)
			deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			deleteBtn.BorderSizePixel = 0
			deleteBtn.Text = "Delete"
			deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			deleteBtn.TextSize = 12
			deleteBtn.Font = Enum.Font.Gotham
			deleteBtn.Parent = slotButton
			
			deleteBtn.MouseButton1Click:Connect(function()
				RemoteEvents.DeleteSaveSlot:FireServer(gameId, i)
				-- Refresh games list
				RemoteEvents.GetPlayerGames:FireServer()
			end)
		end
	end
	
	-- Update slots container size
	slotsContainer.Size = UDim2.new(1, -20, 0, 120)
end

-- Update games list
local function updateGamesList(games: { [string]: any })
	-- Clear existing cards
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end
	
	gamesData = games
	
	-- Create cards for each game
	for gameId, gameData in pairs(games) do
		createGameCard(gameId, gameData)
	end
	
	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- Handle games list updates
RemoteEvents.GetPlayerGames.OnClientEvent:Connect(function(games: { [string]: any })
	updateGamesList(games)
end)

-- Toggle dashboard
local function toggleDashboard()
	print("[GameboyDashboard] toggleDashboard called")
	local success, err = pcall(function()
		dashboardFrame.Visible = not dashboardFrame.Visible
		print("[GameboyDashboard] dashboardFrame.Visible =", dashboardFrame.Visible)
		print("[GameboyDashboard] dashboardFrame.Parent =", dashboardFrame.Parent)
		print("[GameboyDashboard] dashboardScreenGui.DisplayOrder =", dashboardScreenGui.DisplayOrder)
		if dashboardFrame.Visible then
			blur.Size = 24
			-- Refresh games list
			RemoteEvents.GetPlayerGames:FireServer()
			print("[GameboyDashboard] Dashboard opened - Frame visible, blur enabled")
		else
			blur.Size = 0
			print("[GameboyDashboard] Dashboard closed - Frame hidden, blur disabled")
		end
	end)
	if not success then
		warn("[GameboyDashboard] Error in toggleDashboard:", err)
	end
end

-- Close button
closeButton.MouseButton1Click:Connect(function()
	toggleDashboard()
end)

-- Save UI ScreenGui (separate for proper layering)
local saveUIScreenGui = Instance.new("ScreenGui")
saveUIScreenGui.Name = "GameboySaveUIGui"
saveUIScreenGui.ResetOnSpawn = false
saveUIScreenGui.DisplayOrder = 200
saveUIScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
saveUIScreenGui.Parent = playerGui

-- Save UI (shown during gameplay)
local saveUIFrame = Instance.new("Frame")
saveUIFrame.Name = "SaveUI"
saveUIFrame.Size = UDim2.new(0, 400, 0, 300)
saveUIFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
saveUIFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
saveUIFrame.BorderSizePixel = 0
saveUIFrame.Visible = false
saveUIFrame.ZIndex = 1
saveUIFrame.Parent = saveUIScreenGui

-- Add corner to save UI frame
local saveUICorner = Instance.new("UICorner")
saveUICorner.CornerRadius = UDim.new(0, 12)
saveUICorner.Parent = saveUIFrame

local saveUITitle = Instance.new("TextLabel")
saveUITitle.Name = "Title"
saveUITitle.Size = UDim2.new(1, 0, 0, 40)
saveUITitle.Position = UDim2.new(0, 0, 0, 0)
saveUITitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
saveUITitle.BorderSizePixel = 0
saveUITitle.Text = "Save Game"
saveUITitle.TextColor3 = Color3.fromRGB(255, 255, 255)
saveUITitle.TextSize = 20
saveUITitle.Font = Enum.Font.GothamBold
saveUITitle.ZIndex = 2
saveUITitle.Parent = saveUIFrame

-- Add corner to title
local saveUITitleCorner = Instance.new("UICorner")
saveUITitleCorner.CornerRadius = UDim.new(0, 12)
saveUITitleCorner.Parent = saveUITitle

local saveUISlotsContainer = Instance.new("Frame")
saveUISlotsContainer.Name = "SlotsContainer"
saveUISlotsContainer.Size = UDim2.new(1, -20, 1, -100)
saveUISlotsContainer.Position = UDim2.new(0, 10, 0, 50)
saveUISlotsContainer.BackgroundTransparency = 1
saveUISlotsContainer.Parent = saveUIFrame

local saveUISlotsLayout = Instance.new("UIListLayout")
saveUISlotsLayout.FillDirection = Enum.FillDirection.Vertical
saveUISlotsLayout.Padding = UDim.new(0, 5)
saveUISlotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
saveUISlotsLayout.Parent = saveUISlotsContainer

-- Show save UI
local function showSaveUI(currentGameData: any?)
	print("[GameboyDashboard] showSaveUI called, currentGameData:", currentGameData ~= nil)
	saveUIFrame.Visible = true
	print("[GameboyDashboard] saveUIFrame.Visible =", saveUIFrame.Visible)
	print("[GameboyDashboard] saveUIFrame.Parent =", saveUIFrame.Parent)
	print("[GameboyDashboard] saveUIScreenGui.DisplayOrder =", saveUIScreenGui.DisplayOrder)
	
	-- Clear existing slots
	for _, child in ipairs(saveUISlotsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Create slot selection buttons
	for i = 1, MAX_SAVE_SLOTS do
		local slot = currentGameData and currentGameData.saveSlots[i]
		local slotFrame = Instance.new("Frame")
		slotFrame.Name = "Slot" .. i
		slotFrame.Size = UDim2.new(1, 0, 0, 40)
		slotFrame.BackgroundColor3 = slot and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 50, 50)
		slotFrame.BorderSizePixel = 0
		slotFrame.ZIndex = 2
		slotFrame.Parent = saveUISlotsContainer
		
		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slotFrame
		
		local slotNameInput = Instance.new("TextBox")
		slotNameInput.Name = "NameInput"
		slotNameInput.Size = UDim2.new(0.6, -5, 1, -10)
		slotNameInput.Position = UDim2.new(0, 5, 0, 5)
		slotNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		slotNameInput.BorderSizePixel = 0
		slotNameInput.Text = slot and slot.name or ("Slot " .. i)
		slotNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotNameInput.TextSize = 14
		slotNameInput.Font = Enum.Font.Gotham
		slotNameInput.PlaceholderText = "Slot name..."
		slotNameInput.ZIndex = 3
		slotNameInput.Parent = slotFrame
		
		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 4)
		inputCorner.Parent = slotNameInput
		
		local saveButton = Instance.new("TextButton")
		saveButton.Name = "SaveButton"
		saveButton.Size = UDim2.new(0.35, -5, 1, -10)
		saveButton.Position = UDim2.new(0.65, 0, 0, 5)
		saveButton.BackgroundColor3 = slot and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(0, 200, 0)
		saveButton.BorderSizePixel = 0
		saveButton.Text = slot and "Overwrite" or "Save"
		saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		saveButton.TextSize = 14
		saveButton.Font = Enum.Font.Gotham
		saveButton.ZIndex = 3
		saveButton.Parent = slotFrame
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 4)
		buttonCorner.Parent = saveButton
		
		saveButton.MouseButton1Click:Connect(function()
			local slotName = slotNameInput.Text
			if slotName == "" then
				slotName = "Slot " .. i
			end
			RemoteEvents.SaveState:FireServer(i, slotName)
			saveUIFrame.Visible = false
		end)
	end
	
	-- Close button (only create once, reuse if exists)
	local saveUIClose = saveUIFrame:FindFirstChild("CloseButton")
	if not saveUIClose then
		saveUIClose = Instance.new("TextButton")
		saveUIClose.Name = "CloseButton"
		saveUIClose.Size = UDim2.new(0, 100, 0, 30)
		saveUIClose.Position = UDim2.new(0.5, -50, 1, -40)
		saveUIClose.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		saveUIClose.BorderSizePixel = 0
		saveUIClose.Text = "Cancel"
		saveUIClose.TextColor3 = Color3.fromRGB(255, 255, 255)
		saveUIClose.TextSize = 14
		saveUIClose.Font = Enum.Font.Gotham
		saveUIClose.ZIndex = 2
		saveUIClose.Parent = saveUIFrame
		
		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0, 6)
		closeCorner.Parent = saveUIClose
		
		saveUIClose.MouseButton1Click:Connect(function()
			saveUIFrame.Visible = false
		end)
	end
	
	saveUIClose.MouseButton1Click:Connect(function()
		saveUIFrame.Visible = false
	end)
end

-- Track current game (will be set when game loads)
local currentGameId: string? = nil

-- Handle current game updates from server
RemoteEvents.CurrentGameUpdate.OnClientEvent:Connect(function(gameId: string)
	currentGameId = gameId
end)


-- Function to show save UI (can be called from main client)
local function showSaveUIWrapper()
	print("[GameboyDashboard] showSaveUIWrapper called")
	local success, err = pcall(function()
		-- Get current game data and show save UI
		RemoteEvents.GetPlayerGames:FireServer()
		-- Wait a moment for games to be received, then show UI
		task.spawn(function()
			task.wait(0.2)
			if currentGameId and gamesData[currentGameId] then
				showSaveUI(gamesData[currentGameId])
				print("[GameboyDashboard] Save UI shown with game data")
			else
				showSaveUI() -- Show empty slots
				print("[GameboyDashboard] Save UI shown (no game data)")
			end
		end)
	end)
	if not success then
		warn("[GameboyDashboard] Error in showSaveUIWrapper:", err)
	end
end

-- Export functions
GameboyDashboard.showSaveUI = showSaveUIWrapper
GameboyDashboard.toggleDashboard = toggleDashboard

return GameboyDashboard

