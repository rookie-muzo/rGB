local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local GameboyDataStore = {}

-- Create DataStores
local playerDataStore = DataStoreService:GetDataStore("GameboyPlayerData")
local leaderboardStore = DataStoreService:GetDataStore("GameboyLeaderboards")

-- Constants
local MAX_SAVE_SLOTS = 5

-- Generate game ID from title and type
function GameboyDataStore.generateGameId(title: string, isColor: boolean): string
	local gameType = isColor and "GBC" or "GB"
	local cleanTitle = title:gsub("%s+", "_"):gsub("[^%w_]", "")
	return cleanTitle .. "_" .. gameType
end

-- Get player data
function GameboyDataStore.getPlayerData(player: Player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync("Player_" .. player.UserId)
	end)
	
	if success and data then
		return data
	else
		-- Return default structure
		return {
			games = {}
		}
	end
end

-- Save player data
function GameboyDataStore.savePlayerData(player: Player, data: any): boolean
	local success, error = pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)
	
	if not success then
		warn("[GameboyDataStore] Failed to save data for", player.Name, ":", error)
		return false
	end
	
	return true
end

-- Get game data for a player
function GameboyDataStore.getGameData(player: Player, gameId: string)
	local playerData = GameboyDataStore.getPlayerData(player)
	return playerData.games[gameId]
end

-- Save game data
function GameboyDataStore.saveGameData(player: Player, gameId: string, gameData: any): boolean
	local playerData = GameboyDataStore.getPlayerData(player)
	playerData.games[gameId] = gameData
	return GameboyDataStore.savePlayerData(player, playerData)
end

-- Add or update a game entry
function GameboyDataStore.addGame(player: Player, gameId: string, url: string, title: string, isColor: boolean)
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		playerData.games[gameId] = {
			url = url,
			title = title,
			type = isColor and "GBC" or "GB",
			lastPlayed = os.time(),
			saveSlots = {}
		}
		
		-- Initialize empty save slots
		for i = 1, MAX_SAVE_SLOTS do
			playerData.games[gameId].saveSlots[i] = nil
		end
	else
		-- Update last played time
		playerData.games[gameId].lastPlayed = os.time()
	end
	
	return GameboyDataStore.savePlayerData(player, playerData)
end

-- Save state to a slot
function GameboyDataStore.saveState(player: Player, gameId: string, slotNumber: number, state: any, slotName: string?): boolean
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		warn("[GameboyDataStore] Game not found:", gameId)
		return false
	end
	
	if slotNumber < 1 or slotNumber > MAX_SAVE_SLOTS then
		warn("[GameboyDataStore] Invalid slot number:", slotNumber)
		return false
	end
	
	-- Serialize state to JSON
	local success, serialized = pcall(function()
		return HttpService:JSONEncode(state)
	end)
	
	if not success then
		warn("[GameboyDataStore] Failed to serialize save state:", serialized)
		return false
	end
	
	-- Save to slot
	playerData.games[gameId].saveSlots[slotNumber] = {
		state = serialized,
		timestamp = os.time(),
		name = slotName or ("Slot " .. tostring(slotNumber))
	}
	
	return GameboyDataStore.savePlayerData(player, playerData)
end

-- Load state from a slot
function GameboyDataStore.loadState(player: Player, gameId: string, slotNumber: number): (any?, string?)
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		return nil, "Game not found"
	end
	
	if slotNumber < 1 or slotNumber > MAX_SAVE_SLOTS then
		return nil, "Invalid slot number"
	end
	
	local slot = playerData.games[gameId].saveSlots[slotNumber]
	if not slot then
		return nil, "Slot is empty"
	end
	
	-- Deserialize state from JSON
	local success, state = pcall(function()
		return HttpService:JSONDecode(slot.state)
	end)
	
	if not success then
		return nil, "Failed to deserialize save state: " .. tostring(state)
	end
	
	return state, nil
end

-- Delete a save slot
function GameboyDataStore.deleteSlot(player: Player, gameId: string, slotNumber: number): boolean
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		return false
	end
	
	if slotNumber < 1 or slotNumber > MAX_SAVE_SLOTS then
		return false
	end
	
	playerData.games[gameId].saveSlots[slotNumber] = nil
	return GameboyDataStore.savePlayerData(player, playerData)
end

-- Get all games for a player
function GameboyDataStore.getAllGames(player: Player)
	local playerData = GameboyDataStore.getPlayerData(player)
	return playerData.games
end

-- Save battery-backed RAM (in-game save)
function GameboyDataStore.saveBatteryRam(player: Player, gameId: string, externalRam: { [number]: number }): boolean
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		warn("[GameboyDataStore] Game not found for battery RAM save:", gameId)
		return false
	end
	
	-- Convert external_ram table to array format for JSON serialization
	-- external_ram is a sparse table, so we need to capture all non-nil values
	local ramData = {}
	local maxIndex = 0
	for i, v in pairs(externalRam) do
		if i ~= "dirty" and type(i) == "number" then
			ramData[i] = v
			if i > maxIndex then
				maxIndex = i
			end
		end
	end
	
	-- Serialize to JSON
	local success, serialized = pcall(function()
		return HttpService:JSONEncode({
			data = ramData,
			maxIndex = maxIndex
		})
	end)
	
	if not success then
		warn("[GameboyDataStore] Failed to serialize battery RAM:", serialized)
		return false
	end
	
	-- Save to game data
	playerData.games[gameId].batteryRam = serialized
	playerData.games[gameId].batteryRamTimestamp = os.time()
	
	return GameboyDataStore.savePlayerData(player, playerData)
end

-- Load battery-backed RAM (in-game save)
function GameboyDataStore.loadBatteryRam(player: Player, gameId: string): ({ [number]: number }?, string?)
	local playerData = GameboyDataStore.getPlayerData(player)
	
	if not playerData.games[gameId] then
		return nil, "Game not found"
	end
	
	local batteryRamData = playerData.games[gameId].batteryRam
	if not batteryRamData then
		return nil, "No battery RAM save found"
	end
	
	-- Deserialize from JSON
	local success, ramData = pcall(function()
		return HttpService:JSONDecode(batteryRamData)
	end)
	
	if not success then
		return nil, "Failed to deserialize battery RAM: " .. tostring(ramData)
	end
	
	-- Convert back to sparse table format
	local externalRam = {}
	for i, v in pairs(ramData.data) do
		externalRam[i] = v
	end
	externalRam.dirty = false
	
	return externalRam, nil
end

-- Save a score to leaderboard
function GameboyDataStore.saveScore(player: Player, gameId: string, score: number): boolean
	if score <= 0 then
		return false
	end
	
	local success, error = pcall(function()
		-- Get current leaderboard
		local leaderboardKey = "Leaderboard_" .. gameId
		local leaderboardData = leaderboardStore:GetAsync(leaderboardKey)
		
		if not leaderboardData then
			leaderboardData = {
				scores = {}
			}
		end
		
		-- Add or update player's score
		local playerId = tostring(player.UserId)
		local playerScore = {
			playerId = player.UserId,
			playerName = player.Name,
			score = score,
			timestamp = os.time()
		}
		
		-- Check if player already has a score entry
		local found = false
		for i, entry in ipairs(leaderboardData.scores) do
			if tostring(entry.playerId) == playerId then
				-- Update if new score is higher
				if score > entry.score then
					leaderboardData.scores[i] = playerScore
					found = true
				else
					found = true -- Already have a better score
				end
				break
			end
		end
		
		if not found then
			table.insert(leaderboardData.scores, playerScore)
		end
		
		-- Sort by score (descending)
		table.sort(leaderboardData.scores, function(a, b)
			if a.score == b.score then
				return a.timestamp < b.timestamp -- Earlier timestamp wins tie
			end
			return a.score > b.score
		end)
		
		-- Keep only top 100 scores
		if #leaderboardData.scores > 100 then
			for i = 101, #leaderboardData.scores do
				leaderboardData.scores[i] = nil
			end
		end
		
		-- Save back to DataStore
		leaderboardStore:SetAsync(leaderboardKey, leaderboardData)
		
		return true
	end)
	
	if not success then
		warn("[GameboyDataStore] Failed to save score for", player.Name, ":", error)
		return false
	end
	
	return true
end

-- Get leaderboard for a game
function GameboyDataStore.getLeaderboard(gameId: string, limit: number?): { [number]: any }
	limit = limit or 10
	
	local success, leaderboardData = pcall(function()
		local leaderboardKey = "Leaderboard_" .. gameId
		return leaderboardStore:GetAsync(leaderboardKey)
	end)
	
	if not success or not leaderboardData then
		return {}
	end
	
	-- Add rank numbers
	local scores = {}
	for i, entry in ipairs(leaderboardData.scores) do
		if i <= limit then
			local rankedEntry = {}
			for k, v in pairs(entry) do
				rankedEntry[k] = v
			end
			rankedEntry.rank = i
			table.insert(scores, rankedEntry)
		end
	end
	
	return scores
end

-- Get player's best score for a game
function GameboyDataStore.getPlayerBestScore(player: Player, gameId: string): (number?, number?)
	local success, leaderboardData = pcall(function()
		local leaderboardKey = "Leaderboard_" .. gameId
		return leaderboardStore:GetAsync(leaderboardKey)
	end)
	
	if not success or not leaderboardData then
		return nil, nil
	end
	
	local playerId = tostring(player.UserId)
	for i, entry in ipairs(leaderboardData.scores) do
		if tostring(entry.playerId) == playerId then
			return entry.score, i -- Return score and rank
		end
	end
	
	return nil, nil
end

return GameboyDataStore


