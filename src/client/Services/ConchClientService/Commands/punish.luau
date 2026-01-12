local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Conch = require(ReplicatedStorage.Packages.Conch)
local Vide = require(ReplicatedStorage.Packages.Vide)

local PunishmentPanel = require(ReplicatedStorage.UI.Views.PunishmentPanel)

local KickCommand = {}

function KickCommand.Register()
	Conch.register("punish", {
		description = "opens the punishment panel",
		arguments = function()
			return Conch.args.optional(Conch.args.player("player", "player to punish"))
		end,
		permissions = { "super-user" },
		callback = function(player: Player?)
			xpcall(function()
				Vide.mount(function()
					return PunishmentPanel(player or Players.LocalPlayer)
				end, Players.LocalPlayer.PlayerGui)
			end, function(err)
				warn("Error mounting punishment panel:", err)
			end)
		end,
	})
end

return KickCommand
