local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)

local KickCommand = {}

function KickCommand.Register()
	Conch.register("kick", {
		arguments = function()
			return Conch.args.player("player", "player to kick"), Conch.args.string("reason", "reason for kicking")
		end,
		permissions = { "super-user" },
		callback = function(player, reason)
			player:Kick(reason)
		end,
	})
end

return KickCommand
