local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local charm = require(ReplicatedStorage.Packages.Charm)
local template = require(ReplicatedStorage.Data.DataTemplate)

local atom = charm.atom

local cashAtom = atom(template.profileTemplate.Cash)

local ReplicaClient = require(ReplicatedStorage.Packages._Index["azutreo_replica@1.0.1"].replica.ReplicaClient)
local showCashNotification = require("../Components/Cash/CashNotifications")

local firstTime = true

ReplicaClient.OnNew(tostring(Players.LocalPlayer.UserId), function(replica: ReplicaClient.Replica)
	if firstTime then
		local data = replica.Data :: template.Profile
		cashAtom(data.Cash)
	end
	replica:OnSet(
		{ "Cash" },
		function(cash: number)
			firstTime = false
			showCashNotification(cash - cashAtom())
			cashAtom(cash)
		end :: any
	)
end)

ReplicaClient.RequestData()

return {
	cashAtom = cashAtom,
}
