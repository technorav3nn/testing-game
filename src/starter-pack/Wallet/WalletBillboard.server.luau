local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Server.Services.DataService)
local Formatters = require(ReplicatedStorage.Modules.Utils.Formatters)

local tool = script.Parent :: Tool

tool.Equipped:Connect(function()
	-- tool isnt in starterpack, so cast to character (model)
	local player = game.Players:GetPlayerFromCharacter((script.Parent.Parent :: any) :: Model)
	if not player then
		-- its in the backpack, so return
		return
	end
	local cashText = script.Parent.Handle.BillboardGui.CashText
	if cashText.Text == "INIT" then
		-- isnt initalized yet, get data
		DataService:GetData(player)
			:andThen(function(data)
				cashText.Text = `${Formatters:FormatNumber(data.Cash)}`
			end)
			:catch(function(...)
				error("Couldn't update inital cash text in WalletBillboard", ...)
			end)
	end

	if not DataService.isReady then
		DataService.Ready:Wait()
	end
	-- connection is automatically disconnected when player leaves
	DataService:GetPlayerDataChangedSignal(player):Connect(function(newData, oldData)
		if newData.Cash == oldData.Cash then
			return
		end
		cashText.Text = `${Formatters:FormatNumber(newData.Cash)}`
	end)
end)
