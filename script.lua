-- REAPER LOGGER BOT v9.0 - TRAIT & MUTATION TRACKING
-- ========================
-- EXECUTION GUARD
-- ========================
if _G.REAPER_BOT_RUNNING then return end
_G.REAPER_BOT_RUNNING = true

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PLACE_ID = 109983668079237
local SCAN_DURATION = 0.1

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

local CRABBY_PATTY_WEBHOOKS = {
	{threshold = 1000000000, url = "https://discord.com/api/webhooks/1462890088559022110/q5u9FhIm5KWrj_e0WCfKfLsNYvtVBY-1a5THce_TOgH2g_h_v168HrxeO0xbqSuAxbiQ", name = "1B+"},
	{threshold = 300000000, url = "https://discord.com/api/webhooks/1462905310468640842/jQ_9cAOhjV0wO3F2o6i7pdVEaMB5hEhgE1AwEom81wUxNS4RJonnBiOfHKL_SOc9NwHz", name = "300M-1B"},
	{threshold = 100000000, url = "https://discord.com/api/webhooks/1462890331224805418/ZowF613eYktJipPtXJzsskJFBHPnpfoU_533tNLJnJM2EYQH0_VEqWwW32QBBMuujffG", name = "100M-300M"},
	{threshold = 50000000, url = "https://discord.com/api/webhooks/1462890241617694785/xWCyt35YEvPFcLnohxsYqFzkg9C_cQUTOsiNpfwpZajOgb_uGvaxxOw9RVhU4i3qt5gz", name = "50-100M"},
	{threshold = 10000000, url = "https://discord.com/api/webhooks/1462890181152604303/NJ7T33LHI0xQEUVTXVJfSscZQWf3d35iPOp_D36KHk1XiZ7kWyLKnkwy1bALSX63qtiY", name = "10-50M"},
}

local SECONDARY_1_10M_WEBHOOK = "https://discordapp.com/api/webhooks/1449234826803675219/6t-mirx90KQpP6WnDXkI-78viuzCgHlu2lL-bs-EjZ43lmNBtc5snX9HElbGIuuHVFzr"
local AVATAR_URL = "https://cdn.discordapp.com/attachments/1449158166289059982/1449233510589005975/reaper.png"

-- ========================
-- ASYNC WEBHOOK QUEUE
-- ========================
local webhookQueue = {}
local lastWebhookTime = 0
local dynamicCooldown = 0.02

local function queueWebhook(url, data)
	table.insert(webhookQueue, {url = url, data = data})
end

task.spawn(function()
	while true do
		if #webhookQueue > 0 then
			local currentTime = tick()
			if (currentTime - lastWebhookTime) >= dynamicCooldown then
				local item = table.remove(webhookQueue, 1)
				task.spawn(function()
					local request = (syn and syn.request) or http_request or request
					if request then
						pcall(function()
							request({
								Url = item.url,
								Method = "POST",
								Headers = {["Content-Type"] = "application/json"},
								Body = HttpService:JSONEncode(item.data)
							})
						end)
					end
				end)
				lastWebhookTime = currentTime
			end
		end
		RunService.Heartbeat:Wait()
	end
end)

-- ========================
-- UTILITIES
-- ========================
local S = {LocalPlayer = Players.LocalPlayer}
local allAnimalsCache = {}
local webhooksSentForServer = {}

local function formatMoney(value)
	if value >= 1e9 then return string.format("$%.2fB/s", value / 1e9)
	elseif value >= 1e6 then return string.format("$%.2fM/s", value / 1e6)
	elseif value >= 1e3 then return string.format("$%.2fK/s", value / 1e3)
	else return string.format("$%.0f/s", value) end
end

local function getISO8601Timestamp()
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

-- ========================
-- SCANNING LOGIC
-- ========================
local function scan()
	allAnimalsCache = {}
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return end
	
	local children = plots:GetChildren()
	for i = 1, #children do
		local plot = children[i]
		local owner = plot:GetAttribute("Owner")
		local animals = plot:FindFirstChild("Animals")
		if owner and animals then
			local animalList = animals:GetChildren()
			for j = 1, #animalList do
				local animal = animalList[j]
				local animalId = animal:GetAttribute("AnimalId")
				local animalData = S.AnimalsData and S.AnimalsData[animalId]
				if animalData then
					local genValue = S.AnimalsShared.GetGenValue(animal)
					
					-- Extract Traits and Mutations
					local traits = animal:GetAttribute("Traits") or {}
					local mutation = animal:GetAttribute("Mutation")
					
					local traitList = {}
					if mutation and mutation ~= "" then table.insert(traitList, mutation) end
					if type(traits) == "table" then
						for _, trait in ipairs(traits) do table.insert(traitList, trait) end
					elseif type(traits) == "string" and traits ~= "" then
						table.insert(traitList, traits)
					end
					
					local traitString = #traitList > 0 and " (" .. table.concat(traitList, ", ") .. ")" or ""
					
					table.insert(allAnimalsCache, {
						name = animalData.Name,
						fullName = animalData.Name .. traitString,
						genValue = genValue,
						genText = formatMoney(genValue),
						owner = owner
					})
				end
			end
		end
	end
	table.sort(allAnimalsCache, function(a, b) return a.genValue > b.genValue end)
end

-- ========================
-- WEBHOOK DISPATCH
-- ========================
local function send()
	local jobId = game.JobId
	if webhooksSentForServer[jobId] or #allAnimalsCache == 0 then return end
	
	local top = allAnimalsCache[1]
	if top.genValue < 1e6 then return end
	
	local timestamp = getISO8601Timestamp()
	local function getTier(val, set)
		for _, t in ipairs(set) do if val >= t.threshold then return t end end
		return {url = SECONDARY_1_10M_WEBHOOK, name = "1-10M"}
	end
	
	local tier = getTier(top.genValue, WEBHOOKS)
	local crabbyTier = getTier(top.genValue, CRABBY_PATTY_WEBHOOKS)
	
	local others = ""
	for i = 1, math.min(10, #allAnimalsCache) do
		if allAnimalsCache[i].genValue >= 5e6 then
			others = others .. allAnimalsCache[i].fullName .. ": " .. allAnimalsCache[i].genText .. "\n"
		end
	end

	local function createEmbed(title, color)
		return {
			username = "Reaper Notifier",
			avatar_url = AVATAR_URL,
			embeds = {{
				title = "Reaper Notifier | " .. title,
				color = color,
				timestamp = timestamp,
				fields = {
					{name = "Name", value = top.fullName, inline = true},
					{name = "Value", value = top.genText, inline = true},
					{name = "Job ID", value = "```" .. jobId .. "```", inline = false},
					{name = "Others (5M+)", value = "```\n" .. (others ~= "" and others or "None") .. "```", inline = false}
				}
			}}
		}
	end

	queueWebhook(tier.url, createEmbed(tier.name, 0xFFFFFF))
	queueWebhook(crabbyTier.url, createEmbed("Crabby Patty | " .. crabbyTier.name, 0xFFFF00))
	webhooksSentForServer[jobId] = true
end

-- ========================
-- SERVER HOPPING
-- ========================
local function hop()
	local success, servers = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100")).data
	end)
	if success and servers then
		for _, s in ipairs(servers) do
			if s.id ~= game.JobId and s.playing < s.maxPlayers then
				TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, S.LocalPlayer)
				return
			end
		end
	end
end

-- ========================
-- INIT
-- ========================
local Datas = ReplicatedStorage:WaitForChild("Datas", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if Datas and Shared then
	S.AnimalsData = require(Datas:WaitForChild("Animals"))
	S.AnimalsShared = require(Shared:WaitForChild("Animals"))
end

task.spawn(function()
	while true do
		pcall(function()
			scan()
			send()
			task.wait(SCAN_DURATION)
			hop()
		end)
		task.wait(1)
	end
end)
