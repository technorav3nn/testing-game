local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Conch = require(ReplicatedStorage.Packages.Conch)
local DataService = require(ServerScriptService.Server.Services.DataService)

local GiveCashCommand = {}

function GiveCashCommand.Register()
	Conch.register("setcash", {
		arguments = function()
			return Conch.args.player(), Conch.args.number()
		end,
		description = "sets a player's cash to a specific amount",
		permissions = { "super-user" },
		callback = function(player, amount)
			DataService:SetCash(player, amount)
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
