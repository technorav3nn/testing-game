local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local DataTemplate = require(ReplicatedStorage.Data.DataTemplate)
local Promise = require(ReplicatedStorage.Packages["_Index"]["paradoxum-games_lyra@0.6.0"].lyra.Promise)

local PunishmentService = {}

function PunishmentService:OnStart()
	DataService.Ready:Wait()
	Players.PlayerAdded:Connect(function(player: Player)
		-- Preload active punishments when player joins
		local punishments = PunishmentService:GetActivePunishments(player)
			:catch(function(err)
				warn("Failed to load punishments for player", player.UserId, ":", err)
				player:Kick("Error loading punishments")
			end)
			:await()
	end)
end

function PunishmentService:Punish(
	playerToPunish: Player,
	banLength: number?,
	reason: string,
	issuedBy: number?,
	isApiBan: boolean,
	type: string
): Promise.TPromise<boolean>
	local store = DataService.store
	return store:update(playerToPunish, function(data)
		assert(data ~= nil)
		table.insert(data.Punishments, {
			duration = banLength,
			isApiBan = isApiBan,
			issuedAt = os.time(),
			issuedBy = issuedBy,
			reason = reason,
			privateReason = reason,
			type = type,
		})
		return true
	end)
end

function PunishmentService:GetActivePunishments(player: Player): Promise.TPromise<{}>
	local store = DataService.store
	return store:get(player):andThen(function(data)
		assert(data ~= nil)
		local activePunishments = {}
		local currentTime = os.time()
		for _, punishment in data.Punishments do
			if punishment.duration == nil or (punishment.issuedAt + punishment.duration) > currentTime then
				table.insert(activePunishments, punishment)
			end
		end
		return activePunishments
	end)
end

return PunishmentService
