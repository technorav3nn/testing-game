local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Conch = require(ReplicatedStorage.Packages.Conch)
local DataService = require(ServerScriptService.Server.Services.DataService)

local GiveCashCommand = {}

function GiveCashCommand.Register()
	Conch.register("givecash", {
		arguments = function()
			return Conch.args.player("player", "the player to give the cash to"),
				Conch.args.number("the amount of cash, negative or positive")
		end,
		description = "Gives cash to a player.",
		permissions = { "super-user" },
		callback = function(player, amount)
			DataService:GiveCash(player, amount)
				:andThen(function(success)
					if not success then
						Conch.log("error", `failed to give cash to {player.DisplayName}`)
					end
					Conch.log("info", `successfully gave {amount} cash to {player.DisplayName}`)
				end)
				:catch(function(err)
					Conch.log("error", `failed to give cash: {err}`)
				end)
		end,
	})
end

return GiveCashCommand
