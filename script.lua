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
-- FIRST SET: REAPER
local WEBHOOKS = {
	{threshold = 1000000000, url = "https://discord.com/api/webhooks/1449839085618466836/EJ_mosE_BIlOnxh1ybz9LF3Nys9zn92_FXzc_zkHoHCyQAqKu4QDg5P9LiobrxLuZPRR", name = "1B+"},
	{threshold = 300000000, url = "https://discord.com/api/webhooks/1449839022825537786/sBf5I_Aa5WZW-PacXvdzMQXCLhySYpwKppIFJB2RYPk1DDgS9xbd-T5qOv4SmrJWNx4r", name = "300M+"},
	{threshold = 100000000, url = "https://discord.com/api/webhooks/1449838937878167664/-wh9mjxg9reZBGyArotw-2Kah_rI2IntiPRV8JuxHfvLBfvm-hgqzx3PXABQdRTzIDRe", name = "100M+"},
	{threshold = 50000000, url = "https://discord.com/api/webhooks/1449838592200409201/RXZDdX1l9PE2tPQV6VL4zFIK0Q7_Z_28tPd1ZzQIFRDCzph0hz-XQDmHbQIlBLu-DJH6", name = "50M+"},
	{threshold = 10000000, url = "https://discord.com/api/webhooks/1449839469879496754/kZa8bH4QSCwXjRwsOajNUvHq1wosOBsj39ezcw-55rgjS-_qJTe5rVMTIZHWxApD4R3-", name = "10-50M"},
}

-- SECOND SET: CRABBY PATTY NOTIFIER
local CRABBY_PATTY_WEBHOOKS = {
	{threshold = 1000000000, url = "https://discord.com/api/webhooks/1462890088559022110/q5u9FhIm5KWrj_e0WCfKfLsNYvtVBY-1a5THce_TOgH2g_h_v168HrxeO0xbqSuAxbiQ", name = "1B+"},
	{threshold = 300000000, url = "https://discord.com/api/webhooks/1462905310468640842/jQ_9cAOhjV0wO3F2o6i7pdVEaMB5hEhgE1AwEom81wUxNS4RJonnBiOfHKL_SOc9NwHz", name = "300M-1B"},
	{threshold = 100000000, url = "https://discord.com/api/webhooks/1462890331224805418/ZowF613eYktJipPtXJzsskJFBHPnpfoU_533tNLJnJM2EYQH0_VEqWwW32QBBMuujffG", name = "100M-300M"},
	{threshold = 50000000, url = "https://discord.com/api/webhooks/1462890241617694785/xWCyt35YEvPFcLnohxsYqFzkg9C_cQUTOsiNpfwpZajOgb_uGvaxxOw9RVhU4i3qt5gz", name = "50-100M"},
	{threshold = 10000000, url = "https://discord.com/api/webhooks/1462890181152604303/NJ7T33LHI0xQEUVTXVJfSscZQWf3d35iPOp_D36KHk1XiZ7kWyLKnkwy1bALSX63qtiY", name = "10-50M"},
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
local dynamicCooldown = 0.1
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

local function processWebhookQueue()
	while true do
		if #webhookQueue > 0 then
			local currentTime = os.time()
			table.sort(webhookQueue, function(a, b) return a.priority > b.priority end)
			
			if (currentTime - lastWebhookTime) >= dynamicCooldown then
				local batchSize = math.min(3, #webhookQueue)
				local batch = {}
				for i = 1, batchSize do table.insert(batch, table.remove(webhookQueue, 1)) end
				
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
								if response.Headers then
									local remaining = response.Headers["x-ratelimit-remaining"] or response.Headers["X-RateLimit-Remaining"]
									if remaining then
										rateLimitRemaining = tonumber(remaining)
										if rateLimitRemaining and rateLimitRemaining > 10 then dynamicCooldown = 0.05
										elseif rateLimitRemaining and rateLimitRemaining > 5 then dynamicCooldown = 0.1
										else dynamicCooldown = 0.3 end
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
		task.wait(0.05)
	end
end
task.spawn(processWebhookQueue)

-- ========================
-- SERVICES & SESSION
-- ========================
local S = {
	Players = Players,
	ReplicatedStorage = ReplicatedStorage,
	LocalPlayer = Players.LocalPlayer,
}

local SESSION_DATA = {
	botId = nil,
	username = nil,
	userId = nil,
	executionCount = 0,
	sessionStartTime = os.time(),
}

local function formatMoney(value)
	if value >= 1000000000 then return string.format("$%.2fB/s", value / 1000000000)
	elseif value >= 1000000 then return string.format("$%.2fM/s", value / 1000000)
	elseif value >= 1000 then return string.format("$%.2fK/s", value / 1000)
	else return string.format("$%.0f/s", value) end
end

local function getWebhookTier(highestValue, webhookSet)
	webhookSet = webhookSet or WEBHOOKS
	for _, tier in ipairs(webhookSet) do
		if highestValue >= tier.threshold then return tier, false end
	end
	return FALLBACK_WEBHOOK, true
end

-- ========================
-- SCANNING LOGIC
-- ========================
local allAnimalsCache = {}
local lastScanTime = 0
local SCAN_COOLDOWN = 1
local isScanning = false
local hasScannedCurrentServer = false
local scannedServers = {}
local webhooksSentForServer = {}

local function scanServerBrainrots()
	local currentJobId = game.JobId
	if scannedServers[currentJobId] or isScanning or (os.time() - lastScanTime < SCAN_COOLDOWN) then return allAnimalsCache end
	
	isScanning = true
	allAnimalsCache = {}
	
	local plots = workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			local owner = plot:GetAttribute("Owner")
			local animals = plot:FindFirstChild("Animals")
			if owner and animals then
				for _, animal in ipairs(animals:GetChildren()) do
					local animalId = animal:GetAttribute("AnimalId")
					local animalData = S.AnimalsData and S.AnimalsData[animalId]
					if animalData then
						local genValue = S.AnimalsShared.GetGenValue(animal)
						table.insert(allAnimalsCache, {
							name = animalData.Name,
							genValue = genValue,
							genText = formatMoney(genValue),
							owner = owner,
							plot = plot.Name
						})
					end
				end
			end
		end
	end
	
	table.sort(allAnimalsCache, function(a, b) return a.genValue > b.genValue end)
	lastScanTime = os.time()
	isScanning = false
	hasScannedCurrentServer = true
	scannedServers[currentJobId] = true
	return allAnimalsCache
end

-- ========================
-- WEBHOOK DISPATCH
-- ========================
local function sendDiscordWebhook()
	local currentJobId = game.JobId
	if webhooksSentForServer[currentJobId] or #allAnimalsCache == 0 then return end
	
	local topBrainrot = allAnimalsCache[1]
	local highestValue = topBrainrot.genValue
	if highestValue < MIN_THRESHOLD then return end
	
	local tier = getWebhookTier(highestValue, WEBHOOKS)
	local crabbyTier = getWebhookTier(highestValue, CRABBY_PATTY_WEBHOOKS)
	
	local playerCount = #Players:GetPlayers()
	local maxPlayers = Players.MaxPlayers or 8
	
	local othersText = ""
	for i = 1, math.min(15, #allAnimalsCache) do
		local animal = allAnimalsCache[i]
		if animal.genValue >= 5000000 then
			othersText = othersText .. string.format("%s: %s\n", animal.name, animal.genText)
		end
	end
	
	local joinScript = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', PLACE_ID, game.JobId)
	local instantJoinLink = string.format("https://www.roblox.com/games/start?placeId=%d&launchData=%s", PLACE_ID, game.JobId)
	
	local contentText = (highestValue >= 50000000) and "@everyone @here" or ""
	
	local function createEmbed(titleName)
		return {
			["content"] = contentText,
			["embeds"] = {{
				["title"] = string.format("Reaper Notifier | %s", titleName),
				["color"] = 0xFFFFFF,
				["fields"] = {
					{["name"] = "Name", ["value"] = topBrainrot.name, ["inline"] = true},
					{["name"] = "Money/sec", ["value"] = topBrainrot.genText, ["inline"] = true},
					{["name"] = "Players", ["value"] = string.format("%d/%d", playerCount, maxPlayers), ["inline"] = true},
					{["name"] = "Job ID", ["value"] = game.JobId, ["inline"] = false},
					{["name"] = "Instant Join", ["value"] = string.format("[Join Server](%s)", instantJoinLink), ["inline"] = false},
					{["name"] = "Join Script", ["value"] = "```lua\n" .. joinScript .. "\n```", ["inline"] = false},
					{["name"] = "Others (5M+)", ["value"] = "```\n" .. (othersText ~= "" and othersText or "None") .. "```", ["inline"] = false}
				},
				["footer"] = {["text"] = string.format("Scanned by %s • %s", SESSION_DATA.botId, os.date("%I:%M %p"))}
			}},
			["username"] = "Reaper Notifier",
			["avatar_url"] = AVATAR_URL
		}
	end
	
	-- Dispatch to both sets
	queueWebhook(tier.url, createEmbed(tier.name), 8)
	queueWebhook(crabbyTier.url, createEmbed("Crabby Patty | " .. crabbyTier.name), 8)
	
	-- Secondary 1-10M
	if highestValue >= 1000000 and highestValue <= 10000000 then
		queueWebhook(SECONDARY_1_10M_WEBHOOK, createEmbed("1-10M"), 5)
	end
	
	webhooksSentForServer[currentJobId] = true
end

-- ========================
-- SERVER HOPPING
-- ========================
local function serverHop()
	local success, serversData = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"))
	end)
	
	if success and serversData and serversData.data then
		for _, server in ipairs(serversData.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				TeleportService:TeleportToPlaceInstance(PLACE_ID, server.id, S.LocalPlayer)
				break
			end
		end
	end
end

-- ========================
-- MAIN LOOP
-- ========================
SESSION_DATA.botId = "BOT_" .. S.LocalPlayer.Name
SESSION_DATA.username = S.LocalPlayer.Name

local Packages = ReplicatedStorage:WaitForChild("Packages", 10)
local Datas = ReplicatedStorage:WaitForChild("Datas", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)

if Packages and Datas and Shared then
	S.AnimalsData = require(Datas:WaitForChild("Animals", 5))
	S.AnimalsShared = require(Shared:WaitForChild("Animals", 5))
end

task.spawn(function()
	while true do
		pcall(function()
			scanServerBrainrots()
			if hasScannedCurrentServer and #allAnimalsCache > 0 then
				sendDiscordWebhook()
			end
			task.wait(SCAN_DURATION)
			serverHop()
			task.wait(5)
		end)
	end
end)
