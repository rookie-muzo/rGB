local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for RemoteEvents
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Module table
local GameboyLeaderboard = {}

-- Create leaderboard ScreenGui
local leaderboardScreenGui = Instance.new("ScreenGui")
leaderboardScreenGui.Name = "GameboyLeaderboardGui"
leaderboardScreenGui.ResetOnSpawn = false
leaderboardScreenGui.DisplayOrder = 150
leaderboardScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
leaderboardScreenGui.Parent = playerGui

-- Main leaderboard frame
local leaderboardFrame = Instance.new("Frame")
leaderboardFrame.Name = "LeaderboardFrame"
leaderboardFrame.Size = UDim2.new(0, 500, 0, 600)
leaderboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
leaderboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
leaderboardFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
leaderboardFrame.BorderSizePixel = 0
leaderboardFrame.Visible = false
leaderboardFrame.ZIndex = 1
leaderboardFrame.Parent = leaderboardScreenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = leaderboardFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = leaderboardFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Leaderboard"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

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
closeButton.ZIndex = 3
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Game title
local gameTitleLabel = Instance.new("TextLabel")
gameTitleLabel.Name = "GameTitle"
gameTitleLabel.Size = UDim2.new(1, -40, 0, 30)
gameTitleLabel.Position = UDim2.new(0, 20, 0, 60)
gameTitleLabel.BackgroundTransparency = 1
gameTitleLabel.Text = "Loading..."
gameTitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
gameTitleLabel.TextSize = 16
gameTitleLabel.Font = Enum.Font.GothamBold
gameTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
gameTitleLabel.ZIndex = 2
gameTitleLabel.Parent = leaderboardFrame

-- Scrolling frame for scores
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScoresList"
scrollFrame.Size = UDim2.new(1, -40, 1, -120)
scrollFrame.Position = UDim2.new(0, 20, 0, 100)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ZIndex = 2
scrollFrame.Parent = leaderboardFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Format number with commas
local function formatNumber(num: number): string
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

-- Format timestamp
local function formatTime(timestamp: number): string
	local date = os.date("*t", timestamp)
	return string.format("%02d/%02d/%04d", date.month, date.day, date.year)
end

-- Create score entry
local function createScoreEntry(entry: any, index: number)
	local entryFrame = Instance.new("Frame")
	entryFrame.Name = "ScoreEntry" .. index
	entryFrame.Size = UDim2.new(1, 0, 0, 50)
	entryFrame.BackgroundColor3 = index <= 3 and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)
	entryFrame.BorderSizePixel = 0
	entryFrame.Parent = scrollFrame
	
	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 6)
	entryCorner.Parent = entryFrame
	
	-- Rank
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Size = UDim2.new(0, 50, 1, 0)
	rankLabel.Position = UDim2.new(0, 10, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. tostring(entry.rank)
	rankLabel.TextColor3 = index <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
	rankLabel.TextSize = 18
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = entryFrame
	
	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(0, 200, 1, 0)
	nameLabel.Position = UDim2.new(0, 70, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.playerName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = entryFrame
	
	-- Score
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "Score"
	scoreLabel.Size = UDim2.new(0, 150, 1, 0)
	scoreLabel.Position = UDim2.new(1, -160, 0, 0)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = formatNumber(entry.score)
	scoreLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	scoreLabel.TextSize = 16
	scoreLabel.Font = Enum.Font.GothamBold
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
	scoreLabel.Parent = entryFrame
	
	-- Date
	local dateLabel = Instance.new("TextLabel")
	dateLabel.Name = "Date"
	dateLabel.Size = UDim2.new(0, 100, 0, 20)
	dateLabel.Position = UDim2.new(0, 70, 1, -25)
	dateLabel.BackgroundTransparency = 1
	dateLabel.Text = formatTime(entry.timestamp)
	dateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	dateLabel.TextSize = 12
	dateLabel.Font = Enum.Font.Gotham
	dateLabel.TextXAlignment = Enum.TextXAlignment.Left
	dateLabel.Parent = entryFrame
end

-- Update leaderboard display
local function updateLeaderboardDisplay(gameId: string, leaderboard: { [number]: any })
	-- Clear existing entries
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^ScoreEntry") then
			child:Destroy()
		end
	end
	
	-- Update game title
	local gameTitle = gameId:gsub("_GB$", ""):gsub("_GBC$", ""):gsub("_", " ")
	gameTitleLabel.Text = gameTitle .. " Leaderboard"
	
	-- Create entries
	if #leaderboard == 0 then
		local noScoresLabel = Instance.new("TextLabel")
		noScoresLabel.Size = UDim2.new(1, 0, 0, 50)
		noScoresLabel.BackgroundTransparency = 1
		noScoresLabel.Text = "No scores yet. Be the first!"
		noScoresLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		noScoresLabel.TextSize = 16
		noScoresLabel.Font = Enum.Font.Gotham
		noScoresLabel.Parent = scrollFrame
	else
		for i, entry in ipairs(leaderboard) do
			createScoreEntry(entry, i)
		end
	end
	
	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

-- Handle leaderboard updates
RemoteEvents.LeaderboardUpdate.OnClientEvent:Connect(function(gameId: string, leaderboard: { [number]: any })
	updateLeaderboardDisplay(gameId, leaderboard)
end)

-- Show leaderboard
local function showLeaderboard(gameId: string)
	leaderboardFrame.Visible = true
	-- Request leaderboard data
	RemoteEvents.GetLeaderboard:FireServer(gameId)
end

-- Hide leaderboard
local function hideLeaderboard()
	leaderboardFrame.Visible = false
end

-- Close button
closeButton.MouseButton1Click:Connect(hideLeaderboard)

-- Export functions
GameboyLeaderboard.show = showLeaderboard
GameboyLeaderboard.hide = hideLeaderboard
GameboyLeaderboard.toggle = function(gameId: string)
	if leaderboardFrame.Visible then
		hideLeaderboard()
	else
		showLeaderboard(gameId)
	end
end

return GameboyLeaderboard

