local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)

local KickCommand = {}

function KickCommand.Register()
	Conch.register("unban", {
		description = "unbans a player by their user ID",
		arguments = function()
			return Conch.args.userid("user_id", "player 's !! USERID !! to unban")
		end,
		permissions = { "super-user" },
		callback = function(userId)
			Players:UnbanAsync({
				UserIds = { userId },
				ApplyToUniverse = true,
			})
			local playerName = Players:GetNameFromUserIdAsync(userId)
			Conch.log("info", `unbanned player {playerName}`)
		end,
	})
end

return KickCommand
