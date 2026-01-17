-- REAPER LOGGER BOT v7.1 - OPTIMIZED FOR SPEED
-- ========================
-- EXECUTION GUARD
-- ========================
if _G.REAPER_BOT_RUNNING then
	return
end
_G.REAPER_BOT_RUNNING = true

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PLACE_ID = 109983668079237
local SCAN_DURATION = 3

-- AUTO-RESTART CONFIG
local AUTO_RESTART_ENABLED = true
local RESTART_ON_ERROR_COUNT = 3
local consecutiveErrors = 0

-- ========================
-- API CONFIGURATION
-- ========================
local API_BASE_URL = "https://reaperhubadmin.manus.space"
local API_SERVERS_ENDPOINT = API_BASE_URL .. "/api/data"

-- ========================
-- WEBHOOK CONFIGURATION
-- ========================
local WEBHOOKS = {
	{threshold = 1000000000, url = "https://discord.com/api/webhooks/1449839085618466836/EJ_mosE_BIlOnxh1ybz9LF3Nys9zn92_FXzc_zkHoHCyQAqKu4QDg5P9LiobrxLuZPRR", name = "1B+"},
	{threshold = 300000000, url = "https://discord.com/api/webhooks/1449839022825537786/sBf5I_Aa5WZW-PacXvdzMQXCLhySYpwKppIFJB2RYPk1DDgS9xbd-T5qOv4SmrJWNx4r", name = "300M+"},
	{threshold = 100000000, url = "https://discord.com/api/webhooks/1449838937878167664/-wh9mjxg9reZBGyArotw-2Kah_rI2IntiPRV8JuxHfvLBfvm-hgqzx3PXABQdRTzIDRe", name = "100M+"},
	{threshold = 50000000, url = "https://discord.com/api/webhooks/1449838592200409201/RXZDdX1l9PE2tPQV6VL4zFIK0Q7_Z_28tPd1ZzQIFRDCzph0hz-XQDmHbQIlBLu-DJH6", name = "50M+"},
	{threshold = 10000000, url = "https://discord.com/api/webhooks/1449839469879496754/kZa8bH4QSCwXjRwsOajNUvHq1wosOBsj39ezcw-55rgjS-_qJTe5rVMTIZHWxApD4R3-", name = "10-50M"},
}

local FALLBACK_WEBHOOK = {
	url = "https://discord.com/api/webhooks/1449180921592025245/cwF8NKXB05G8lzJt1ombgvTGdA2SxzdQfDOId-9S_IgF7c26QwgbxRdrQamwwy5VZrqK",
	name = "1-10M",
	color = 0xFFFFFF
}

local MIN_THRESHOLD = 1000000
local HIGHLIGHTS_THRESHOLD = 50000000

-- ========================
-- SPECIAL BRAINROT PINGS
-- ========================
local SPECIAL_PING_BRAINROTS = {
	"Ketupat ketpat",
	"ketchuru and musturu",
	"Tictack sahur",
	"Nuclearo dinosaur",
	"money money puggy",
	"Gobblino Uniciclino",
	"La Supreme Combinasion",
	"Lavadorito Spinito",
	"Tang Tang Keletang"
}
local HIGHLIGHTS_WEBHOOK = "https://discordapp.com/api/webhooks/1449228042990915665/daivH8t-I_Ry-d4QrFNa2oAk8Vo9FWkP8-pzsaWvjar_QIwdNdXpmjZV3nVkQuxQi27Q"
local STATUS_WEBHOOK = "https://discord.com/api/webhooks/1449225207561584772/64Mb0pE4gGhrXMDPj0DVLcupNvSKKop2KgMAgSGxIAC4k7V30vobDh9XX1NXonVzxIeB"
local SECONDARY_1_10M_WEBHOOK = "https://discordapp.com/api/webhooks/1449234826803675219/6t-mirx90KQpP6WnDXkI-78viuzCgHlu2lL-bs-EjZ43lmNBtc5snX9HElbGIuuHVFzr"
local AVATAR_URL = "https://cdn.discordapp.com/attachments/1449158166289059982/1449233510589005975/reaper.png"

-- ========================
-- OPTIMIZED WEBHOOK QUEUE
-- ========================
local webhookQueue = {}
local lastWebhookTime = 0
local dynamicCooldown = 0.1 -- Start with minimal cooldown
local rateLimitRemaining = nil

local function queueWebhook(url, data, priority)
	priority = priority or 5
	table.insert(webhookQueue, {
		url = url,
		data = data,
		priority = priority,
		timestamp = os.time(),
		retries = 0
	})
end

-- OPTIMIZED: Process multiple webhooks in parallel batches
local function processWebhookQueue()
	while true do
		if #webhookQueue > 0 then
			local currentTime = os.time()
			
			-- Sort by priority
			table.sort(webhookQueue, function(a, b)
				return a.priority > b.priority
			end)
			
			if (currentTime - lastWebhookTime) >= dynamicCooldown then
				-- OPTIMIZATION: Process up to 3 webhooks at once
				local batchSize = math.min(3, #webhookQueue)
				local batch = {}
				
				for i = 1, batchSize do
					table.insert(batch, table.remove(webhookQueue, 1))
				end
				
				-- Send all webhooks in batch simultaneously
				for _, webhook in ipairs(batch) do
					task.spawn(function()
						local request = (syn and syn.request) or http_request or request
						if request then
							local success, response = pcall(function()
								return request({
									Url = webhook.url,
									Method = "POST",
									Headers = {["Content-Type"] = "application/json"},
									Body = HttpService:JSONEncode(webhook.data)
								})
							end)
							
							if success and response then
								-- Parse rate limit headers
								if response.Headers then
									local remaining = response.Headers["x-ratelimit-remaining"] or response.Headers["X-RateLimit-Remaining"]
									if remaining then
										rateLimitRemaining = tonumber(remaining)
										-- Adjust cooldown based on remaining requests
										if rateLimitRemaining and rateLimitRemaining > 10 then
											dynamicCooldown = 0.05 -- Very fast
										elseif rateLimitRemaining and rateLimitRemaining > 5 then
											dynamicCooldown = 0.1 -- Fast
										else
											dynamicCooldown = 0.3 -- Slow down
										end
									end
								end
							elseif not success and webhook.retries < 2 then
								webhook.retries = webhook.retries + 1
								table.insert(webhookQueue, webhook)
							end
						end
					end)
				end
				
				lastWebhookTime = currentTime
			end
		end
		task.wait(0.05) -- Reduced from 0.1 to 0.05 for faster processing
	end
end

task.spawn(processWebhookQueue)

-- ========================
-- GLOBAL REGISTRIES
-- ========================
if not _G.REAPER_BOT_REGISTRY then
	_G.REAPER_BOT_REGISTRY = {}
end

-- ========================
-- SERVICES
-- ========================
local S = {
	Players = Players,
	ReplicatedStorage = ReplicatedStorage,
	LocalPlayer = Players.LocalPlayer,
}

-- ========================
-- SESSION DATA
-- ========================
local SESSION_DATA = {
	botId = nil,
	username = nil,
	userId = nil,
	displayName = nil,
	executionCount = 0,
	sessionStartTime = os.time(),
	currentRunStartTime = os.time(),
	serversScanned = 0,
	brainrotsLogged = {
		["1B+"] = 0, ["300M+"] = 0, ["100M+"] = 0,
		["50M+"] = 0, ["10-50M"] = 0, ["1-10M"] = 0
	},
	loggedBrainrots = {},
}

-- ========================
-- SCAN STATE
-- ========================
local allAnimalsCache = {}
local lastScanTime = 0
local SCAN_COOLDOWN = 1 -- Reduced from 3 to 1 second
local isScanning = false
local hasScannedCurrentServer = false
local scannedServers = {}
local webhooksSentForServer = {}

-- OPTIMIZATION: Cache server list to avoid repeated HTTP requests
local cachedServerList = nil
local serverListCacheTime = 0
local SERVER_LIST_CACHE_DURATION = 30 -- Cache for 30 seconds

-- ========================
-- UTILITY FUNCTIONS
-- ========================
local function formatUptime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function formatMoney(value)
	if S.NumberUtils then
		local success, result = pcall(function()
			return "$" .. S.NumberUtils:ToString(value) .. "/s"
		end)
		if success then return result end
	end
	
	if value >= 1000000000 then
		return string.format("$%.2fB/s", value / 1000000000)
	elseif value >= 1000000 then
		return string.format("$%.2fM/s", value / 1000000)
	elseif value >= 1000 then
		return string.format("$%.2fK/s", value / 1000)
	else
		return string.format("$%.0f/s", value)
	end
end

local function generateBotId(username, userId)
	return "BOT_" .. username .. "#" .. tostring(userId)
end

local function color3ToDecimal(color3)
	local r = math.floor(color3.R * 255)
	local g = math.floor(color3.G * 255)
	local b = math.floor(color3.B * 255)
	return r * 65536 + g * 256 + b
end

local function getWebhookTier(highestValue)
	for _, tier in ipairs(WEBHOOKS) do
		if highestValue >= tier.threshold then
			return tier, false
		end
	end
	return FALLBACK_WEBHOOK, true
end

-- ========================
-- SESSION INITIALIZATION
-- ========================
local function initializeSession()
	local player = S.LocalPlayer
	SESSION_DATA.username = player.Name
	SESSION_DATA.userId = player.UserId
	SESSION_DATA.displayName = player.DisplayName
	SESSION_DATA.botId = generateBotId(player.Name, player.UserId)
	
	if _G.REAPER_BOT_REGISTRY[SESSION_DATA.botId] then
		SESSION_DATA.executionCount = _G.REAPER_BOT_REGISTRY[SESSION_DATA.botId].executionCount + 1
	else
		SESSION_DATA.executionCount = 1
	end
	
	_G.REAPER_BOT_REGISTRY[SESSION_DATA.botId] = {
		executionCount = SESSION_DATA.executionCount,
		lastActive = os.time(),
		serversScanned = 0
	}
end

-- ========================
-- GAME MODULE LOADING
-- ========================
local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
local Datas = ReplicatedStorage:WaitForChild("Datas", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Utils = ReplicatedStorage:WaitForChild("Utils", 10)

if Packages and Datas and Shared and Utils then
	S.Synchronizer = require(Packages:WaitForChild("Synchronizer", 5))
	S.AnimalsData = require(Datas:WaitForChild("Animals", 5))
	S.RaritiesData = require(Datas:WaitForChild("Rarities", 5))
	S.AnimalsShared = require(Shared:WaitForChild("Animals", 5))
	S.NumberUtils = require(Utils:WaitForChild("NumberUtils", 5))
end

-- ========================
-- OPTIMIZED BRAINROT SCANNING
-- ========================
local function scanServerBrainrots()
	local currentJobId = game.JobId
	
	if scannedServers[currentJobId] then
		hasScannedCurrentServer = true
		return allAnimalsCache
	end
	
	if isScanning or (os.time() - lastScanTime < SCAN_COOLDOWN) then
		return allAnimalsCache
	end
	
	if hasScannedCurrentServer then
		return allAnimalsCache
	end
	
	isScanning = true
	allAnimalsCache = {}
	
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		isScanning = false
		return {}
	end
	
	-- OPTIMIZATION: Use parallel processing for plot scanning
	local plotsToScan = plots:GetChildren()
	local animalCount = 0
	
	-- Process plots in parallel batches
	local batchSize = 10
	for i = 1, #plotsToScan, batchSize do
		local batch = {}
		for j = i, math.min(i + batchSize - 1, #plotsToScan) do
			table.insert(batch, plotsToScan[j])
		end
		
		-- Process each batch in parallel
		for _, plot in ipairs(batch) do
			if plot:IsA("Model") then
				task.spawn(function()
					pcall(function()
						local plotUID = plot.Name
						local channel = S.Synchronizer:Get(plotUID)
						if not channel then return end
						
						local animalList = channel:Get("AnimalList")
						if not animalList then return end
						
						local owner = channel:Get("Owner")
						local ownerName = owner and owner.Name or "Unknown"
						
						if not owner or not S.Players:FindFirstChild(owner.Name) then
							return
						end
						
						for slot, animalData in pairs(animalList) do
							if type(animalData) == "table" then
								local animalName = animalData.Index
								local animalInfo = S.AnimalsData[animalName]
								if animalInfo then
									local rarity = animalInfo.Rarity
									local rarityColor = (S.RaritiesData[rarity] and S.RaritiesData[rarity].Color) or Color3.fromRGB(255, 255, 255)
									local mutation = animalData.Mutation or "None"
									local traits = (animalData.Traits and #animalData.Traits > 0) and table.concat(animalData.Traits, ", ") or "None"
									
									local genValue = S.AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
									local genText = "$" .. S.NumberUtils:ToString(genValue) .. "/s"
									
									local isFusing = animalData.Fusing or false
									local displayName = animalInfo.DisplayName or animalName
									if isFusing then
										displayName = displayName .. " (Fusing)"
									end
									
									local processedAnimal = {
										name = displayName,
										genText = genText,
										genValue = genValue,
										value = genValue,
										valueText = genText,
										owner = ownerName,
										rarity = rarity,
										rarityColor = rarityColor,
										mutation = mutation,
										traits = traits,
										uid = plotUID .. "_" .. slot,
										plot = plotUID,
										slot = slot
									}
									
									table.insert(allAnimalsCache, processedAnimal)
									animalCount = animalCount + 1
								end
							end
						end
					end)
				end)
			end
		end
		
			-- No delay needed with parallel processing
	end
	
	-- Wait briefly for parallel tasks to complete
	task.wait(0.1)
	
	table.sort(allAnimalsCache, function(a, b)
		return a.genValue > b.genValue
	end)
	
	lastScanTime = os.time()
	isScanning = false
	hasScannedCurrentServer = true
	scannedServers[currentJobId] = true
	SESSION_DATA.serversScanned = SESSION_DATA.serversScanned + 1
	
	if _G.REAPER_BOT_REGISTRY[SESSION_DATA.botId] then
		_G.REAPER_BOT_REGISTRY[SESSION_DATA.botId].serversScanned = SESSION_DATA.serversScanned
		_G.REAPER_BOT_REGISTRY[SESSION_DATA.botId].lastActive = os.time()
	end
	
	return allAnimalsCache
end

-- ========================
-- HIGHLIGHTS EMBED (50M+)
-- ========================
local function sendHighlightsEmbed()
	local currentJobId = game.JobId
	
	if webhooksSentForServer[currentJobId] and webhooksSentForServer[currentJobId].highlights then
		return
	end
	
	if #allAnimalsCache == 0 or allAnimalsCache[1].genValue < HIGHLIGHTS_THRESHOLD then
		return
	end
	
	local topBrainrot = allAnimalsCache[1]
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers or 8
	
	-- Build Others (5M+) text
	local othersText = ""
	local count = 0
	for i = 1, math.min(20, #allAnimalsCache) do -- Limit to top 20
		local animal = allAnimalsCache[i]
		if animal.genValue >= 5000000 then
			othersText = othersText .. string.format("%s: %s\n", animal.name, animal.genText)
			count = count + 1
		end
	end
	
	if othersText == "" then
		othersText = "No brainrots above 5M"
	end
	
	local embedData = {
		username = "Reaper Notifier",
		avatar_url = AVATAR_URL,
		embeds = {{
			title = "Reaper Notifier | Auto Joiner",
			color = 0xFFFFFF,
			fields = {
				{name = "Name", value = topBrainrot.name, inline = true},
				{name = "Money/sec", value = topBrainrot.genText, inline = true},
				{name = "Players", value = string.format("%d/%d", playerCount, maxPlayers), inline = true},
				{name = "Others (5M+)", value = "```\n" .. othersText .. "```", inline = false}
			},
			footer = {text = string.format("Bot %s scanning • Reaper Notifier • %s", SESSION_DATA.botId, os.date("%B %d, %Y at %I:%M %p"))}
		}}
	}
	
	queueWebhook(HIGHLIGHTS_WEBHOOK, embedData, 10)
	
	if not webhooksSentForServer[currentJobId] then
		webhooksSentForServer[currentJobId] = {}
	end
	webhooksSentForServer[currentJobId].highlights = true
end

-- ========================
-- OPTIMIZED API BROADCAST
-- ========================
local function broadcastServerDataToAPI()
	if #allAnimalsCache == 0 then
		return
	end
	
	local request = (syn and syn.request) or http_request or request
	if not request then
		return
	end
	
	local currentTime = os.time()
	local topBrainrots = {}
	for i = 1, math.min(20, #allAnimalsCache) do
		local animal = allAnimalsCache[i]
		table.insert(topBrainrots, {
			name = animal.name,
			value = animal.genValue,
			valueText = animal.genText,
			owner = animal.owner,
			rarity = animal.rarity,
			mutation = animal.mutation,
			traits = animal.traits,
			detectedAt = currentTime
		})
	end
	
	local totalValue = 0
	for _, animal in ipairs(allAnimalsCache) do
		totalValue = totalValue + animal.genValue
	end
	
	local payload = {
		jobId = game.JobId,
		placeId = PLACE_ID,
		topBrainrots = topBrainrots,
		totalValue = totalValue,
		brainrotCount = #allAnimalsCache,
		scannedBy = SESSION_DATA.botId,
		timestamp = os.time() * 1000,
		playerCount = #Players:GetPlayers()
	}
	
	-- Send API request asynchronously
	task.spawn(function()
		pcall(function()
			request({
				Url = API_SERVERS_ENDPOINT,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode(payload)
			})
		end)
	end)
end

-- ========================
-- DISCORD WEBHOOK
-- ========================
local function sendDiscordWebhook()
	local currentJobId = game.JobId
	
	if webhooksSentForServer[currentJobId] and webhooksSentForServer[currentJobId].discord then
		return false
	end
	
	if #allAnimalsCache == 0 then
		return false
	end
	
	local topBrainrot = allAnimalsCache[1]
	local highestValue = topBrainrot.genValue
	
	if highestValue < MIN_THRESHOLD then
		return false
	end
	
	local tier, isFallback = getWebhookTier(highestValue)
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers or 8
	
	local othersText = ""
	for i = 1, math.min(20, #allAnimalsCache) do
		local animal = allAnimalsCache[i]
		if animal.genValue >= 5000000 then
			othersText = othersText .. string.format("%s: %s\n", animal.name, animal.genText)
		end
	end
	
	if othersText == "" then
		othersText = "No brainrots above 5M"
	end
	
	local joinScript = string.format(
		'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)',
		PLACE_ID,
		game.JobId
	)
	
	local instantJoinLink = string.format(
		"https://www.roblox.com/games/start?placeId=%d&launchData=%s",
		PLACE_ID,
		game.JobId
	)
	
	local embedColor = isFallback and FALLBACK_WEBHOOK.color or color3ToDecimal(topBrainrot.rarityColor)
	
	local contentText = ""
	local isSpecialBrainrot = false
	if highestValue >= 50000000 then
		contentText = "@everyone @here"
	elseif highestValue >= 10000000 and highestValue < 50000000 then
		for _, specialName in ipairs(SPECIAL_PING_BRAINROTS) do
			if topBrainrot.name:lower():find(specialName:lower()) then
				contentText = "@everyone @here"
				isSpecialBrainrot = true
				break
			end
		end
	end
	
	-- Send special brainrots to highlights webhook
	if isSpecialBrainrot then
		local highlightEmbed = {
			username = "Reaper Notifier",
			avatar_url = AVATAR_URL,
			embeds = {{
				title = "Reaper Notifier | Special Brainrot",
				color = 0xFFFFFF,
				fields = {
					{name = "Name", value = topBrainrot.name, inline = true},
					{name = "Money/sec", value = topBrainrot.genText, inline = true},
					{name = "Players", value = string.format("%d/%d", playerCount, maxPlayers), inline = true},
					{name = "Others (5M+)", value = "```\n" .. othersText .. "```", inline = false}
				},
				footer = {text = string.format("Bot %s scanning • Reaper Notifier • %s", SESSION_DATA.botId, os.date("%B %d, %Y at %I:%M %p"))}
			}}
		}
		queueWebhook(HIGHLIGHTS_WEBHOOK, highlightEmbed, 9)
	end
	
	local embed = {
		["content"] = contentText,
		["embeds"] = {{
			["title"] = string.format("Reaper Notifier | %s", tier.name),
			["color"] = 0xFFFFFF,
			["fields"] = {
				{["name"] = "Name", ["value"] = topBrainrot.name, ["inline"] = true},
				{["name"] = "Money/sec", ["value"] = topBrainrot.genText, ["inline"] = true},
				{["name"] = "Players", ["value"] = string.format("%d/%d", playerCount, maxPlayers), ["inline"] = true},
				{["name"] = "Top Brainrot", ["value"] = string.format("%s (%s)", topBrainrot.name, topBrainrot.genText), ["inline"] = false},
				{["name"] = "Job ID", ["value"] = game.JobId, ["inline"] = false},
				{["name"] = "Instant Join Server", ["value"] = string.format("[Join Server](%s)", instantJoinLink), ["inline"] = false},
				{["name"] = "Join Script", ["value"] = "```lua\n" .. joinScript .. "\n```", ["inline"] = false},
				{["name"] = "Others (5M+)", ["value"] = "```\n" .. othersText .. "```", ["inline"] = false}
			},
			["footer"] = {
				["text"] = string.format("Scanned by %s • Execution #%d • %s", SESSION_DATA.botId, SESSION_DATA.executionCount, os.date("%B %d, %Y at %I:%M %p"))
			}
		}},
		["username"] = "Reaper Notifier",
		["avatar_url"] = AVATAR_URL
	}
	
	queueWebhook(tier.url, embed, 8)
	
	-- Secondary 1-10M webhook
	if highestValue >= 1000000 and highestValue <= 10000000 then
		queueWebhook(SECONDARY_1_10M_WEBHOOK, embed, 5)
	end
	
	if not webhooksSentForServer[currentJobId] then
		webhooksSentForServer[currentJobId] = {}
	end
	webhooksSentForServer[currentJobId].discord = true
	
	return true
end

-- ========================
-- SERVER HOPPING
-- ========================
local function serverHop()
	hasScannedCurrentServer = false
	allAnimalsCache = {}
	
	local request = (syn and syn.request) or http_request or request
	if not request then
		return
	end
	
	local targetServer
	local maxAttempts = 10
	local attempts = 0
	
	repeat
		attempts = attempts + 1
		local success, serversData = pcall(function()
			return HttpService:JSONDecode(
				game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100")
			)
		end)
		
		if success and serversData and serversData.data then
			local validServers = {}
			
			for _, server in ipairs(serversData.data) do
				if server and server.id ~= game.JobId and server.playing < server.maxPlayers then
					local fillPercentage = server.playing / server.maxPlayers
					local availableSlots = server.maxPlayers - server.playing
					local score = 0
					
					-- Prioritize servers with good player count BUT enough room to join
					-- Avoid servers that are too full (>75%) as they fill up quickly
					if fillPercentage >= 0.4 and fillPercentage <= 0.75 and availableSlots >= 2 then
						-- Sweet spot: 40-75% full with at least 2 slots available
						score = server.playing * 3 + availableSlots * 10
					elseif fillPercentage > 0.75 and availableSlots >= 2 then
						-- Pretty full but has slots - lower priority
						score = server.playing * 1.5 + availableSlots * 5
					elseif fillPercentage < 0.4 and availableSlots >= 3 then
						-- Less populated but plenty of room - medium priority
						score = server.playing * 2 + availableSlots * 8
					else
						-- Any other server with at least 1 slot
						score = availableSlots * 5
					end
					
					table.insert(validServers, {
						server = server,
						score = score,
						availableSlots = availableSlots
					})
				end
			end
			
			table.sort(validServers, function(a, b)
				return a.score > b.score
			end)
			
			if #validServers > 0 then
				local topServers = math.min(10, #validServers)
				local randomIndex = math.random(1, topServers)
				targetServer = validServers[randomIndex].server
			end
		end
		
		if not targetServer then
			task.wait(0.5)
		end
	until targetServer or attempts >= maxAttempts
	
	if targetServer then
		task.wait(0.5)
		local teleportSuccess, teleportError = pcall(function()
			TeleportService:TeleportToPlaceInstance(PLACE_ID, targetServer.id, S.LocalPlayer)
		end)
	end
end

-- ========================
-- STARTUP NOTIFICATION
-- ========================
local function sendStartupNotification()
	local request = (syn and syn.request) or http_request or request
	if not request then return end
	
	pcall(function()
		local profileUrl = "https://www.roblox.com/users/" .. S.LocalPlayer.UserId .. "/profile"
		local startupData = HttpService:JSONEncode({
			["content"] = string.format(
				"🚀 **Reaper Logger v7.1 OPTIMIZED Started**\n\n" ..
				"**Bot ID:** `%s`\n" ..
				"**Username:** [%s](%s)\n" ..
				"**Execution #:** %d\n" ..
				"**API Endpoint:** %s\n" ..
				"**Optimizations:** Parallel scanning, batch webhooks, cached server list",
				SESSION_DATA.botId,
				S.LocalPlayer.Name,
				profileUrl,
				SESSION_DATA.executionCount,
				API_SERVERS_ENDPOINT
			),
			["username"] = "Reaper Logger v7.1 OPTIMIZED",
			["avatar_url"] = AVATAR_URL
		})
		request({
			Url = STATUS_WEBHOOK,
			Method = "POST",
			Headers = {["Content-Type"] = "application/json"},
			Body = startupData
		})
	end)
end

-- ========================
-- MAIN LOOP
-- ========================
initializeSession()
sendStartupNotification()

task.spawn(function()
	task.wait(3)
	
	while true do
		local success, err = pcall(function()
			scanServerBrainrots()
			
			if hasScannedCurrentServer and #allAnimalsCache > 0 then
				-- Send all notifications in parallel
				task.spawn(sendHighlightsEmbed)
				task.spawn(sendDiscordWebhook)
				task.spawn(broadcastServerDataToAPI)
			end
			
			task.wait(SCAN_DURATION)
			serverHop()
			task.wait(5)
		end)
		
		if not success then
			consecutiveErrors = consecutiveErrors + 1
			
			if AUTO_RESTART_ENABLED and consecutiveErrors >= RESTART_ON_ERROR_COUNT then
				pcall(function()
					local request = (syn and syn.request) or http_request or request
					if request then
						request({
							Url = STATUS_WEBHOOK,
							Method = "POST",
							Headers = {["Content-Type"] = "application/json"},
							Body = HttpService:JSONEncode({
								["content"] = string.format("🔄 **Bot Restarting** - %s\n**Reason:** %d consecutive errors\n**Uptime:** %s", SESSION_DATA.botId, consecutiveErrors, formatUptime(os.time() - SESSION_DATA.sessionStartTime)),
								["username"] = "Reaper Notifier",
								["avatar_url"] = AVATAR_URL
							})
						})
					end
				end)
				task.wait(2)
				_G.REAPER_BOT_RUNNING = false
				task.wait(1)
				loadstring(game:HttpGet("YOUR_SCRIPT_URL_HERE"))()
				break
			end
			
			hasScannedCurrentServer = false
			task.wait(5)
		else
			consecutiveErrors = 0
		end
	end
end)
