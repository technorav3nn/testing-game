local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CashDrop = require(ServerScriptService.Server.Services.CashDropperService.CashDrop)
local Cooldowns = require(ReplicatedStorage.Modules.Utils.Cooldowns)
local DataService = require(ServerScriptService.Server.Services.DataService)
local Network = require(ReplicatedStorage.Network)

local WalletDropCash = {}

function WalletDropCash.OnStart()
	Network.cash.DropCash:onRequest(function(player, amount)
		local cooldown = Cooldowns.new(`${player.UserId}_Wallet`)
		local ready, _rem = cooldown:Check("WalletDropCash")
		local remaining = _rem :: number

		if ready then
			local char = player.Character :: Model
			CashDrop.new(amount, (char.PrimaryPart :: BasePart).CFrame + Vector3.new(4, 0, 0), false)
			DataService:RemoveCash(player, amount)
			cooldown:Add("WalletDropCash", 3)
			return 0
		else
			return remaining
		end
	end)
end

return WalletDropCash
