local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Wait for RemoteEvents
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local WIDTH = 160
local HEIGHT = 144

-- Create spectator GUI
local spectatorGui = Instance.new("ScreenGui")
spectatorGui.Name = "GameboySpectator"
spectatorGui.ResetOnSpawn = false
spectatorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
spectatorGui.Enabled = false
spectatorGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, WIDTH * 3, 0, HEIGHT * 3 + 80)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = spectatorGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Spectating..."
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, -20, 0, 20)
subtitleLabel.Position = UDim2.new(0, 10, 0, 40)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Press ESC to stop spectating"
subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitleLabel.TextSize = 12
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = mainFrame

-- Screen container
local screenContainer = Instance.new("Frame")
screenContainer.Name = "ScreenContainer"
screenContainer.Size = UDim2.new(1, -20, 1, -60)
screenContainer.Position = UDim2.new(0, 10, 0, 60)
screenContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
screenContainer.BorderSizePixel = 0
screenContainer.Parent = mainFrame

local screenCorner = Instance.new("UICorner")
screenCorner.CornerRadius = UDim.new(0, 8)
screenCorner.Parent = screenContainer

-- Display frame
local displayFrame = Instance.new("Frame")
displayFrame.Name = "DisplayFrame"
displayFrame.Size = UDim2.new(0, WIDTH * 2.8, 0, HEIGHT * 2.8)
displayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
displayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
displayFrame.BackgroundColor3 = Color3.new(0, 0, 0)
displayFrame.BorderSizePixel = 0
displayFrame.Parent = screenContainer

local displayCorner = Instance.new("UICorner")
displayCorner.CornerRadius = UDim.new(0, 4)
displayCorner.Parent = displayFrame

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

-- Create EditableImage for spectator
local AssetService = game:GetService("AssetService")
local spectatorScreen = AssetService:CreateEditableImage({ Size = Vector2.new(WIDTH, HEIGHT) })
screenImage.ImageContent = Content.fromObject(spectatorScreen)

-- Handle frame data
local frameCount = 0
RemoteEvents.FrameData.OnClientEvent:Connect(function(frameDataString)
	if not spectatorGui.Enabled then
		return
	end
	
	frameCount = frameCount + 1
	
	if frameDataString and #frameDataString > 0 then
		-- Convert string back to buffer
		local success, frameBuffer = pcall(function()
			local buf = buffer.create(WIDTH * HEIGHT * 4)
			local expectedSize = WIDTH * HEIGHT * 4
			
			if #frameDataString ~= expectedSize then
				warn("[Spectator] Frame data size mismatch! Expected:", expectedSize, "Got:", #frameDataString)
			end
			
			-- Convert string bytes to buffer
			for i = 0, math.min(#frameDataString - 1, expectedSize - 1) do
				buffer.writeu8(buf, i, string.byte(frameDataString, i + 1))
			end
			
			return buf
		end)
		
		if success and frameBuffer then
			-- Update EditableImage with frame data
			spectatorScreen:WritePixelsBuffer(Vector2.zero, Vector2.new(WIDTH, HEIGHT), frameBuffer)
		else
			warn("[Spectator] Failed to convert frame data:", frameBuffer)
		end
	end
end)

-- Handle spectating updates
local isSpectating = false
RemoteEvents.SpectatorUpdate.OnClientEvent:Connect(function(spectating: boolean, playerName: string?, gameTitle: string?)
	isSpectating = spectating
	spectatorGui.Enabled = spectating
	
	if spectating then
		if playerName and gameTitle then
			titleLabel.Text = "Spectating " .. playerName .. " - " .. gameTitle
		else
			titleLabel.Text = "Spectating..."
		end
	else
		spectatorGui.Enabled = false
	end
end)

-- Handle Escape key to stop spectating
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	
	if input.KeyCode == Enum.KeyCode.Escape and isSpectating then
		RemoteEvents.StopSpectating:FireServer()
	end
end)

print("[Spectator Client] Loaded")

