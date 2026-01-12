local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)
local Network = require(ReplicatedStorage.Network)

local PunishPlayer = {}

function PunishPlayer.OnStart()
	Network.moderation.PunishPlayer:onRequest(function(player, punishment)
		local type = punishment.type
		if type ~= "ban" and type ~= "kick" and type ~= "warn" and type ~= "serverban" then
			return false, "Invalid punishment type"
		end

		local conchUser = Conch.get_user(player)
		if not conchUser or not table.find(conchUser.roles, "super-user") then
			return false, "No permission"
		end

		return true, "Success!"
	end)
end

return PunishPlayer
