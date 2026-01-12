local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)

local KickCommand = {}

function KickCommand.Register()
	Conch.register("ban", {
		description = "bans a player from the server",
		arguments = function()
			return Conch.args.player("player", "player to ban"),
				Conch.args.string("reason", "reason for ban"),
				Conch.args.optional(Conch.args.string("private note", "private note for ban")),
				Conch.args.optional(Conch.args.number("duration", "duration of ban in minutes (-1 for permanent)")),
				Conch.args.boolean("ban_alts", "whether to ban alternate accounts using roblox ban api")
		end,
		permissions = { "super-user" },
		callback = function(player, reason: string, privateNote: string?, duration: number?, shouldBanAlts: boolean)
			Players:BanAsync({
				UserIds = { player.UserId },
				ApplyToUniverse = true,
				DisplayReason = reason,
				PrivateReason = privateNote or `same as display reason: {reason}`,
				Duration = duration or -1,
				ExcludeAltAccounts = not shouldBanAlts,
			})
			Conch.log("info", `banned player {player.DisplayName} for reason: {reason}`)
		end,
	})
end

return KickCommand
