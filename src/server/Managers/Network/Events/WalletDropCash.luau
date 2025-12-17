local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CashDrop = require(ServerScriptService.Server.Services.CashDropperService.CashDrop)
local DataService = require(ServerScriptService.Server.Services.DataService)
local WalletDropCashEvent = require(ReplicatedStorage.Network.Events.WalletDropCash):Server()

local WalletDropCash = {}

function WalletDropCash.OnStart()
	print("started")
	WalletDropCashEvent:On(function(player, amount: number)
		print(player.Name, amount)
		local char = player.Character :: Model
		CashDrop.new(amount, (char.PrimaryPart :: BasePart).CFrame + Vector3.new(4, 0, 0), false)
		DataService:RemoveCash(player, amount)
	end)
end

return WalletDropCash
