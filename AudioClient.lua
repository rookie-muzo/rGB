--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Waveform Asset IDs (TODO: Replace with actual Asset IDs after uploading)
-- These are placeholders - user must upload assets and update these values
local WAVEFORM_ASSETS = {
	-- Pulse channel duty cycles
	Square_12_5 = "rbxassetid://78480806309019", -- TODO: Replace with actual Asset ID
	Square_25 = "rbxassetid://74842452805310",   -- TODO: Replace with actual Asset ID
	Square_50 = "rbxassetid://124203102353983",   -- TODO: Replace with actual Asset ID
	Square_75 = "rbxassetid://123514182401703",   -- TODO: Replace with actual Asset ID
	
	-- Wave channel
	Wave_Default_32 = "rbxassetid://132760378069518", -- TODO: Replace with actual Asset ID
	
	-- Noise channel
	-- NOTE: Noise_LFSR15 is the filtered version (Noise_LFSR15_Filtered.wav)
	-- The original was rejected by Roblox moderation
	Noise_LFSR15 = "rbxassetid://74085613598777", -- Filtered LFSR15 (moderation-safe)
	Noise_LFSR7 = "rbxassetid://96614979809415",  -- Already uploaded and accepted
}

-- Base frequencies for playback speed calculation
local PULSE_BASE_FREQ = 172.27  -- 44100 / 256
local WAVE_BASE_FREQ = 1378.125  -- 44100 / 32

-- Noise channel gain compensation (LFSR7 is significantly louder than filtered LFSR15)
local GAIN_LFSR15 = 1.0   -- Filtered LFSR15 (baseline)
local GAIN_LFSR7 = 0.10   -- Raw LFSR7 (needs significant attenuation to match)

local AudioClient = {}

-- Audio objects
local audioPlayers = {}
local audioEffects = {}
local audioOutput = nil

-- Channel state
local channelStates = {
	tone1 = { frequency = 0, volume = 0, enabled = false, dutyCycle = 0.5, sweepActive = false, panLeft = false, panRight = false },
	tone2 = { frequency = 0, volume = 0, enabled = false, dutyCycle = 0.5, panLeft = false, panRight = false },
	wave3 = { frequency = 0, volume = 0, enabled = false, panLeft = false, panRight = false },
	noise4 = { volume = 0, enabled = false, lfsrType = 15, panLeft = false, panRight = false }
}

local masterVolume = { left = 1.0, right = 1.0 }

-- Helper function to create a Wire between two audio objects
local function createWire(source: Instance, target: Instance, sourceName: string?, targetName: string?): Wire
	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = target
	if sourceName then
		wire.SourceName = sourceName
	end
	if targetName then
		wire.TargetName = targetName
	end
	wire.Parent = source
	return wire
end

-- Initialize audio system
local function initializeAudio()
	-- Create SoundService container
	local soundServiceContainer = Instance.new("Folder")
	soundServiceContainer.Name = "GameboyAudio"
	soundServiceContainer.Parent = SoundService
	
	-- Create AudioDeviceOutput
	audioOutput = Instance.new("AudioDeviceOutput")
	audioOutput.Name = "GameboyAudioOutput"
	audioOutput.Parent = soundServiceContainer
	
	-- Create AudioChannelMixer to mix all 4 channels together
	local audioMixer = Instance.new("AudioChannelMixer")
	audioMixer.Name = "GameboyMixer"
	audioMixer.Layout = Enum.AudioChannelLayout.Mono -- Mix to mono for Game Boy
	audioMixer.Parent = soundServiceContainer
	
	-- Create shared audio effects chain (applied to mixed output)
	-- AudioEqualizer (DMG frequency response)
	local equalizer = Instance.new("AudioEqualizer")
	equalizer.Name = "DMGEqualizer"
	equalizer.LowGain = -15  -- Roll-off below ~100 Hz
	equalizer.MidGain = 3    -- 1-2 kHz "honk"
	equalizer.HighGain = -10 -- Roll-off above ~4-5 kHz
	equalizer.Parent = soundServiceContainer
	audioEffects.equalizer = equalizer
	
	-- AudioCompressor (mixer saturation)
	local compressor = Instance.new("AudioCompressor")
	compressor.Name = "DMGCompressor"
	compressor.Ratio = 2.5
	compressor.Threshold = -12
	compressor.Attack = 0.05
	compressor.Release = 0.2
	compressor.Parent = soundServiceContainer
	audioEffects.compressor = compressor
	
	-- AudioDistortion (optional, very subtle)
	local distortion = Instance.new("AudioDistortion")
	distortion.Name = "DMGDistortion"
	distortion.Level = 0.1  -- Very low, barely audible
	distortion.Parent = soundServiceContainer
	audioEffects.distortion = distortion
	
	-- AudioLimiter (final safety limiter to catch summed peaks and prevent fizz/crackle)
	local limiter = Instance.new("AudioLimiter")
	limiter.Name = "DMGLimiter"
	limiter.MaxLevel = -1  -- Very gentle limit, catches rare overs (output won't exceed -1 dB, range: -12 to 0)
	limiter.Release = 0.05  -- Fast release to avoid pumping (range: 0.001 to 1)
	limiter.Parent = soundServiceContainer
	audioEffects.limiter = limiter
	
	-- Wire effects chain using Wire objects: Mixer → Equalizer → Compressor → Distortion → Limiter → Output
	createWire(audioMixer, equalizer, "Output", "Input")
	createWire(equalizer, compressor, "Output", "Input")
	createWire(compressor, distortion, "Output", "Input")
	createWire(distortion, limiter, "Output", "Input")
	createWire(limiter, audioOutput, "Output", "Input")
	
	-- Create 4 AudioPlayer objects (one per channel)
	-- All channels route to the AudioMixer, which then goes through shared effects
	local channelNames = { "tone1", "tone2", "wave3", "noise4" }
	
	for _, channelName in ipairs(channelNames) do
		local audioPlayer = Instance.new("AudioPlayer")
		audioPlayer.Name = "Channel_" .. channelName
		audioPlayer.Looping = true
		audioPlayer.Volume = 0
		audioPlayer.Parent = soundServiceContainer
		
		-- Wire AudioPlayer to AudioMixer (all channels mix together)
		createWire(audioPlayer, audioMixer, "Output", "Input")
		
		audioPlayers[channelName] = audioPlayer
	end
	
	-- Set initial waveform assets
	audioPlayers.tone1.AssetId = WAVEFORM_ASSETS.Square_50
	audioPlayers.tone2.AssetId = WAVEFORM_ASSETS.Square_50
	audioPlayers.wave3.AssetId = WAVEFORM_ASSETS.Wave_Default_32
	audioPlayers.noise4.AssetId = WAVEFORM_ASSETS.Noise_LFSR15
	
	print("[AudioClient] Audio system initialized")
end

-- Get duty cycle asset name
local function getDutyCycleAsset(dutyCycle: number): string
	if dutyCycle == 0.125 then
		return WAVEFORM_ASSETS.Square_12_5
	elseif dutyCycle == 0.25 then
		return WAVEFORM_ASSETS.Square_25
	elseif dutyCycle == 0.5 then
		return WAVEFORM_ASSETS.Square_50
	elseif dutyCycle == 0.75 then
		return WAVEFORM_ASSETS.Square_75
	else
		return WAVEFORM_ASSETS.Square_50 -- Default
	end
end

-- Update a channel
local function updateChannel(channelName: string, params: any)
	local channel = channelStates[channelName]
	local audioPlayer = audioPlayers[channelName]
	
	if not channel or not audioPlayer then
		return
	end
	
	-- Update frequency (for tone1, tone2, wave3)
	if params.frequency ~= nil and (channelName == "tone1" or channelName == "tone2" or channelName == "wave3") then
		local baseFreq = (channelName == "wave3") and WAVE_BASE_FREQ or PULSE_BASE_FREQ
		local playbackSpeed = params.frequency > 0 and (params.frequency / baseFreq) or 0
		audioPlayer.PlaybackSpeed = playbackSpeed
		channel.frequency = params.frequency
	end
	
	-- Update volume
	if params.volume ~= nil then
		-- Apply master volume (use average of left/right for mono output, or implement proper panning)
		local masterVol = (masterVolume.left + masterVolume.right) / 2
		local finalVolume = params.volume * masterVol
		
		-- Apply per-mode gain compensation for noise channel
		if channelName == "noise4" then
			local lfsrGain = (channel.lfsrType == 7) and GAIN_LFSR7 or GAIN_LFSR15
			finalVolume = finalVolume * lfsrGain
		end
		
		-- Apply wave channel compensation (helps wave channel cut through psychoacoustically)
		if channelName == "wave3" then
			finalVolume = finalVolume * 1.15
		end
		
		audioPlayer.Volume = finalVolume
		channel.volume = params.volume
	end
	
	-- Update enabled state
	if params.enabled ~= nil then
		channel.enabled = params.enabled
		if params.enabled then
			if not audioPlayer.IsPlaying then
				audioPlayer:Play()
			end
		else
			audioPlayer.Volume = 0
		end
	end
	
	-- Update duty cycle (for tone1, tone2)
	if params.dutyCycle ~= nil and (channelName == "tone1" or channelName == "tone2") then
		if channel.dutyCycle ~= params.dutyCycle then
			local assetId = getDutyCycleAsset(params.dutyCycle)
			audioPlayer.AssetId = assetId
			channel.dutyCycle = params.dutyCycle
		end
	end
	
	-- Update LFSR type (for noise4)
	-- When switching LFSR types, restart playback to ensure consistent phase/time behavior
	if params.lfsrType ~= nil and channelName == "noise4" then
		if channel.lfsrType ~= params.lfsrType then
			local wasPlaying = audioPlayer.IsPlaying
			
			-- Stop playback before switching asset
			if wasPlaying then
				audioPlayer:Stop()
			end
			
			-- Switch to the appropriate asset
			local assetId = (params.lfsrType == 15) and WAVEFORM_ASSETS.Noise_LFSR15 or WAVEFORM_ASSETS.Noise_LFSR7
			audioPlayer.AssetId = assetId
			channel.lfsrType = params.lfsrType
			
			-- Reset playback position and restart if it was playing before
			-- This prevents buffer discontinuity crackle when switching LFSR types
			if wasPlaying then
				audioPlayer.TimePosition = 0
				audioPlayer:Play()
			end
			
			-- Recalculate volume with new gain compensation (use current channel volume)
			local currentVolume = params.volume or channel.volume or 0
			if currentVolume > 0 then
				local masterVol = (masterVolume.left + masterVolume.right) / 2
				local lfsrGain = (params.lfsrType == 7) and GAIN_LFSR7 or GAIN_LFSR15
				local finalVolume = currentVolume * masterVol * lfsrGain
				audioPlayer.Volume = finalVolume
			end
		end
	end
	
	-- Update panning (hard L/R routing)
	-- NOTE: Roblox AudioPlayer doesn't support true hard L/R panning without separate AudioDeviceOutput objects
	-- The Game Boy has hard L/R routing (binary), but Roblox's audio system mixes all channels to mono
	-- For true hard L/R panning, we would need:
	--   - Separate AudioDeviceOutput objects for left and right
	--   - Route channels to left/right outputs based on panLeft/panRight flags
	--   - This is a limitation of the current Roblox audio API
	-- For now, we track panning state but use mono output (volume averaging)
	-- The panning information is available in channel state if needed for future enhancement
	if params.panLeft ~= nil then
		channel.panLeft = params.panLeft
	end
	if params.panRight ~= nil then
		channel.panRight = params.panRight
	end
end

-- Handle audio channel updates from server
RemoteEvents.AudioChannelUpdate.OnClientEvent:Connect(function(channelData: any)
	if not channelData then
		return
	end
	
	-- Update master volume
	if channelData.masterVolume then
		masterVolume.left = channelData.masterVolume.left or 1.0
		masterVolume.right = channelData.masterVolume.right or 1.0
	end
	
	-- Update each channel
	if channelData.tone1 then
		updateChannel("tone1", channelData.tone1)
	end
	if channelData.tone2 then
		updateChannel("tone2", channelData.tone2)
	end
	if channelData.wave3 then
		updateChannel("wave3", channelData.wave3)
	end
	if channelData.noise4 then
		updateChannel("noise4", channelData.noise4)
	end
end)

-- Handle audio reset
RemoteEvents.AudioReset.OnClientEvent:Connect(function()
	-- Stop all channels
	for channelName, audioPlayer in pairs(audioPlayers) do
		audioPlayer.Volume = 0
		audioPlayer:Stop()
		channelStates[channelName].enabled = false
		channelStates[channelName].volume = 0
	end
	print("[AudioClient] Audio reset")
end)

-- Initialize audio system
initializeAudio()

-- Export functions
function AudioClient.start()
	-- Audio is always running, just ensure channels are ready
	print("[AudioClient] Audio started")
end

function AudioClient.stop()
	-- Stop all channels
	for _, audioPlayer in pairs(audioPlayers) do
		audioPlayer.Volume = 0
		audioPlayer:Stop()
	end
	print("[AudioClient] Audio stopped")
end

function AudioClient.setWaveformAssets(assets: { [string]: string })
	-- Allow runtime update of asset IDs
	for key, value in pairs(assets) do
		if WAVEFORM_ASSETS[key] then
			WAVEFORM_ASSETS[key] = value
		end
	end
	print("[AudioClient] Waveform assets updated")
end

return AudioClient

